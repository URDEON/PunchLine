extends Node3D
## Daño solo en autoridad. Los efectos reciben eventos; nunca deciden impactos.
const Catalog := preload("res://scripts/mecha_move_catalog.gd")
var controller: Node3D
var game: Node3D
var current: Dictionary = {}
var elapsed := 0.0
var cooldowns := [0.0,0.0,0.0,0.0]
var m1_cooldown := 0.0
var m1_next_stomp := false
var revision := 0
var contacted := false
var direction := Vector3.FORWARD
var hit_ids: Array[int] = []
var projectiles: Array[Dictionary] = []
var serial := 0
var ram_finished := false
var cannon_aim := Vector3.FORWARD*20
var cannon_phase := ""
var release_pending := false
var aim_laser: MeshInstance3D
var aim_spot: MeshInstance3D
var cannon: Node3D
var barrel_tip: Marker3D

func setup(owner_controller: Node3D) -> void:
	controller = owner_controller; game = controller.game

func can_act() -> bool:
	return controller.fused and not controller.replica and game.hp > 0 and game.stun <= 0 and game.moves.player_freeze <= 0 and not game.player_ragdoll and not game.block and current.is_empty() and controller.boost_time <= 0

func press(slot: int) -> bool:
	if controller.spider.active():controller.spider.ability(slot);return slot in [1,2]
	if slot>=1 and slot<=4 and not controller.damage.allowed(slot):
		game.ult_msg=controller.damage.reason(slot);game.ult_msg_time=2.5;return false
	if slot < 1 or slot > 4 or not can_act() or cooldowns[slot-1] > 0 or not game.player.is_on_floor(): return false
	current = Catalog.mega(slot); current.slot = slot
	if slot == 3: current["limb"] = "Izq" if controller.damage.missing(2) else "Der"
	cooldowns[slot-1] = 0.0 if slot == 1 else current.cooldown
	if slot == 1: cannon_phase = "hold"; release_pending = false; current.duration = 100000.0; current.contact = 1.1
	start(); return true

func punch() -> bool:
	if not can_act() or m1_cooldown > 0 or not game.player.is_on_floor(): return false
	var stomp := m1_next_stomp; m1_next_stomp = not m1_next_stomp
	var can_arm:bool=not controller.damage.missing(0) or not controller.damage.missing(1)
	var can_leg:bool=not controller.damage.missing(2) or not controller.damage.missing(3)
	if not can_arm and not can_leg:return false
	if not can_arm:stomp=true
	if not can_leg:stomp=false
	current = {"id":"m1_stomp" if stomp else "m1_hammer","slot":0,"title":"Pisotón" if stomp else "Puño al suelo","duration":1.3 if stomp else 1.2,"contact":.65 if stomp else .55,"damage":14.0 if stomp else 16.0,"radius":3.0 if stomp else 2.4,"range":0.0 if stomp else 1.9,"ragdoll":1.2,"force":8.0,"vertical":4.0,"move":.18}
	m1_cooldown = 1.5 if stomp else 1.4
	current["limb"]="Izq" if controller.damage.missing(2 if stomp else 0) else "Der"
	start(); return true

func start() -> void:
	elapsed = 0; contacted = false; ram_finished = false; revision += 1; hit_ids.clear()
	direction = Vector3.FORWARD.rotated(Vector3.UP,game.yaw) if game.camera_lock else game.facing_forward()
	cannon_aim = aim_point()
	game.presentation.cancel_emote()
	game.attack_buffer = 0; game.ability_buffer = 0; game.attack_anim = current.duration
	game.skill_vfx.mega_event("prepare",game.player.global_position,direction,current.id,revision)
	game.feedback.sound("mecha_power" if current.id == "cannon" else "mecha_servo_2",game.player.global_position,-6)

func members_available() -> bool:
	var id: String = current.get("id","")
	if id in ["m1_hammer","m1_stomp","seismic"]:
		var index := (0 if id == "m1_hammer" else 2)+(1 if current.get("limb","Der") == "Izq" else 0)
		return not controller.damage.missing(index)
	var slot: int = current.get("slot",0)
	return slot <= 0 or controller.damage.allowed(slot)

func interrupted() -> void:
	if is_instance_valid(aim_laser): aim_laser.hide()
	if is_instance_valid(aim_spot): aim_spot.hide()
	if current.is_empty(): return
	game.skill_vfx.mega_event("cancel",game.player.global_position,direction,current.id,revision)
	current.clear(); cannon_phase = ""; game.attack_anim = 0

func release_cannon() -> void:
	if current.get("id","") == "cannon" and cannon_phase == "hold": release_pending = true

func tick(delta: float) -> void:
	for i in range(4): cooldowns[i] = maxf(0,cooldowns[i]-delta)
	m1_cooldown = maxf(0,m1_cooldown-delta)
	tick_projectiles(delta)
	if current.is_empty(): update_cannon(); return
	if not members_available():
		interrupted();update_cannon();return
	if game.hp <= 0 or game.stun > 0 or game.moves.player_freeze > 0:
		interrupted(); update_cannon(); return
	elapsed += delta; game.attack_anim = maxf(0,float(current.duration)-elapsed)
	if current.id == "cannon":
		if cannon_phase == "hold":
			direction = Vector3.FORWARD.rotated(Vector3.UP,game.yaw)
			cannon_aim = aim_point()
			if elapsed > .25 and not game.input_pressed("ability1"): release_pending = true
			if release_pending and elapsed >= 1.1:
				update_cannon(); fire(); contacted = true
				cannon_phase = "retract"; elapsed = 0; current.duration = .95; cooldowns[0] = 2.0
		elif elapsed >= .95:
			current.clear(); cannon_phase = ""; game.attack_anim = 0
		update_cannon(); return
	update_cannon()
	if elapsed >= float(current.contact) and not contacted:
		contacted = true
		if current.id == "cannon": fire()
		elif current.id == "ram": game.skill_vfx.mega_event("boost",game.player.global_position,direction,current.id,revision)
		else: ground_attack()
	if current.id == "ram" and elapsed >= current.contact and elapsed < 1.25 and not ram_finished:
		ram_contact()
		for i in range(game.player.get_slide_collision_count()):
			if absf(game.player.get_slide_collision(i).get_normal().y) < .5:
				ram_finished = true
				game.skill_vfx.mega_event("crash",game.player.global_position+direction,direction,current.id,revision)
				game.feedback.sound("mecha_armor",game.player.global_position,1)
				break
	if elapsed >= float(current.duration): current.clear(); game.attack_anim = 0

func movement_scale() -> float:
	return float(current.get("move",1.0))

func ram_velocity() -> Vector3:
	return direction*8.0 if current.get("id","") == "ram" and elapsed >= .55 and elapsed < 1.25 and not ram_finished else Vector3.ZERO

func line_clear(from: Vector3, to: Vector3, enemy: Dictionary) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from,to,1)
	query.exclude = [game.player.get_rid(),enemy.body.get_rid()]
	return game.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func ground_point(point: Vector3) -> Variant:
	var query := PhysicsRayQueryParameters3D.create(point+Vector3.UP*1.4,point-Vector3.UP*2.8,1)
	query.exclude = [game.player.get_rid()]
	var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() and hit.normal.dot(Vector3.UP) > .5 else null

func ground_attack() -> void:
	var center: Variant = ground_point(game.player.global_position+direction*float(current.range))
	if not center is Vector3:
		# Edges: resolve on the last safe point between feet and fist.
		for fraction in [.75,.5,.25,0.0]:
			center = ground_point(game.player.global_position+direction*float(current.range)*fraction)
			if center is Vector3: break
		if not center is Vector3: refund_ground(); return
	# El punto frontal no puede aparecer al otro lado de una pared.
	var origin: Vector3 = game.player.global_position+Vector3.UP*.4
	var wall_query := PhysicsRayQueryParameters3D.create(origin,center+Vector3.UP*.4,1)
	wall_query.exclude = [game.player.get_rid()]
	for enemy in game.enemies: wall_query.exclude.append(enemy.body.get_rid())
	var obstruction := game.get_world_3d().direct_space_state.intersect_ray(wall_query)
	if not obstruction.is_empty():
		center = ground_point(obstruction.position+obstruction.normal*.18-Vector3.UP*.4)
		if not center is Vector3: refund_ground(); return
	game.skill_vfx.mega_event("ground",center,direction,current.id,revision)
	game.feedback.sound("mecha_armor",center,1)
	shake(center,.9)
	for enemy in game.enemies:
		var target: Vector3 = preload("res://scripts/combat_geometry.gd").point(enemy,center+Vector3.UP*.5)
		var offset: Vector3 = target-center; var flat := Vector3(offset.x,0,offset.z)
		if flat.length() > float(current.radius) or absf(offset.y) > 1.35: continue
		if not line_clear(center+Vector3.UP*.25,target+Vector3.UP*.5,enemy): continue
		var radial := flat.normalized() if flat.length() > .05 else direction
		var unblockable: bool = int(current.slot) in [2,3] and flat.length() < 1.5
		game.perform_hit(enemy,float(current.damage),0,radial,float(current.force),float(current.vertical),.6,float(current.ragdoll),false,unblockable,"downslam")
	game.arena.urban.hit_props(center,direction)

func refund_ground() -> void:
	var slot: int = current.get("slot",0)
	if slot > 0: cooldowns[slot-1] = 0.0
	else: m1_cooldown = 0
	game.ult_msg = "SIN APOYO / recarga devuelta"; game.ult_msg_time = 1.5

func ram_contact() -> void:
	for enemy in game.enemies:
		var id: int = enemy.body.get_instance_id()
		if id in hit_ids: continue
		var offset: Vector3 = enemy.body.global_position-game.player.global_position
		var flat := Vector3(offset.x,0,offset.z)
		if flat.length() > 2.1 or absf(offset.y) > 2.3 or (flat.length() > .1 and flat.normalized().dot(direction) < .1): continue
		if not line_clear(game.player.global_position+Vector3.UP,enemy.body.global_position+Vector3.UP,enemy): continue
		hit_ids.append(id)
		if game.perform_hit(enemy,current.damage,0,direction,current.force,current.vertical,.7,current.ragdoll,false,false,"heavy"):
			game.skill_vfx.mega_event("crash",enemy.body.global_position,direction,"ram",revision)
			shake(enemy.body.global_position,.8)

func aim_point() -> Vector3:
	var pitch: float = game.pitch
	var ray_direction := Vector3.FORWARD.rotated(Vector3.RIGHT,pitch).rotated(Vector3.UP,game.yaw)
	var start: Vector3 = game.player.global_position+Vector3.UP*2.6
	var end := start+ray_direction*32
	var query := PhysicsRayQueryParameters3D.create(start,end,11)
	query.collide_with_areas = true; query.exclude = controller.damage_exclusions()
	var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
	return end if hit.is_empty() else hit.position

func fire() -> void:
	if projectiles.size() >= 3: return
	var start: Vector3 = game.player.global_position+Vector3.UP*2.15+direction*1.4
	if is_instance_valid(barrel_tip): start = barrel_tip.global_position
	# El cañón inclina ligeramente el disparo; no apunta ni sigue enemigos automáticamente.
	var aim: Vector3 = (cannon_aim-start).normalized()
	var query := PhysicsRayQueryParameters3D.create(game.player.global_position+Vector3.UP*1.7,start,1)
	query.exclude = [game.player.get_rid()]
	var blocked := game.get_world_3d().direct_space_state.intersect_ray(query)
	serial += 1
	var shot := {"position":start,"direction":aim,"distance":0.0,"serial":serial,"profile":current.duplicate(true)}
	game.skill_vfx.mega_event("fire",start,aim,"cannon",serial)
	game.feedback.sound("heavy",start,1); game.feedback.sound("mecha_armor",start,-2)
	game.feedback.sound("mecha_servo_2",start,-10)
	if not blocked.is_empty(): explode(shot,blocked.position); return
	projectiles.append(shot)

func tick_projectiles(delta: float) -> void:
	var space := game.get_world_3d().direct_space_state
	for i in range(projectiles.size()-1,-1,-1):
		var shot: Dictionary = projectiles[i]
		var travel: float = minf(70*delta,32-float(shot.distance))
		var motion: Vector3 = shot.direction*travel
		var query := PhysicsShapeQueryParameters3D.new(); var shape := SphereShape3D.new(); shape.radius = .22
		query.shape = shape; query.transform.origin = shot.position; query.motion = motion; query.collision_mask = 11
		query.collide_with_areas = true; query.exclude = controller.damage_exclusions()
		var initial := space.intersect_shape(query,1)
		var fractions := space.cast_motion(query)
		var hit: bool = not initial.is_empty() or (fractions.size() == 2 and fractions[0] < 1.0)
		if hit:
			var fraction: float = 0 if not initial.is_empty() else fractions[1]
			var point: Vector3 = shot.position+motion*clampf(fraction,0,1)
			explode(shot,point); projectiles.remove_at(i); continue
		shot.position += motion; shot.distance += travel
		if shot.distance >= 32:
			game.skill_vfx.mega_event("fizzle",shot.position,shot.direction,"cannon",shot.serial)
			projectiles.remove_at(i)

func explode(shot: Dictionary, point: Vector3) -> void:
	game.skill_vfx.mega_event("explosion",point,shot.direction,"cannon",shot.serial)
	game.feedback.sound("heavy",point,1); game.feedback.sound("mecha_armor",point,0); shake(point,1)
	for enemy in game.enemies:
		var center: Vector3 = preload("res://scripts/combat_geometry.gd").point(enemy,point)
		var offset := center-point
		if offset.length() > 2.8 or not line_clear(point,center,enemy): continue
		var radial := Vector3(offset.x,0,offset.z).normalized()
		if radial.length() < .1: radial = direction
		var damage: float = float(shot.profile.damage)*lerpf(1,.75,clampf(offset.length()/2.8,0,1))
		game.perform_hit(enemy,damage,0,radial,shot.profile.force,shot.profile.vertical,.65,shot.profile.ragdoll,false,false,"heavy")
	game.arena.urban.hit_props(point,shot.direction)

func shake(point: Vector3, strength: float) -> void:
	if game.online_session() != null: game.online_session().fusion_step.rpc(point,strength,revision)
	else: controller.impulse(point,strength)

func update_cannon() -> void:
	if not is_instance_valid(controller.sequence) or controller.sequence.articulation == null: return
	var rig: Node3D = controller.sequence.articulation
	if not is_instance_valid(barrel_tip):
		barrel_tip = Marker3D.new(); add_child(barrel_tip)
		aim_laser = MeshInstance3D.new(); var beam := CylinderMesh.new(); beam.top_radius = .008; beam.bottom_radius = .008; beam.radial_segments = 6
		aim_laser.mesh = beam; add_child(aim_laser)
		var material := StandardMaterial3D.new(); material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(.4,.95,1,.6); material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		aim_laser.material_override = material; aim_laser.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		aim_spot = MeshInstance3D.new(); var sphere := SphereMesh.new(); sphere.radius = .035; sphere.height = .07
		aim_spot.mesh = sphere; aim_spot.material_override = material; add_child(aim_spot)
	barrel_tip.global_position = rig.muzzle()
	var aiming: bool = current.get("id","") == "cannon" and cannon_phase == "hold" and elapsed > .1 and game.moves.player_freeze <= 0 and game.hp > 0
	aim_laser.visible = aiming; aim_spot.visible = aiming
	if not aiming: return
	var vector := cannon_aim-barrel_tip.global_position
	if vector.length() < .02: return
	aim_laser.global_transform = Transform3D(Basis(Quaternion(Vector3.UP,vector.normalized())),(cannon_aim+barrel_tip.global_position)*.5)
	aim_laser.scale = Vector3(1,vector.length()/2,1)
	aim_spot.global_position = cannon_aim

func pose_state() -> Dictionary:
	return {"slot":current.get("slot",0),"limb":current.get("limb","Der"),"id":current.get("id",""),"time":elapsed,"duration":current.get("duration",1.0),"contact":current.get("contact",.5),"revision":revision,"cooldowns":cooldowns.duplicate(),"m1_cd":m1_cooldown,"direction":direction,"ram_finished":ram_finished,"aim":cannon_aim,"cannon_phase":cannon_phase,"deploy":(clampf(elapsed/1.1,0,1) if cannon_phase == "hold" else (1-clampf(elapsed/.95,0,1) if cannon_phase == "retract" else 0.0))}

func apply_state(data: Dictionary) -> void:
	var id: String = data.get("id","")
	current = {} if id.is_empty() else {"id":id,"slot":data.get("slot",0),"limb":data.get("limb","Der"),"duration":data.get("duration",1.0),"contact":data.get("contact",.5),"move":.65 if id == "cannon" else 0.0}
	cannon_phase = data.get("cannon_phase","")
	elapsed = float(data.get("time",0)); revision = int(data.get("revision",0))
	cooldowns = data.get("cooldowns",[0.0,0.0,0.0,0.0]); m1_cooldown = data.get("m1_cd",0.0)
	cannon_aim = data.get("aim",game.player.global_position+Vector3.FORWARD*20)
	direction = data.get("direction",Vector3.FORWARD); ram_finished = data.get("ram_finished",false)
	update_cannon()

func reset() -> void:
	current.clear(); cannon_phase = ""; release_pending = false; projectiles.clear(); cooldowns = [0.0,0.0,0.0,0.0]; m1_cooldown = 0
	elapsed = 0; m1_next_stomp = false; hit_ids.clear()
	if is_instance_valid(cannon): cannon.queue_free()
	cannon = null
	if is_instance_valid(barrel_tip): barrel_tip.queue_free()
	if is_instance_valid(aim_laser): aim_laser.queue_free(); aim_spot.queue_free()
	barrel_tip = null; aim_laser = null; aim_spot = null

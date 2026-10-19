extends Node3D
# Cinemática recibida + rig mecánico articulado de las 22 mallas originales.
var game: Node3D
var assembly_guard: StaticBody3D
var sequence: Node3D
var cinematic := false
var fused := false
var elapsed := 0.0
var cooldown := 0.0
var revision := 0
var base_state: Dictionary = {}
var origin := Vector3.ZERO
var cast_yaw := 0.0
var shake_time := 0.0
var shake_strength := 0.0
var camera_release := 0.0
var step_distance := 0.0
var step_index := 0
var last_position := Vector3.ZERO
var last_replica_revision := -1
var replica := false
var replica_lift := 0.0
var last_sound_phase := ""
var reset_notice := ""
var replica_delta := .016667
var replica_pose_time := 0.0
var last_step_variant := -1
var heavy_attack := -1.0
var heavy_attack_cd := 0.0
var heavy_contact := false
var heavy_side := "Der"
var combat: Node3D
var spider:Node3D
var damage = preload("res://scripts/mecha_damage.gd").new()
var wreck:Node3D
var death_wait:=0.0
var fused_capsule:CapsuleShape3D
var boost_time := 0.0
var boost_direction := Vector3.FORWARD
var boost_smoke := 0.0
var boost_in_flight := false
var death_broken := false
var hurt_area: Area3D
const HURT_SIZE := Vector3(3.0,4.0,1.7)
const NORMAL_HEIGHT := 2.0
const FUSED_HEIGHT := 4.0
const FUSED_MAX_HP := 300.0
const FUSED_RADIUS := 1.05
const HEAVY_SPEED := 2.35
const HEAVY_WALK_SPEED := 1.05
const HEAVY_REACH := 4.2

func setup(host: Node3D) -> void:
	game = host; name = "FusionController"
	spider=preload("res://scripts/head_spider.gd").new();add_child(spider);spider.setup(self)
	combat = preload("res://scripts/mecha_combat.gd").new(); add_child(combat); combat.setup(self)
	add_child(damage); damage.setup(self)

func start_boost() -> bool:
	if not damage.allowed(4) or not combat.can_act() or game.dash_cd > 0 or boost_time > 0 or not game.player.is_on_floor(): return false
	game.presentation.cancel_emote()
	boost_direction = game.movement()
	if boost_direction.length() < .1: boost_direction = game.facing_forward()
	boost_direction = boost_direction.normalized(); boost_in_flight = true
	boost_time = .48; game.dash_time = boost_time; game.dash_cd = 5.5; boost_smoke = 0
	game.player.velocity = boost_direction*11+Vector3.UP*8.5
	game.skill_vfx.mega_event("launch",game.player.global_position,boost_direction,"boost",combat.revision)
	game.feedback.sound("fusion_thruster",game.player.global_position,0)
	impulse(game.player.global_position,.65)
	return true

func sync_hurtbox() -> void:
	if not is_instance_valid(hurt_area):
		hurt_area = Area3D.new(); hurt_area.name = "MegaHurtVolume"
		hurt_area.collision_layer = 8; hurt_area.collision_mask = 0
		hurt_area.monitoring = false; game.player.add_child(hurt_area)
		var col := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = HURT_SIZE
		col.shape = box; hurt_area.add_child(col); col.position.y = 2.0
	hurt_area.rotation.y = game.model.rotation.y
	var collider: CollisionShape3D = hurt_area.get_child(0)
	var height: float = game.robot_clearance.current_height if game.robot_clearance.current_height > 0 else 4.0
	collider.shape.size.y = height
	collider.position.y = height*.5

func damage_exclusions() -> Array[RID]:
	var result: Array[RID] = [game.player.get_rid()]
	if is_instance_valid(hurt_area): result.append(hurt_area.get_rid())
	return result

func visual() -> Node3D:
	if spider!=null and spider.active():return spider.rig
	return sequence._fusion_root if is_instance_valid(sequence) else null

func busy() -> bool: return cinematic or fused

func site_valid(point: Vector3) -> bool:
	var shape := CylinderShape3D.new(); shape.radius = 5.5; shape.height = 13.0
	var query := PhysicsShapeQueryParameters3D.new(); query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY,point+Vector3.UP*6.6)
	query.collision_mask = 1
	query.exclude = [game.player.get_rid()]
	if not game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(): return false
	var landing := CapsuleShape3D.new(); landing.height = 6; landing.radius = 1.3
	query.shape = landing; query.transform.origin = point+Vector3.UP*3.1; query.collision_mask = 2
	return game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func ground_at(point: Vector3) -> Variant:
	var ray := PhysicsRayQueryParameters3D.create(point+Vector3.UP*2,point-Vector3.UP*6,1)
	var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or hit.normal.dot(Vector3.UP) < .95: return null
	return hit.position+Vector3.UP*.04

func choose_site() -> Variant:
	var current: Variant = ground_at(game.player.global_position)
	if current is Vector3 and site_valid(current): return current
	var candidates: Array[Vector3] = []
	for point in [Vector3.ZERO,Vector3(-16,0,0),Vector3(16,0,0),Vector3(0,0,-16),Vector3(0,0,16),Vector3(-30,0,0),Vector3(30,0,0)]:
		var grounded: Variant = ground_at(point)
		if grounded is Vector3 and site_valid(grounded): candidates.append(grounded)
	candidates.sort_custom(func(a: Vector3,b: Vector3) -> bool: return a.distance_squared_to(game.player.global_position) < b.distance_squared_to(game.player.global_position))
	return candidates[0] if not candidates.is_empty() else null

func request() -> bool:
	var network: Node = game.online_session()
	if network != null:
		for actor in network.actors.values():
			if actor.moves.domain_time > 0 and game.player.global_position.distance_to(actor.moves.domain_center) < 12:
				game.ult_msg = "FUSIÓN / necesita cielo abierto"; game.ult_msg_time = 3; return false
	if not game.robots.active or busy() or cooldown > 0 or not game.can_start_action() or not game.player.is_on_floor(): return false
	if game.charge < 100:
		game.ult_msg = "FUSIÓN / energía %d%% · conecta golpes" % int(game.charge); game.ult_msg_time = 2.5; return false
	var safe: Variant = choose_site()
	if not safe is Vector3:
		game.ult_msg = "FUSIÓN / busca un espacio abierto"; game.ult_msg_time = 3; return false
	var correction: float = game.player.global_position.distance_to(safe)
	origin = safe; cast_yaw = game.model.rotation.y
	base_state = {"layer":game.player.collision_layer,"mask":game.player.collision_mask,"shape":game.robots.naoya.collision.shape.duplicate(),"position":game.robots.naoya.collision.position,"max_hp":game.max_hp}
	game.charge = 0
	revision += 1; elapsed = 0; cooldown = 45; cinematic = true; fused = false; replica = false
	game.presentation.cancel_emote(); game.cancel_skill(); game.physical_ragdoll.cancel(); game.robots.stop_locomotion()
	game.rig_anim.active = false; game.rig_holder.hide(); game.model.hide()
	game.robots.guard_time = 0; game.robots.counter_time = 0; game.robots.counter_response = 0; game.robots.counter_pending = false
	game.player.velocity = Vector3.ZERO; game.player.global_position = origin
	game.player.collision_layer = 0; game.player.collision_mask = 0; game.player.reset_physics_interpolation()
	last_position = origin; step_distance = 0
	create_sequence(game.robots.NAMES[game.robots.index])
	create_guard()
	game.ult_msg = "FUSIÓN / ascenso" if correction < 1 else "FUSIÓN / zona de montaje despejada"
	game.ult_msg_time = 3
	return true

func create_sequence(chassis: String) -> void:
	if is_instance_valid(sequence): sequence.queue_free()
	sequence = preload("res://scripts/fusion_g.gd").new()
	sequence.standalone = false; sequence.automatic_process = false; sequence.autoplay = false
	var roof_height := 0.0
	for offset in [Vector3(-10,0,-5),Vector3(10,0,-5),Vector3(1,0,11)]:
		for fraction in [.0,.25,.5]:
			var start: Vector3 = origin+(offset*(1-fraction)).rotated(Vector3.UP,cast_yaw)
			var ray := PhysicsRayQueryParameters3D.create(start+Vector3.UP*50,start+Vector3.UP*.3,1)
			var roof := game.get_world_3d().direct_space_state.intersect_ray(ray)
			if not roof.is_empty(): roof_height = maxf(roof_height,float(roof.position.y)-origin.y)
	sequence.incoming_lift = replica_lift if replica else maxf(0,roof_height-.5)
	sequence.active_chassis = chassis; sequence.normal_character_height_m = NORMAL_HEIGHT; sequence.fused_height_multiplier = 2.0
	for mesh in game.robots.current.get("meshes",[]):
		sequence.leading_materials.append(mesh.get_active_material(0))
	add_child(sequence); sequence.global_position = origin; sequence.rotation.y = cast_yaw
	sequence.fusion_finished.connect(finished)
	sequence.module_landed.connect(module_landed)
	sequence.phase_changed.connect(phase_changed)
	sequence.play_fusion()

func phase_changed(phase: String) -> void:
	if replica: return
	var sound: String = {"ascent":"fusion_thruster","merge":"mecha_power","assembly":"mecha_servo_1","activation":"mecha_servo_2","impact":"mecha_armor"}.get(phase,"charge")
	game.feedback.sound(sound,origin,-9 if phase != "impact" else -3)
	last_sound_phase = phase
	if phase == "impact":
		if game.online_session() != null: game.online_session().fusion_step.rpc(origin,1.0,step_index)
		else: impulse(origin,1.0)

func module_landed(_piece: String,point: Vector3) -> void:
	if replica: return
	game.feedback.sound("mecha_armor",point,-11)

func finished(_root: Node3D) -> void:
	if replica: return
	clear_guard()
	death_broken = false; death_wait = 0
	damage.configure(sequence.articulation)
	cinematic = false; fused = true; elapsed = sequence.DURATION; camera_release = .65
	game.hp = clampf(game.hp/maxf(1,game.max_hp),0,1)*FUSED_MAX_HP; game.max_hp = FUSED_MAX_HP
	if sequence.articulation != null: sequence.articulation.foot_contact.connect(on_foot_contact)
	game.interface.identity.set_robot_portrait(sequence._fusion_root,sequence._fusion_root.scale.x,-1,4.0)
	game.player.global_position = origin; game.player.velocity = Vector3.ZERO
	game.player.collision_layer = int(base_state.layer); game.player.collision_mask = int(base_state.mask)
	apply_fused_dimensions()
	game.player.reset_physics_interpolation(); last_position = game.player.global_position
	sync_hurtbox()
	game.ult_msg = "JUNKYARD SENTINEL / 300 HP · núcleo activo"; game.ult_msg_time = 5

func tick(delta: float) -> bool:
	spider.return_cd=maxf(0,spider.return_cd-delta)
	if not spider.active():
		spider.scan_cd=maxf(0,spider.scan_cd-delta);spider.cloak_cd=maxf(0,spider.cloak_cd-delta)
	cooldown = maxf(0,cooldown-delta)
	if not busy(): return false
	if death_broken and game.hp <= 0:
		game.clock += delta; game.player.velocity = Vector3.ZERO; tick_death(delta)
		if can_respawn(): reset(); game.respawn_player()
		return true
	game.clock += delta
	if spider.active():
		spider.tick(delta);return true
	var requested_slot: int = game.buffered_ability if game.ability_buffer > 0 else 0
	var request_attack: bool = game.attack_buffer > 0 or (bool(game.preferences.values.hold_attack) and game.input_pressed("attack") and not game.hud_attack_requires_release)
	game.attack_buffer = 0; game.ability_buffer = 0; game.jump_buffer = 0; game.attack_anim = 0; game.block = false
	game.stun = maxf(0,game.stun-delta); game.player_wakeup_protection = maxf(0,game.player_wakeup_protection-delta)
	game.ult_msg_time = maxf(0,game.ult_msg_time-delta)
	if cinematic:
		if game.player.global_position.distance_to(origin) > 1.0: reset(); return false
		game.player.velocity = Vector3.ZERO; game.player.global_position = origin
		sequence.advance(delta); elapsed = sequence._clock
	elif fused:
		game.dash_cd = maxf(0,game.dash_cd-delta)
		if game.presentation.emote_time > 0 and (game.movement().length() > .1 or game.input_pressed("block") or game.stun > 0 or not game.player.is_on_floor()): game.presentation.cancel_emote()
		if game.moves.tick_player_freeze(delta):
			combat.interrupted(); combat.tick(delta); boost_time = 0; game.dash_time = 0
			return true
		game.block = damage.guard_available() and game.input_pressed("block") and game.stun <= 0 and combat.current.is_empty() and boost_time <= 0 and game.player.is_on_floor()
		if requested_slot > 0 and boost_time <= 0: combat.press(requested_slot)
		if request_attack and boost_time <= 0: combat.punch()
		combat.tick(delta)
		heavy_attack = combat.elapsed if not combat.current.is_empty() else -1.0
		heavy_attack_cd = combat.m1_cooldown; heavy_contact = combat.contacted
		var direction: Vector3 = game.movement()
		var speed := HEAVY_WALK_SPEED if game.input_pressed("walk") else HEAVY_SPEED
		if game.block: speed *= .4
		speed *= combat.movement_scale()*damage.speed_scale()
		speed *= lerpf(1.0,.72,game.robot_clearance.pressure)
		if game.stun > 0: direction = Vector3.ZERO; boost_time = 0
		if boost_time > 0:
			boost_time = maxf(0,boost_time-delta)
			game.player.velocity.x = boost_direction.x*11; game.player.velocity.z = boost_direction.z*11
			boost_smoke -= delta
			if boost_smoke <= 0:
				boost_smoke = .07
				game.skill_vfx.mega_event("smoke",game.player.global_position,boost_direction,"boost",combat.revision)
		else:
			var ram: Vector3 = combat.ram_velocity()
			if ram.length() > 0:
				game.player.velocity.x = ram.x; game.player.velocity.z = ram.z
			else:
				var accel := 16.0 if not combat.current.is_empty() else 4.0
				game.player.velocity.x = move_toward(game.player.velocity.x,direction.x*speed,delta*accel)
				game.player.velocity.z = move_toward(game.player.velocity.z,direction.z*speed,delta*accel)
		game.dash_time = boost_time
		var airborne_before: bool = not game.player.is_on_floor()
		game.player.velocity.y -= game.GRAVITY*delta
		if boost_time <= 0 and game.stun <= 0: preload("res://scripts/terrain_steps.gd").prepare(game.player,delta)
		game.robot_clearance.tick(delta)
		game.player.move_and_slide()
		if boost_in_flight and airborne_before and game.player.is_on_floor():
			boost_in_flight = false; boost_time = 0; game.dash_time = 0
			game.player.velocity.x = direction.x*speed; game.player.velocity.z = direction.z*speed
			game.skill_vfx.mega_event("land",game.player.global_position,boost_direction,"boost",combat.revision)
			game.feedback.sound("mecha_step_0",game.player.global_position,1)
			if game.online_session() != null: game.online_session().fusion_step.rpc(game.player.global_position,.65,step_index)
			else: impulse(game.player.global_position,.65)
		if game.player.is_on_ceiling(): boost_time = 0; game.dash_time = 0; game.player.velocity.y = minf(0,game.player.velocity.y)
		var target_yaw: float = game.model.rotation.y
		if not combat.current.is_empty(): target_yaw = atan2(-combat.direction.x,-combat.direction.z)
		elif boost_time > 0: target_yaw = atan2(-boost_direction.x,-boost_direction.z)
		elif game.block: target_yaw = game.yaw
		elif game.camera_aim_locked():
			# La cabeza mira primero; caderas y pies acompañan solo giros amplios.
			var relative_view: float = wrapf(game.yaw-game.model.rotation.y,-PI,PI)
			var freedom := .48 if direction.length() > .1 else .60
			target_yaw += relative_view-clampf(relative_view,-freedom,freedom)
		elif direction.length() > .1: target_yaw = atan2(-direction.x,-direction.z)
		game.model.rotation.y = lerp_angle(game.model.rotation.y,target_yaw,1-exp(-delta*12))
		sync_hurtbox()
		sequence.global_position = game.player.global_position; sequence.rotation.y = game.model.rotation.y
		var displacement: Vector3 = game.player.position-last_position
		var traveled: float = Vector2(displacement.x,displacement.z).length()
		last_position = game.player.position
		if sequence.articulation != null:
			sequence.articulation.configure_locomotion(game.player,false,displacement/maxf(delta,.001))
			sequence.articulation.configure_view(game.yaw,game.pitch,game.camera_lock)
			sequence.articulation.emote_state = {"index":game.presentation.emote_index,"time":game.presentation.emote_elapsed} if game.presentation.emote_time > 0 else {}
			sequence.articulation.gait_enabled = bool(game.preferences.values.procedural_gait) and game.stun <= 0
			sequence.articulation.strike = -1
			sequence.articulation.action = combat.pose_state(); sequence.articulation.boosting = boost_time > 0
			sequence.articulation.guarding = game.block
			sequence.articulation.locomotion(delta,Vector2(game.player.velocity.x,game.player.velocity.z).length(),game.player.is_on_floor(),game.player.velocity.y,traveled,game.stun > 0 or not combat.current.is_empty())
		combat.update_cannon()
		sequence.set_engine_active(true,Vector2(game.player.velocity.x,game.player.velocity.z).length())
		if game.player.position.y < -12: reset(); game.respawn_player()
	return true

func resolve_heavy_contact() -> void:
	if not combat.current.is_empty(): combat.ground_attack()

func on_foot_contact(_side: String, point: Vector3) -> void:
	if damage.missing(2 if _side == "Der" else 3):return
	if replica or not fused or not game.player.is_on_floor() or game.moves.player_freeze > 0: return
	if Vector2(game.player.velocity.x,game.player.velocity.z).length()<.12:return
	var ray := PhysicsRayQueryParameters3D.create(point+Vector3.UP*.22,point-Vector3.UP*.95,1)
	ray.exclude = [game.player.get_rid()]
	var ground := game.get_world_3d().direct_space_state.intersect_ray(ray)
	if ground.is_empty() or ground.normal.dot(Vector3.UP) < .55: return
	point=ground.position
	if not game.feedback.planted_step(_side,point,true):return
	step_index+=1
	last_step_variant = (last_step_variant+1)%3
	game.feedback.sound("fusion_step",point,-13)
	sequence.dust.puff(point,.35,Color(.68,.63,.53),false)
	if game.online_session() != null: game.online_session().fusion_step.rpc(point,.55,step_index)
	else: impulse(point,.55)

func protected_m1(attacker_is_mega: bool = false) -> bool:
	return fused and not attacker_is_mega and combat.current.get("id","") in ["m1_hammer","m1_stomp"]

func receive_enemy(enemy: Dictionary,offset: Vector3) -> void:
	if spider.active():
		var source:Vector3=enemy.body.global_position+Vector3.UP*1.1
		var target:Vector3=game.player.global_position+spider.normal*.32
		if source.distance_to(target)>2.5:return
		var ray:=PhysicsRayQueryParameters3D.create(source,target,1);ray.exclude=[game.player.get_rid(),enemy.body.get_rid()]
		if game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():spider.take_damage(10.0 if int(enemy.combo)==4 else 6.0)
		return
	if game.hp<=0 or cinematic or (game.stun > 0 and not protected_m1()) or game.player_wakeup_protection > 0: return
	if game.block and game.facing_forward().dot((enemy.body.position-game.player.position).normalized()) > .25:
		game.feedback.sound("mecha_armor",game.player.position,-4); return
	var damage := 10.0 if int(enemy.combo) == 4 else 6.0
	if game.moves.player_freeze > 0: game.moves.break_player_frame("hit")
	game.hp -= damage
	self.damage.record(damage,game.player.global_position+Vector3.UP*2.15+(enemy.body.global_position-game.player.global_position).normalized()*.8)
	if not protected_m1():
		game.stun = .3; game.player.velocity = offset.normalized()*2; combat.interrupted()
	game.feedback.sound("heavy",game.player.global_position,-4)
	if game.hp <= 0: game.on_player_death()

func camera_update(camera: Camera3D,delta: float) -> bool:
	if spider.active():spider.camera_update(camera,delta);return true
	if death_broken:
		var target:Vector3=game.player.global_position+Vector3.UP*1.2
		var point:Vector3=game.player.global_position+Vector3(6,4.5,7).rotated(Vector3.UP,game.yaw)
		camera.global_position = camera.global_position.lerp(point,1-exp(-delta*4))
		if camera.global_position.distance_to(target)>.1:camera.look_at(target)
		return true
	if not cinematic or not is_instance_valid(sequence): return false
	var focus := origin+Vector3.UP*(2.7+sin(elapsed*.22)*.35)
	var offset := Vector3(6.1,5.0,12.5).rotated(Vector3.UP,cast_yaw+PI*smoothstep(8.5,10.4,elapsed))
	var wanted := origin+offset
	var ray := PhysicsRayQueryParameters3D.create(focus,wanted,1)
	var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty(): wanted = hit.position+hit.normal*.3
	camera.global_position = camera.global_position.lerp(wanted,1-exp(-delta*5)) if elapsed > .1 else wanted
	if camera.global_position.distance_to(focus) > .05: camera.look_at(focus)
	camera.fov = lerpf(camera.fov,58,1-exp(-delta*5))
	return true

func impulse(point: Vector3,strength: float) -> void:
	var distance: float = game.player.global_position.distance_to(point)
	if distance >= 4: return
	shake_strength = maxf(shake_strength,strength*pow(1-distance/4,2)); shake_time = .34

func camera_shake(camera: Camera3D,delta: float) -> void:
	shake_time = maxf(0,shake_time-delta)
	if shake_time <= 0: shake_strength = 0; return
	var amount: float = shake_strength*float(game.preferences.values.shake)*shake_time/.34
	camera.position += Vector3(sin(game.clock*71),sin(game.clock*55),0)*amount*.14

func break_apart(remaining:float = 3.6) -> void:
	if death_broken or not fused or not is_instance_valid(sequence): return
	death_broken = true
	var debris := preload("res://scripts/mecha_wreck.gd").new()
	game.get_parent().add_child(debris); debris.capture(sequence._fusion_root,revision)
	wreck=debris; debris.remaining=clampf(remaining,0,3.6); death_wait=3.85; damage.begin_cleanup(3.6)
	if sequence.articulation != null: sequence.articulation.dead=true
	sequence._fusion_root.hide(); sequence.set_engine_active(false)
	combat.interrupted(); boost_time = 0
	game.player.collision_layer = 0
	if is_instance_valid(hurt_area): hurt_area.collision_layer = 0
	if not replica:game.skill_vfx.mega_event("land",game.player.global_position,game.facing_forward(),"death",revision)

func tick_death(delta:float)->void:
	death_wait=maxf(0,death_wait-delta)
func can_respawn()->bool:
	return death_wait<=0 and (not is_instance_valid(wreck) or wreck.remaining<=0) and damage.remnants_gone()

func reset() -> void:
	if is_instance_valid(spider):spider.reset()
	if is_instance_valid(wreck): wreck.queue_free()
	wreck=null
	if not busy() and not is_instance_valid(sequence) and base_state.is_empty(): return
	if game.moves.player_freeze > 0: game.moves.clear_player_frame()
	clear_guard()
	damage.clear(); death_wait=0
	if is_instance_valid(hurt_area): hurt_area.collision_layer = 0; hurt_area.queue_free()
	hurt_area = null
	if is_instance_valid(sequence): sequence.stop(); sequence.queue_free()
	sequence = null
	if not base_state.is_empty():
		var restored_max: float = base_state.get("max_hp",100.0)
		game.hp = clampf(game.hp/maxf(1,game.max_hp),0,1)*restored_max; game.max_hp = restored_max
		game.player.collision_layer = int(base_state.layer); game.player.collision_mask = int(base_state.mask)
		game.robots.naoya.collision.shape = base_state.shape; game.robots.naoya.collision.position = base_state.position
	cinematic = false; fused = false; elapsed = 0; cooldown = 0; base_state.clear()
	heavy_attack = -1; heavy_attack_cd = 0; heavy_contact = false
	boost_time = 0; boost_in_flight = false; death_broken = false; game.dash_time = 0
	combat.reset()
	game.attack_anim=0;game.attack_buffer=0;game.ability_buffer=0;game.block=false
	game.presentation.cancel_emote()
	game.skill_vfx.clear()
	if game.rig_holder != null: game.rig_holder.show(); game.rig_anim.active = true
	if game.robots.active and game.interface.identity != null: game.interface.identity.set_robot_portrait(game.rig_scene,game.rig_holder.scale.x,game.robots.index)
	game.player.velocity = Vector3.ZERO; game.camera_initialized = false
	last_replica_revision = -1

func state() -> Dictionary:
	return {"spider":spider.snapshot(),"cinematic":cinematic,"fused":fused,"elapsed":elapsed,"cooldown":cooldown,"revision":revision,"origin":origin,"yaw":cast_yaw,"lift":sequence.incoming_lift if is_instance_valid(sequence) else 0.0,"chassis":game.robots.NAMES[game.robots.index] if game.robots.active else "George","swing":heavy_attack/.95 if heavy_attack >= 0 else -1.0,"swing_side":heavy_side,"guard":game.block,"gait":sequence.articulation.phase if is_instance_valid(sequence) and sequence.articulation != null else 0.0,"dead":death_broken,"wreck_time":wreck.remaining if is_instance_valid(wreck) else 0.0,"damage":damage.state(),"death_wait":death_wait,"view_locked":game.camera_lock,"view":Vector2(game.yaw,game.pitch),"emote":{"index":game.presentation.emote_index,"time":game.presentation.emote_elapsed} if game.presentation.emote_time > 0 else {},"feet":sequence.articulation.gait.snapshot() if is_instance_valid(sequence) and sequence.articulation != null else {},"rig_clock":sequence.articulation.clock if is_instance_valid(sequence) and sequence.articulation != null else 0.0,"velocity":game.player.velocity,"grounded":game.player.is_on_floor(),"combat":combat.pose_state(),"boost":boost_time,"boost_dir":boost_direction,"dash_cd":game.dash_cd}

func apply_state(data: Dictionary) -> void:
	var previously_fused := fused
	var active: bool = bool(data.get("cinematic",false)) or bool(data.get("fused",false))
	if not active:
		if busy(): reset()
		return
	replica = true; replica_lift = float(data.get("lift",0.0))
	if base_state.is_empty(): base_state = {"layer":game.player.collision_layer,"mask":game.player.collision_mask,"shape":game.robots.naoya.collision.shape.duplicate(),"position":game.robots.naoya.collision.position,"max_hp":100.0}
	if int(data.revision) != last_replica_revision or not is_instance_valid(sequence):
		origin = data.origin; cast_yaw = data.yaw
		create_sequence(data.chassis); last_replica_revision = int(data.revision)
	if cinematic and bool(data.fused): camera_release = .65
	cinematic = data.cinematic; fused = data.fused; elapsed = data.elapsed; cooldown = data.cooldown
	game.rig_holder.hide(); game.model.hide()
	game.player.collision_layer = 0 if cinematic else int(base_state.layer); game.player.collision_mask = 0 if cinematic else int(base_state.mask)
	if fused:
		apply_fused_dimensions()
		sync_hurtbox()
	sequence.global_position = origin if cinematic else game.player.global_position
	sequence.rotation.y = cast_yaw if cinematic else game.model.rotation.y
	if cinematic or sequence.articulation == null: sequence.seek(elapsed)
	if fused and sequence.articulation != null:
		if damage.rig != sequence.articulation:damage.configure(sequence.articulation)
		damage.apply_state(data.get("damage",{}))
		if bool(data.get("dead",game.hp<=0)):
			if not death_broken: break_apart(float(data.get("wreck_time",3.6)))
			if is_instance_valid(wreck): wreck.remaining=minf(wreck.remaining,float(data.get("wreck_time",wreck.remaining)))
			game.player.collision_layer=0
			if is_instance_valid(hurt_area):hurt_area.collision_layer=0
		death_wait=float(data.get("death_wait",0))
		sequence.set_engine_active(game.hp > 0)
		sequence.articulation.phase = float(data.get("gait",0))
		sequence.articulation.clock = float(data.get("rig_clock",0))
		var velocity: Vector3 = data.get("velocity",Vector3.ZERO)
		sequence.articulation.configure_locomotion(game.player,true,velocity)
		var view: Vector2 = data.get("view",Vector2(game.model.rotation.y,0))
		sequence.articulation.configure_view(view.x,view.y,bool(data.get("view_locked",false)))
		sequence.articulation.emote_state = data.get("emote",{}).duplicate()
		sequence.articulation.gait_enabled = bool(game.preferences.values.procedural_gait) and not data.get("feet",{}).is_empty()
		sequence.articulation.gait.accept_state(data.get("feet",{}),sequence.articulation)
		combat.apply_state(data.get("combat",{}))
		boost_time = float(data.get("boost",0)); boost_direction = data.get("boost_dir",Vector3.FORWARD)
		game.dash_time = boost_time; game.dash_cd = float(data.get("dash_cd",0))
		sequence.articulation.action = combat.pose_state(); sequence.articulation.boosting = boost_time > 0
		sequence.articulation.strike = -1
		sequence.articulation.strike_side = data.get("swing_side","Der"); sequence.articulation.guarding = bool(data.get("guard",false))
		var frozen := float(game.full_state.get("full",{}).get("moves",{}).get("freeze",0)) > 0 if "full_state" in game else false
		if not frozen and not death_broken: sequence.articulation.locomotion(replica_delta,Vector2(velocity.x,velocity.z).length(),bool(data.get("grounded",true)),velocity.y,0,true)
		if not previously_fused: game.interface.identity.set_robot_portrait(sequence._fusion_root,sequence._fusion_root.scale.x,-1,4.0)
	spider.accept(data.get("spider",{}),replica_delta)
	if cinematic and not is_instance_valid(assembly_guard): create_guard()
	if not cinematic: clear_guard()

func blend_camera(camera: Camera3D,wanted: Vector3,delta: float) -> Vector3:
	if camera_release <= 0: return wanted
	camera_release = maxf(0,camera_release-delta)
	return camera.global_position.lerp(wanted,1-exp(-delta*7))

func create_guard() -> void:
	if is_instance_valid(assembly_guard): return
	assembly_guard = StaticBody3D.new(); assembly_guard.name = "FusionAssemblyBoundary"; add_child(assembly_guard)
	assembly_guard.global_position = origin; assembly_guard.collision_layer = 0 if replica else 1
	var shape := CollisionShape3D.new(); var capsule := CapsuleShape3D.new(); capsule.height = 6.0; capsule.radius = 1.25
	shape.shape = capsule; shape.position.y = 3.1; assembly_guard.add_child(shape)
func clear_guard() -> void:
	if not is_instance_valid(assembly_guard): return
	assembly_guard.collision_layer = 0; assembly_guard.queue_free(); assembly_guard = null

func apply_fused_dimensions() -> void:
	if fused_capsule == null:
		fused_capsule=CapsuleShape3D.new();fused_capsule.height=FUSED_HEIGHT;fused_capsule.radius=FUSED_RADIUS
	if game.robots.naoya.collision.shape != fused_capsule:
		game.robots.naoya.collision.shape=fused_capsule
		game.robots.naoya.collision.position=Vector3.UP*FUSED_HEIGHT*.5

func _exit_tree() -> void:
	if is_instance_valid(wreck):wreck.queue_free()

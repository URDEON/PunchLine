extends Node
# Segundo personaje. Solo el chasis activo determina sus ataques y habilidades.
const NAMES := ["Leela","Stan","George","Mike"]
const SPEEDS := [1.10,.80,1.0,.88]
const DURATIONS := [.42,.68,.44,.48]
const DAMAGE := [5.0,10.0,6.0,4.0]
const REACH := [2.5,2.7,3.0,2.4]
const Catalog := preload("res://scripts/mecha_move_catalog.gd")
const TITLES = Catalog.BASE_NAMES
const EMOTES := [
	{"name":"Baile mecánico","clip":"Dance","speed":1.0,"music":true},
	{"name":"Saludo","clip":"Hello","speed":1.0,"music":false},
	{"name":"Afirmativo","clip":"Yes","speed":1.0,"music":false},
	{"name":"Negativo","clip":"No","speed":1.0,"music":false}]
var game: Node3D
var active := false
var index := -1
var color_index := 0
var generation := 0
var rng := RandomNumberGenerator.new()
var naoya: Dictionary = {}
var cached: Dictionary = {}
var current: Dictionary = {}
var cooldowns := [0.0,0.0,0.0,0.0]
var attack: Dictionary = {}
var elapsed := 0.0
var contacts: Array[int] = []
var hit_ids: Array[int] = []
var guard_time := 0.0
var counter_time := 0.0
var last_clip := ""
var counter_response := 0.0
var last_attack_revision := -1
var revision := 0
var counter_recovery := 0.0
var counter_pending := false
var sidestep_time := 0.0
var sidestep_direction := Vector3.ZERO
var forced := -1 # Solo utilizado por el laboratorio explícito.

func setup(host: Node3D) -> void:
	game = host; rng.randomize()
	for key in ["rig_holder","rig_scene","rig_anim","rig_anim_names","physical_ragdoll"]: naoya[key] = game.get(key)
	for child in game.player.get_children():
		if child is CollisionShape3D: naoya["collision"] = child; naoya["shape"] = child.shape.duplicate(); naoya["collision_position"] = child.position

func select(character: int) -> void:
	if game.fusion.death_broken:return
	if game.fusion.busy(): game.fusion.reset()
	if character not in [0,1]: return
	if (character == 1) == active: return
	game.moves.clear_player_frame(); game.moves.end_domain(); game.presentation.reset(); game.cancel_skill()
	game.physical_ragdoll.cancel(); stop_locomotion(); game.locomotion_tree.active = false
	game.rig_anim.active = false; game.rig_holder.hide(); game.moves.curse.hide(); game.form = "BASE"; game.charge = 0
	active = character == 1
	if not active:
		game.robot_clearance.restore()
		for key in ["rig_holder","rig_scene","rig_anim","rig_anim_names","physical_ragdoll"]: game.set(key,naoya[key])
		naoya.collision.shape = naoya.shape; naoya.collision.position = naoya.collision_position
		game.rig_holder.show(); game.rig_anim.active = not game.paused
		game.rig_current_anim = StringName(); game.visual_motion.bridge_weight = 0
	game.respawn_player()
	game.interface.refresh_characters()
	game.interface.select_tab("character")

func spawn() -> void:
	if not active: return
	game.physical_ragdoll.cancel(); stop_locomotion(); game.rig_anim.active = false; game.rig_holder.hide()
	var previous := index
	if forced >= 0: index = clampi(forced,0,3)
	else:
		index = rng.randi_range(0,3)
		if index == previous: index = (index+1+rng.randi_range(0,2))%4
	color_index = rng.randi_range(0,4); generation += 1
	if not cached.has(index): cached[index] = make_model(index)
	current = cached[index]
	for key in ["rig_holder","rig_scene","rig_anim","rig_anim_names","physical_ragdoll"]: game.set(key,current[key])
	game.rig_current_anim = StringName(); last_clip = ""; last_attack_revision = -1
	apply_color(); game.rig_holder.show(); game.rig_anim.active = not game.paused
	game.model.hide(); game.locomotion_tree.active = false
	game.player.velocity = Vector3.ZERO
	var capsule := CapsuleShape3D.new(); capsule.height = 2.0; capsule.radius = [.32,.44,.40,.46][index]
	naoya.collision.shape = capsule; naoya.collision.position = Vector3.UP*1.0
	cooldowns = [0.0,0.0,0.0,0.0]; sidestep_time = 0.0; sidestep_direction = Vector3.ZERO; guard_time = 0; counter_time = 0; counter_response = 0; counter_pending = false; counter_recovery = 0; cancel()
	game.ult_msg = "ROBOT · "+NAMES[index]; game.ult_msg_time = 2
	sync_transform()
	if game.interface.identity != null: game.interface.identity.set_robot_portrait(game.rig_scene,game.rig_holder.scale.x,index)

func make_model(model_index: int) -> Dictionary:
	var holder := Node3D.new(); holder.name = "Robot_"+NAMES[model_index]
	game.player.add_child(holder)
	var scene: Node3D = load("res://assets/characters/robots/"+NAMES[model_index]+"/model.gltf").instantiate()
	holder.add_child(scene)
	var skeleton: Skeleton3D = game.visual_motion.find_skeleton(scene)
	var player: AnimationPlayer = game.find_animation_player(scene)
	var mesh_list: Array[MeshInstance3D] = []; preload("res://scripts/mesh_pose_snapshot.gd").collect(scene,mesh_list)
	var bounds := AABB()
	var first := true
	for mesh in mesh_list:
		var box: AABB = holder.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
		bounds = box if first else bounds.merge(box); first = false
	holder.scale = Vector3.ONE*(2.0/maxf(bounds.size.y,.1))
	holder.position.y = -bounds.position.y*holder.scale.y
	var names: Dictionary = {}
	for key in player.get_animation_list():
		var short: String = String(key).get_slice("/",String(key).get_slice_count("/")-1)
		names[short.to_lower()] = key
		player.get_animation(key).loop_mode = Animation.LOOP_LINEAR if short.begins_with("Walk") or short.begins_with("Run") or short in ["Idle","Dance"] else Animation.LOOP_NONE
		if short.begins_with("Walk") or short.begins_with("Run") or short == "Idle":
			for track in range(player.get_animation(key).get_track_count()): player.get_animation(key).track_set_interpolation_type(track,Animation.INTERPOLATION_CUBIC)
	var data := {"rig_holder":holder,"rig_scene":scene,"rig_anim":player,"rig_anim_names":names,"meshes":mesh_list,"skeleton":skeleton}
	var movement := preload("res://scripts/robot_locomotion.gd").new(); holder.add_child(movement); movement.setup(game,data,model_index in [0,2])
	data["locomotion"] = movement
	var grounding := preload("res://scripts/robot_grounding.gd").new(); skeleton.add_child(grounding); grounding.setup(game,data)
	data["grounding"] = grounding
	var procedural := preload("res://scripts/robot_procedural_motion.gd").new()
	skeleton.add_child(procedural)
	procedural.setup(game,data)
	data["procedural"] = procedural
	var physics := preload("res://scripts/robot_ragdoll.gd").new(); game.add_child(physics)
	physics.hull_profile = NAMES[model_index]
	physics.setup(game.player,holder,skeleton,player,movement.tree); data["physical_ragdoll"] = physics
	create_guard(player,skeleton,names)
	create_dash(player,names)
	if model_index == 0: create_sweep(player,names)
	return data

func apply_color() -> void:
	var file := "base.png" if color_index == 0 else "color_%d.webp" % color_index
	var texture: Texture2D = load("res://assets/characters/robots/"+NAMES[index]+"/"+file)
	for mesh in current.meshes:
		var original: StandardMaterial3D = mesh.mesh.surface_get_material(0)
		var material := original.duplicate() as StandardMaterial3D
		material.albedo_texture = texture; material.roughness = .8; material.metallic = .15
		mesh.material_override = material

func sync_transform() -> void:
	if active and not game.physical_ragdoll.active:
		game.rig_holder.rotation = Vector3(0,game.model.rotation.y+PI,0)

func ability_count() -> int: return TITLES[index].size() if active else 0
func speed_mult() -> float: return SPEEDS[index]*(.35 if counter_recovery > 0 else 1.0) if active else 1.0
func title(slot: int) -> String: return TITLES[index][slot-1] if slot <= ability_count() else "Sin habilidad"
func available(slot: int) -> bool: return active and slot >= 1 and slot <= ability_count()

func punch() -> void:
	if game.attack_cd > 0 or not game.can_start_action() or game.input_pressed("block"): return
	game.presentation.cancel_emote()
	game.combo = 0 if game.combo_timeout <= 0 else game.combo
	game.combo = game.combo%4+1; game.combo_timeout = 1.45
	var final: bool = game.combo == 4
	var duration: float = DURATIONS[index]+(.20 if final else 0)
	var clip := "Kick" if index == 0 or (index == 2 and final) else "Punch"
	game.attack_cd = duration+.04; game.attack_anim = duration
	game.attack_hit_done = true
	begin({"clip":clip,"duration":duration,"contacts":[duration*.53],"damage":DAMAGE[index]+(6 if final else 0),"range":REACH[index],"ragdoll":1.15 if final else 0.0,"vertical":2.5,"force":10.0 if final else 1.0,"aoe":false,"slam":false},false)
	game.skill_vfx.cast(0)

func press(slot: int) -> bool:
	if not available(slot) or cooldowns[slot-1] > 0 or not game.can_start_action(): return false
	game.presentation.cancel_emote(); cooldowns[slot-1] = [6.0,8.0,7.0,0.0][slot-1]
	if index == 3:
		if slot == 3:
			# Desvío corto sin teletransporte: mueve CharacterBody3D con colisiones.
			var right: Vector3 = game.facing_forward().cross(Vector3.UP).normalized()
			var intent: Vector3 = game.movement()
			var sign: float = -1.0 if intent.dot(right) < -0.1 else 1.0
			sidestep_direction = right*sign
			sidestep_time = 0.24
			game.skill_active = "robot"
			game.attack_anim = sidestep_time
			game.skill_vfx.cast(slot)
			return true
		if slot == 1:
			guard_time = 1.6; game.feedback.sound("block",game.player.position); counter_pending = false; revision += 1
		else: counter_time = .45; counter_pending = true; revision += 1
		game.skill_vfx.cast(slot)
		return true
	var clip := "Kick" if index == 0 or (index == 2 and slot == 3) else "Punch"
	var duration := .72 if index != 1 else (0.82 if slot == 3 else 1.0)
	var damage := 14.0 if index != 1 else (16.0 if slot == 3 else 23.0)
	var contact_times: Array = [duration*.52]
	if index == 2 and slot == 1: contact_times = [.24,.70]; duration = .95; damage = 8
	if index == 0 and slot in [2,3] and game.player.is_on_floor(): game.player.velocity.y = 6.5
	begin({"clip":clip,"duration":duration,"contacts":contact_times,"damage":damage,"range":REACH[index]+(.8 if index == 1 and slot == 3 else .3),"ragdoll":1.25,"vertical":9.0 if slot == 2 and index == 0 else 2.5,"force":(18.0 if slot == 3 else 13.0) if index == 1 else 8.0,"aoe":slot == 1 and index == 0 or slot == 2 and index == 1,"slam":slot == 3 and index == 0 or slot == 2 and index == 1,"advance":slot == 2 and index == 2,"slot":slot},true)
	configure_skill(slot)
	game.skill_vfx.cast(slot)
	return true

func begin(definition: Dictionary, skill: bool) -> void:
	attack = definition; elapsed = 0; contacts.clear(); hit_ids.clear(); revision += 1
	if skill: game.skill_active = "robot"
	game.attack_anim = definition.duration; game.attack_hit_done = true
	game.attack_variant = "normal"

func cancel() -> void:
	sidestep_time = 0.0
	attack.clear(); elapsed = 0; contacts.clear(); hit_ids.clear()
	if game != null and game.skill_active == "robot": game.skill_active = ""

func counter(enemy: Dictionary) -> bool:
	if counter_time <= 0: return false
	var offset: Vector3 = enemy.body.position-game.player.position; offset.y = 0
	if offset.normalized().dot(game.facing_forward()) < .2: return false
	counter_time = 0; counter_pending = false; counter_response = .55; game.attack_anim = .55; game.attack_hit_done = true; game.interrupt_enemy_attack(enemy)
	game.perform_hit(enemy,14,game.FOURTH_M1_CHARGE,game.facing_forward(),8,2,.7,.9,false,false,"heavy")
	game.skill_vfx.impact_local(2,enemy.body.global_position+Vector3.UP)
	return true

func tick(delta: float) -> void:
	if not active: return
	counter_recovery = maxf(0,counter_recovery-delta)
	for i in range(4): cooldowns[i] = maxf(0,cooldowns[i]-delta)
	guard_time = maxf(0,guard_time-delta); counter_time = maxf(0,counter_time-delta); counter_response = maxf(0,counter_response-delta)
	if sidestep_time > 0:
		sidestep_time = maxf(0,sidestep_time-delta)
		if sidestep_time <= 0 and game.skill_active == "robot": game.skill_active = ""
	if counter_pending and counter_time <= 0:
		counter_pending = false; counter_recovery = .35
	if attack.is_empty(): return
	if game.stun > 0 or game.player_ragdoll or game.moves.player_freeze > 0:
		cancel(); game.attack_anim = 0; return
	elapsed += delta
	if bool(attack.get("advance",false)) and elapsed >= float(attack.get("contact_start",.12)) and not contacts.has(-1):
		resolve_contact()
		if not hit_ids.is_empty(): contacts.append(-1)
	for i in range(attack.contacts.size()):
		if elapsed >= attack.contacts[i] and not contacts.has(i) and not bool(attack.get("advance",false)):
			contacts.append(i); hit_ids.clear(); resolve_contact()
	if elapsed >= attack.duration: cancel()

func velocity() -> Vector3:
	if sidestep_time > 0: return sidestep_direction*8.0
	return game.facing_forward()*10 if not attack.is_empty() and bool(attack.get("advance",false)) and elapsed < .42 else Vector3.ZERO

func resolve_contact() -> void:
	var definition: Dictionary = attack.duplicate(true)
	if definition.is_empty(): return
	var forward: Vector3 = game.facing_forward()
	for enemy in game.enemies:
		var offset: Vector3 = preload("res://scripts/combat_geometry.gd").offset(enemy,game.player.global_position)
		if absf(offset.y) > 1.8: continue
		offset.y = 0
		if offset.length() > float(definition.range): continue
		if not definition.slam and offset.length() > .01 and offset.normalized().dot(forward) < (-.05 if definition.aoe else .35): continue
		var ray := PhysicsRayQueryParameters3D.create(game.player.position+Vector3.UP,enemy.body.position+Vector3.UP,1)
		ray.exclude = [game.player.get_rid(),enemy.body.get_rid()]
		if not game.player.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		var final_contact: bool = definition.contacts.size() == 1 or elapsed >= float(definition.contacts[-1])-.001
		var gain: float = game.FOURTH_M1_CHARGE if definition.has("slot") or game.combo == 4 else game.M1_CHARGE
		if definition.contacts.size() > 1: gain /= float(definition.contacts.size())
		var accepted: bool = game.perform_hit(enemy,definition.damage,gain,forward,definition.force if final_contact else 1.3,definition.vertical if final_contact else .2,.35,definition.ragdoll if final_contact else 0.0,definition.slam,false,"kick" if definition.clip in ["Kick","RobotSweep"] else "heavy")
		if accepted:
			hit_ids.append(enemy.body.get_instance_id())
			game.skill_vfx.contact(int(definition.get("slot",0)),enemy.body.global_position+Vector3.UP)
		if accepted and not definition.aoe: break
	
	game.arena.urban.hit_props(game.player.position,forward)

func play(clip: String, speed: float = 1, restart: bool = false) -> void:
	var key: StringName = game.rig_anim_names.get(clip.to_lower(),StringName())
	if key == StringName(): return
	stop_locomotion(); game.rig_anim.active = true; game.rig_anim.speed_scale = speed
	if last_clip != clip or game.rig_current_anim != key or restart:
		game.rig_anim.play(key,.10); last_clip = clip; game.rig_current_anim = key

func animate(dir: Vector3) -> void:
	if not active or game.physical_ragdoll.active: return
	if game.presentation.emote_time > 0:
		stop_locomotion(); game.presentation.animate_rig(); return
	if not attack.is_empty():
		var definition: Dictionary = attack
		var part := 0
		var clip: String = definition.clip
		var span: float = definition.duration
		if definition.has("sequence"):
			for i in range(definition.sequence.size()):
				if elapsed >= definition.sequence[i].start: part = i
			var item: Dictionary = definition.sequence[part]
			clip = item.clip; span = item.finish-item.start
		elif definition.contacts.size() > 1:
			part = 1 if elapsed >= definition.duration*.5 else 0; span = definition.duration*.5
		var length: float = game.rig_anim.get_animation(game.rig_anim_names[clip.to_lower()]).length
		var token: int = revision*4+part
		play(clip,length/span,last_attack_revision != token); last_attack_revision = token
	elif game.player_ragdoll: play("Death",1.2)
	elif counter_response > 0: play("Punch",game.rig_anim.get_animation(game.rig_anim_names.punch).length/.55)
	elif counter_recovery > 0: play("HitRecieve_2",.65)
	elif counter_time > 0: play("HitRecieve_2",1.25)
	elif game.block_recoil_time > 0: play("HitRecieve_2",1.5)
	elif game.stun > 0: play("HitRecieve_1",1.3)
	elif game.dash_time > 0 or sidestep_time > 0:
		# La inclinación, compresión y contrapeso del dash se calculan en los huesos.
		# No congelar Jump: eso anulaba la animación y podía dejar un frame rígido.
		current.locomotion.tick(0.0,get_physics_process_delta_time())
		last_clip = "procedural_dash"
	elif not game.player.is_on_floor(): play("Jump",1.5)
	elif game.block: play("RobotGuard")
	else:
		game.rig_anim.speed_scale = 1
		current.locomotion.tick(Vector2(game.player.velocity.x,game.player.velocity.z).length(),get_physics_process_delta_time())
		last_clip = "locomotion"

func stop_locomotion() -> void:
	if not current.is_empty() and current.has("locomotion"): current.locomotion.stop()
	if not current.is_empty() and current.has("procedural"): current.procedural.reset_motion()

func create_guard(player: AnimationPlayer, skeleton: Skeleton3D, names: Dictionary) -> void:
	var idle: Animation = player.get_animation(names.idle).duplicate()
	var holding: Animation = player.get_animation(names.get("walk_holding",names.idle))
	for track in range(idle.get_track_count()):
		var path := idle.track_get_path(track)
		if path.get_subname_count() == 0: continue
		var bone: String = path.get_subname(0)
		if bone == "Body" and idle.track_get_type(track) == Animation.TYPE_ROTATION_3D:
			for key in range(idle.track_get_key_count(track)):
				var q: Quaternion = idle.track_get_key_value(track,key)
				idle.track_set_key_value(track,key,Quaternion(Vector3.RIGHT,.14)*q)
		if not any_arm(bone): continue
		var source := holding.find_track(path,idle.track_get_type(track))
		if source < 0: continue
		var value: Variant
		if idle.track_get_type(track) == Animation.TYPE_ROTATION_3D: value = holding.rotation_track_interpolate(source,.2)
		else: continue
		while idle.track_get_key_count(track) > 0: idle.track_remove_key(track,0)
		idle.track_insert_key(track,0,value); idle.track_insert_key(track,idle.length,value)
	idle.loop_mode = Animation.LOOP_LINEAR
	player.get_animation_library("").add_animation("RobotGuard",idle); names["robotguard"] = &"RobotGuard"

func any_arm(bone: String) -> bool:
	return "Shoulder" in bone or "Arm" in bone or "Palm" in bone or "Finger" in bone

func configure_skill(slot: int) -> void:
	if index == 0: attack.damage = [13.0,14.0,18.0][slot-1]
	elif index == 1: attack.damage = [23.0,20.0,16.0][slot-1]
	if index == 0 and slot == 1: attack.range = 2.8
	if index == 0 and slot == 1:
		attack.clip = "RobotSweep"; attack.duration = 1.05; attack.contacts = [.53]
	elif index == 0 and slot == 2:
		attack.duration = 1.10; attack.contacts = [.67]
		attack.sequence = [{"clip":"Jump","start":0.0,"finish":.30},{"clip":"Kick","start":.30,"finish":1.10}]
	elif index == 1 and slot == 1:
		attack.duration = 1.20; attack.contacts = [.84]
		attack.sequence = [{"clip":"Pickup","start":0.0,"finish":.50},{"clip":"Punch","start":.50,"finish":1.20}]
	elif index == 1 and slot == 2:
		attack.clip = "SwordSlash"; attack.duration = 1.15; attack.contacts = [.60]
	elif index == 2 and slot == 2:
		attack.duration = .90; attack.contact_start = .30
		attack.sequence = [{"clip":"Run_Holding","start":0.0,"finish":.20},{"clip":"Punch","start":.20,"finish":.90}]
	game.attack_anim = attack.duration

func create_sweep(player: AnimationPlayer, names: Dictionary) -> void:
	var clip: Animation = player.get_animation(names.kick).duplicate()
	for track in range(clip.get_track_count()):
		var path := clip.track_get_path(track)
		if path.get_subname_count() == 0 or path.get_subname(0) != "Body" or clip.track_get_type(track) != Animation.TYPE_ROTATION_3D: continue
		for key in range(clip.track_get_key_count(track)):
			var time: float = clip.track_get_key_time(track,key)/clip.length
			var source: Quaternion = clip.track_get_key_value(track,key)
			clip.track_set_key_value(track,key,Quaternion(Vector3.UP,sin(time*TAU)*.70)*source)
	player.get_animation_library("").add_animation("RobotSweep",clip); names["robotsweep"] = &"RobotSweep"

func create_dash(player: AnimationPlayer,names: Dictionary) -> void:
	var clip: Animation = player.get_animation(names.jump).duplicate()
	clip.loop_mode = Animation.LOOP_NONE
	player.get_animation_library("").add_animation("RobotBoost",clip); names["robotboost"] = &"RobotBoost"

extends "res://scripts/main.gd"
# Adaptador independiente: reutiliza rig, locomoción y física de la versión individual.
# La autoridad de movimiento, vida, golpes y reaparición pertenece a Session.
var session: Node
var peer_id := 1
var metadata: Dictionary = {}
var skeleton: Skeleton3D
var tag: Label3D
var input_state := {"axis":Vector2.ZERO,"yaw":0.0,"flags":0,"seq":0,"time":0.0}
var action_queue: Array[String] = []
var last_action_sequence := 0
var last_character_change := -20.0
var last_damage_time := -20.0
var death_timer := 0.0
var attack_duration := 0.0
var attack_revision := 0
var visual_revision := -1
var spawn_protection := 0.5
var grounded := false
var states: Array[Dictionary] = []
var streamed_pose := false
var bind_holder := Transform3D.IDENTITY
var model_kind := 0
var robot_index := 0
var robot_color := 0
var last_snapshot := 0

var menu_blocked := false
var proxies: Dictionary = {}
var held_time := 0.0
var full_state: Dictionary = {}
var applying_counter := false

func _ready() -> void:
	tuning = tuning.duplicate(true)
	preferences.free(); preferences = session.arena.preferences
	arena.free(); arena = preload("res://network/terrain_adapter.gd").new(); add_child(arena)
	arena.punchline = session.arena.map
	arena.urban = preload("res://network/props_adapter.gd").new(); arena.add_child(arena.urban)
	moves.projection.free(); moves.free(); moves = preload("res://network/moves.gd").new()
	feedback.free(); feedback = preload("res://network/feedback.gd").new()
	interface.free(); interface = preload("res://network/interface.gd").new()
	robots.free(); robots = preload("res://network/robot.gd").new()
	peer_id = int(metadata.id); model_kind = int(metadata.character)
	robot_index = int(metadata.variant); robot_color = int(metadata.color)
	player = body(metadata.spawn); player.name = "Controller"; player.collision_layer = 2; player.collision_mask = 3
	player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var parts := mannequin(player,Color("ebe5d7"),true)
	for key in ["arm_left","arm_right","elbow_left","elbow_right","leg_left","leg_right"]: set(key,parts[key])
	model = parts.visual; setup_player_rig()
	camera = session.arena.camera
	add_child(route_trial); route_trial.setup(self)
	add_child(domain_inspector); domain_inspector.setup(self)
	create_dash_frame()
	add_child(moves); moves.setup(self)
	add_child(presentation); presentation.setup(self)
	add_child(feedback); feedback.setup(self)
	add_child(robots); robots.setup(self)
	add_child(robot_clearance); robot_clearance.setup(self)
	add_child(performance_capture); performance_capture.setup(self)
	add_child(fusion); fusion.setup(self)
	add_child(skill_vfx); skill_vfx.setup(self)
	if model_kind == 1:
		locomotion_tree.active = false; rig_anim.active = false; rig_holder.hide()
		robots.active = true; robots.index = robot_index; robots.color_index = robot_color
		robots.current = robots.make_model(robot_index); robots.cached[robot_index] = robots.current
		for key in ["rig_holder","rig_scene","rig_anim","rig_anim_names","physical_ragdoll"]: set(key,robots.current[key])
		robots.apply_color(); rig_enabled = true
		var capsule := CapsuleShape3D.new(); capsule.height = 2.0; capsule.radius = [.32,.44,.40,.46][robot_index]
		robots.naoya.collision.shape = capsule; robots.naoya.collision.position = Vector3.UP
	skeleton = visual_motion.find_skeleton(rig_scene); bind_holder = rig_holder.transform
	hud = Label.new(); notice = Label.new(); skills_label = Label.new(); health_bar = ProgressBar.new(); ult_bar = ProgressBar.new(); crosshair = Label.new()
	for node in [hud,notice,skills_label,health_bar,ult_bar,crosshair]: add_child(node); node.hide()
	add_child(interface); interface.setup(self)
	if model_kind == 1: interface.identity.set_robot_portrait(rig_scene,rig_holder.scale.x,robot_index)
	interface.set_process_input(peer_id == session.local_id()); interface.visible = peer_id == session.local_id()
	tag = Label3D.new(); player.add_child(tag); tag.position.y = 2.7; tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED; tag.font_size = 28; tag.pixel_size = .006
	model.rotation.y = float(metadata.yaw); yaw = model.rotation.y; camera_lock = true; sync_rig_transform()
	physical_ragdoll.set_process(session.is_host())
	if model_kind == 1: robots.naoya.physical_ragdoll.set_process(session.is_host())
	set_process_input(false); set_process_unhandled_input(false); process_priority = 150

func _unhandled_input(_event: InputEvent) -> void: pass
func _physics_process(_delta: float) -> void: pass
func _process(delta: float) -> void:
	if not session.active: return
	if not session.is_host():
		interpolate_state(delta); clock += delta
		presentation.tick(delta); feedback.tick(delta); moves.replica_tick(delta); skill_vfx.tick(delta)
		interface.tick(delta)
	tag.visible = not fusion.cinematic and not fusion.spider.invisible(); tag.position.y = .85 if fusion.spider.active() else (4.5 if fusion.fused else 2.7)
	tag.text = "%s · %d" % [metadata.nickname,int(hp)]
	tag.modulate = Color("86d7c2") if peer_id == session.local_id() else Color("e7d2a3")

func grounded_for_actions() -> bool:
	return player.is_on_floor() if session.is_host() else grounded

func input_pressed(action: String) -> bool:
	if clock-float(input_state.time) > .35: return false
	return int(input_state.flags) & int({"block":1,"walk":2,"attack":4,"ability1":8}.get(action,0)) != 0
func first_person_enabled() -> bool:
	if fusion.spider!=null and fusion.spider.active():return true
	return clock-float(input_state.time) <= .35 and int(input_state.flags) & 16 != 0

func movement() -> Vector3:
	return Vector3(input_state.axis.x,0,input_state.axis.y).rotated(Vector3.UP,float(input_state.yaw)) if clock-float(input_state.time) <= .35 else Vector3.ZERO
func actionable() -> bool: return hp > 0 and not fusion.cinematic and (stun <= 0 if fusion.fused else can_start_action())
func queue_action(action: String) -> void:
	if action_queue.size() < 16: action_queue.append(action)
func simulate(delta: float) -> void:
	refresh_targets()
	spawn_protection = maxf(0,spawn_protection-delta); held_time = maxf(0,held_time-delta)
	yaw = float(input_state.yaw)
	for action in action_queue:
		if hp <= 0: break
		if action=="interact":fusion.spider.interact();continue
		if fusion.spider.active():
			if action in ["ability1","ability2"]:fusion.spider.ability(int(action.trim_prefix("ability")))
			continue
		if action == "attack": attack_buffer = .14
		elif action == "cannon_release": fusion.combat.release_cannon()
		elif action == "jump": jump_buffer = .12
		elif action == "dash": start_dash()
		elif action.begins_with("ability"): buffered_ability = int(action.trim_prefix("ability")); ability_buffer = .16
		elif action == "transform": moves.transform_input()
		elif action == "kogane": presentation.toggle_kogane()
		elif action == "lock": camera_lock = not camera_lock
		elif action.begins_with("emote:"): presentation.start_emote(int(action.trim_prefix("emote:")))
	action_queue.clear()
	if hp <= 0:
		clock += delta; death_timer -= delta
		if fusion.fused: fusion.tick_death(delta)
		if physical_ragdoll.active: physical_ragdoll.follow_actor()
		if death_timer <= 0 and (not fusion.fused or fusion.can_respawn()): session.respawn(peer_id)
		return
	# A barrage holds its actual target; releasing/cancelling removes the hold.
	for other in session.actors.values():
		if other == self: continue
		var entry: Dictionary = other.proxies.get(peer_id,{})
		if float(entry.get("sequence_hold",0)) > 0: held_time = maxf(held_time,.05)
	if held_time > 0: stun = maxf(stun,held_time); player.velocity = Vector3.ZERO
	super._physics_process(delta)
	grounded = player.is_on_floor()
	for other in session.actors.values():
		if other != self: other.refresh_targets()
func update_enemy(_enemy: Dictionary,_delta: float) -> void: pass
func refresh_targets() -> void:
	enemies.clear()
	for other in session.actors.values():
		if other == self or not is_instance_valid(other) or other.is_queued_for_deletion(): continue
		if not proxies.has(other.peer_id): proxies[other.peer_id] = {"peer":other.peer_id,"sequence_hold":0.0,"cd":0.0,"attack_timer":0.0,"flash":0.0,"respawn":0.0,"spawn":other.player.position,"projection_frame":null}
		var e: Dictionary = proxies[other.peer_id]
		e.merge({"body":other.player,"mega":other.fusion.fused and not other.fusion.spider.active(),"spider":other.fusion.spider.active(),"surface_up":other.fusion.spider.normal,"mega_yaw":other.model.rotation.y,"visual":other.model,"rig_holder":other.rig_holder,"rig_scene":other.rig_scene,"rig_anim":other.rig_anim,"rig_enabled":other.rig_enabled,"physics":other.physical_ragdoll,"hp":other.hp,"stun":other.stun,"ragdoll":other.player_ragdoll,"ragdoll_time":other.player_ragdoll_time,"wakeup_protection":maxf(other.spawn_protection,other.player_wakeup_protection),"projection_freeze":maxf(other.moves.player_freeze,other.held_time),"kind":0,"combo":other.combo,"attack_phase":"attack" if other.attack_anim > 0 or not other.skill_active.is_empty() else "idle","attack_anim":other.attack_anim,"label":other.tag},true)
		enemies.append(e)
func interrupt_enemy_attack(enemy: Dictionary) -> void:
	if not session.actors.has(int(enemy.peer)): return
	var target: Node3D = session.actors[int(enemy.peer)]
	if target.fusion.protected_m1(fusion.fused): return
	target.cancel_skill(); target.attack_anim = 0; target.attack_hit_done = true; target.attack_buffer = 0; target.ability_buffer = 0
	super.interrupt_enemy_attack(enemy)
func enemy_blocks_hit(enemy: Dictionary,flat_offset: Vector3) -> bool:
	var target: Node3D = session.actors.get(int(enemy.peer))
	return target != null and target.block and target.facing_forward().dot(-flat_offset.normalized()) > .25
func perform_hit(enemy: Dictionary,damage: float,charge_gain: float,forward: Vector3,horizontal_force: float,vertical_force: float,stun_time: float,ragdoll_time: float = 0.0,slam: bool = false,unblockable: bool = false,audio_id: String = "") -> bool:
	if not session.is_host() or not session.actors.has(int(enemy.peer)): return false
	var target: Node3D = session.actors[int(enemy.peer)]
	var ray := PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP,preload("res://scripts/combat_geometry.gd").point(enemy,player.global_position+Vector3.UP),1)
	ray.exclude = [player.get_rid(),target.player.get_rid()]
	if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return false
	var accepted: bool = target.receive_hit(self,{"damage":damage,"force":horizontal_force,"vertical":vertical_force,"stun":stun_time,"ragdoll":ragdoll_time,"kind":"downslam" if slam else ("uppercut" if vertical_force >= 6 else "horizontal"),"direction":forward,"unblockable":unblockable,"audio":audio_id if not audio_id.is_empty() else ("heavy" if damage >= 12 else "hit")})
	if accepted: add_charge(charge_gain)
	refresh_targets(); return accepted
func receive_hit(attacker: Node3D,profile: Dictionary) -> bool:
	if fusion.cinematic or hp <= 0 or player_ragdoll or spawn_protection > 0 or player_wakeup_protection > 0: return false
	refresh_targets()
	if moves.player_freeze <= 0 and not applying_counter and not fusion.spider.active():
		applying_counter = true
		var countered: bool = robots.counter(proxies[attacker.peer_id]) if robots.active else moves.counter(proxies[attacker.peer_id])
		applying_counter = false
		if countered: return false
	var crystallized: bool = moves.player_freeze > 0
	var incoming: Vector3 = attacker.player.position-player.position; incoming.y = 0
	if not crystallized and block and not profile.unblockable and facing_forward().dot(incoming.normalized()) > .25:
		if attacker.combo == 4: stun = BLOCKSTUN_DURATION; block_recoil_time = BLOCKSTUN_DURATION
		session.effect("block",attacker.peer_id,peer_id,0); return false
	if crystallized: moves.break_player_frame("hit")
	hp = maxf(0,hp-float(profile.damage)); last_damage_time = clock
	if fusion.spider.active():fusion.spider.cloak_time=0
	if fusion.fused and not fusion.spider.active(): fusion.damage.record(float(profile.damage),profile.get("point",player.global_position+Vector3.UP*2.15+incoming.normalized()*.8))
	var armor: bool = fusion.protected_m1(attacker.fusion.fused)
	if not armor:
		stun = maxf(stun,float(profile.stun)); attack_anim = 0; attack_hit_done = true; block = false
		presentation.cancel_emote(); cancel_skill(); fusion.combat.interrupted()
	attack_buffer = 0; ability_buffer = 0; jump_buffer = 0
	if interface.emote_wheel.visible: interface.close_emotes()
	presentation.comment("damage")
	var direction: Vector3 = profile.get("direction",attacker.facing_forward())
	if not armor: player.velocity = direction*float(profile.force)+Vector3.UP*float(profile.vertical)
	session.effect(profile.audio,attacker.peer_id,peer_id,float(profile.damage)); add_charge(4)
	if hp <= 0 and ult_ready(): rebirth_phase1(); return true
	if hp <= 0:on_player_death()
	var duration: float = maxf(float(profile.ragdoll),3.0 if hp <= 0 else 0.0)
	if duration > 0 and not fusion.fused:
		player_ragdoll = true; player_ragdoll_time = duration
		player_ragdoll_impact = {"kind":profile.kind,"direction":direction,"side":-1.0 if attacker.combo%2 == 0 else 1.0}
		if form == "BASE": physical_ragdoll.start(player.velocity,player_ragdoll_impact)
	return true
func on_player_death() -> void:
	if not session.is_host():return
	if fusion.spider.active():fusion.spider.destroy();return
	death_timer=maxf(death_timer,3.85 if fusion.fused else 3.0)
	if fusion.fused:fusion.break_apart()
func respawn_player() -> void:
	if session.is_host(): session.respawn(peer_id)
func set_paused(value: bool) -> void:
	menu_blocked = value; interface.pause_changed(value)
	if peer_id == session.local_id():
		Input.mouse_mode = hud_mouse_mode()
		if value: session.local_input(Vector2.ZERO,yaw,0)
func hud_mouse_mode() -> int:
	return Input.MOUSE_MODE_VISIBLE if menu_blocked or hud_cursor or session.arena.menu_open or interface.emote_wheel.visible else Input.MOUSE_MODE_CAPTURED
func move_speed() -> float: return 6.0*robots.SPEEDS[robot_index] if model_kind == 1 else SPEED
func make_snapshot() -> Dictionary:
	var pose: bool = physical_ragdoll.active or physical_ragdoll.recovering > 0
	var result := {"id":peer_id,"generation":metadata.generation,"position":player.position,"velocity":player.velocity,"yaw":model.rotation.y,"hp":hp,"combo":combo,"variant":attack_variant,"attack":attack_anim,"duration":attack_duration,"revision":attack_revision,"punch":punch_visual,"stun":stun,"block":block,"recoil":block_recoil_time,"dash":dash_time,"dash_cd":dash_cd,"dash_dir":dash_dir,"grounded":grounded,"land":landing_anim,"fall":descending_time,"ragdoll":player_ragdoll,"pose":pose,"protection":spawn_protection,"ack":input_state.seq}
	if physical_ragdoll.active: physical_ragdoll.transfer_physical_pose()
	var positions := PackedVector3Array(); var rotations: Array[Quaternion] = []
	for index in range(skeleton.get_bone_count()): positions.append(skeleton.get_bone_pose_position(index)); rotations.append(skeleton.get_bone_pose_rotation(index))
	if not robots.active and is_instance_valid(human_motion):
		for index in human_motion.pose_cache:
			positions[index] = human_motion.pose_cache[index].position; rotations[index] = human_motion.pose_cache[index].rotation
	if robots.active and robots.current.has("grounding"):
		for index in robots.current.grounding.pose_cache:
			positions[index]=robots.current.grounding.pose_cache[index].position
			rotations[index]=robots.current.grounding.pose_cache[index].rotation
		if robots.current.has("procedural"):
			for index in robots.current.procedural.pose_cache:
				positions[index]=robots.current.procedural.pose_cache[index].position
				rotations[index]=robots.current.procedural.pose_cache[index].rotation
	result["holder"] = rig_holder.global_transform; result["positions"] = positions; result["rotations"] = rotations
	var full := {}
	for key in ["max_hp","charge","form","ult_time","ult_duration","ult_msg","ult_msg_time","domain_used","skill_active","skill_phase","skill_timer","skill_dir","skill3_cd","skill4_cd","player_wakeup_protection","wakeup_anim","rush_hits","camera_lock"]: full[key] = get(key)
	full["fusion"] = fusion.state()
	full["clearance"] = robot_clearance.snapshot()
	full["moves"] = {"key":moves.key,"stage":moves.stage,"remaining":moves.remaining,"direction":moves.direction,"cooldowns":moves.cooldowns.duplicate(),"phase_charge":moves.phase_charge,"freeze":moves.player_freeze,"domain_time":moves.domain_time,"domain_center":moves.domain_center,"domain_saved":moves.domain_saved_player,"strike_revision":moves.projection.strike_revision,"strike_index":moves.projection.strike_index,"close_variant":moves.projection.close_variant}
	full["robot"] = {"cooldowns":robots.cooldowns.duplicate(),"attack":robots.attack.duplicate(true),"elapsed":robots.elapsed,"guard":robots.guard_time,"counter":robots.counter_time,"response":robots.counter_response,"recovery":robots.counter_recovery,"revision":robots.revision,"sidestep":robots.sidestep_time,"sidestep_dir":robots.sidestep_direction}
	full["presentation"] = {"emote_index":presentation.emote_index,"emote_time":presentation.emote_time,"emote_elapsed":presentation.emote_elapsed,"dance_name":presentation.dance_name,"kogane_invoked":presentation.kogane_invoked,"kogane_state":presentation.kogane_state,"kogane_transition":presentation.kogane_transition,"transition_time":presentation.transition_time}
	result["full"] = full
	return result

func accept_snapshot(sequence: int, state: Dictionary) -> void:
	if sequence <= last_snapshot or int(state.generation) != int(metadata.generation): return
	last_snapshot = sequence; state["received"] = Time.get_ticks_msec()/1000.0
	states.append(state)
	while states.size() > 6: states.pop_front()
	hp = float(state.hp)

func interpolate_state(delta: float) -> void:
	if states.is_empty(): return
	var now := Time.get_ticks_msec()/1000.0
	var local: bool = peer_id == session.local_id()
	var target_time := now-(.025 if local else .08)
	var before: Dictionary = states[0]; var after: Dictionary = states[-1]
	for state in states:
		if float(state.received) <= target_time: before = state
		if float(state.received) >= target_time: after = state; break
	var span: float = float(after.received)-float(before.received)
	var weight := clampf((target_time-float(before.received))/maxf(.001,span),0,1)
	var wanted: Vector3 = before.position.lerp(after.position,weight)
	if target_time > float(after.received): wanted += after.velocity*minf(.05,target_time-float(after.received))
	if player.position.distance_to(wanted) > 3: player.position = wanted
	else: player.position = player.position.lerp(wanted,1-exp(-delta*(25 if local else 18)))
	player.velocity = before.velocity.lerp(after.velocity,weight)
	var latest: Dictionary = states[-1]
	model.rotation.y = lerp_angle(float(before.yaw),float(after.yaw),weight)
	for key in ["combo","attack_variant","attack_anim","attack_duration","attack_revision","punch_visual","stun","block","block_recoil_time","dash_time","dash_cd","dash_dir","grounded","landing_anim","descending_time","player_ragdoll","spawn_protection"]:
		var mapping := {"attack_variant":"variant","attack_anim":"attack","attack_duration":"duration","attack_revision":"revision","punch_visual":"punch","block_recoil_time":"recoil","dash_time":"dash","grounded":"grounded","landing_anim":"land","descending_time":"fall","player_ragdoll":"ragdoll","spawn_protection":"protection"}
		set(key,latest.get(mapping.get(key,key),get(key)))
	full_state = latest
	fusion.replica_delta = delta
	apply_full_state(latest.full)
	apply_streamed_pose(latest,before,after,weight)

func apply_streamed_pose(state: Dictionary,before: Dictionary,after: Dictionary,weight: float) -> void:
	# All animations use the actual host bone poses, including ordinary locomotion.
	streamed_pose = bool(state.pose); rig_anim.active = false; locomotion_tree.active = false; robots.stop_locomotion()
	rig_holder.set_as_top_level(true)
	rig_holder.global_transform = before.holder.interpolate_with(after.holder,weight)
	for index in range(skeleton.get_bone_count()):
		skeleton.set_bone_pose_position(index,before.positions[index].lerp(after.positions[index],weight))
		skeleton.set_bone_pose_rotation(index,before.rotations[index].slerp(after.rotations[index],weight))
	if model_kind == 1: physical_ragdoll.attach_visual_feet(true)

func apply_full_state(data: Dictionary) -> void:
	var old_form := form
	for key in data:
		if key not in ["moves","robot","presentation","fusion","clearance"]: set(key,data[key])
	if old_form != form:
		presentation.begin_transition(old_form)
		presentation.show_form(form)
	var values: Dictionary = data.moves
	for key in ["key","stage","remaining","direction","cooldowns","phase_charge"]: moves.set(key,values[key])
	for key in ["strike_revision","strike_index","close_variant"]: moves.projection.set(key,values[key])
	var fusion_data: Dictionary = data.get("fusion",{}).duplicate()
	if bool(fusion_data.get("cinematic",false)) and not states.is_empty():
		var prediction: float = clampf(Time.get_ticks_msec()/1000.0-float(states[-1].received),0,.1)
		fusion_data.elapsed = minf(11.5,float(fusion_data.elapsed)+prediction)
	fusion.apply_state(fusion_data)
	if data.has("clearance") and not fusion.spider.active():
		robot_clearance.apply_snapshot(data.clearance)
		if fusion.fused: fusion.sync_hurtbox()
	if hp <= 0 and fusion.fused: fusion.break_apart()
	var frozen: float = float(values.freeze)
	if frozen > 0 and not is_instance_valid(moves.player_frame):
		var state_key: String = moves.key; var state_stage: String = moves.stage; var active_skill: String = skill_active
		moves.freeze_player(frozen)
		moves.key = state_key; moves.stage = state_stage; skill_active = active_skill
	elif frozen <= 0 and is_instance_valid(moves.player_frame): moves.break_player_frame("timeout")
	moves.player_freeze = frozen
	if frozen > 0 and fusion.fused and fusion.visual() != null: fusion.visual().hide()
	if frozen > 0 and is_instance_valid(moves.player_frame): moves.player_frame.global_position = player.global_position+moves.player_frame_offset; moves.player_frame.enforce()
	if float(values.domain_time) > 0 and not is_instance_valid(moves.domain_arena):
		var peers := enemies.duplicate(); var current_position := player.position; var used := domain_used
		enemies.clear(); domain_used = false; moves.domain_center = values.domain_center
		moves.begin_domain(); enemies.assign(peers); player.position = current_position; domain_used = used
		moves.domain_saved_player = values.domain_saved
	elif float(values.domain_time) <= 0 and is_instance_valid(moves.domain_arena):
		var current_position := player.position; moves.end_domain(); player.position = current_position
	moves.domain_time = float(values.domain_time)
	robots.cooldowns = data.robot.cooldowns; robots.attack = data.robot.attack; robots.elapsed = data.robot.elapsed
	robots.sidestep_time = float(data.robot.get("sidestep",0)); robots.sidestep_direction = data.robot.get("sidestep_dir",Vector3.ZERO); robots.guard_time = data.robot.guard; robots.counter_time = data.robot.counter; robots.counter_response = data.robot.response; robots.counter_recovery = data.robot.get("recovery",0); robots.revision = data.robot.revision
	var display: Dictionary = data.presentation
	if bool(display.kogane_invoked) != presentation.kogane_invoked: presentation.toggle_kogane()
	var entering_emote: bool = float(display.emote_time) > 0 and presentation.emote_time <= 0
	if entering_emote and peer_id == session.local_id() and presentation.emote_entries()[int(display.emote_index)].music: feedback.music.play()
	if float(display.emote_time) <= 0: feedback.music.stop()
	for key in display: presentation.set(key,display[key])
	pass # Estado de fusión ya aplicado antes de capturar el fotograma.
	refresh_targets()

func online_session() -> Node:
	return session

extends Node3D
# El eco reproduce posiciones y huesos registrados del jugador real; no hace daño.
var game: Node3D
var active := false
var elapsed := 0.0
var checkpoint := 0
var best_time := INF
var samples: Array[Dictionary] = []
var best_samples: Array[Dictionary] = []
var sample_timer := 0.0
var gates: Array[Node3D] = []
var ghost: Node3D
var ghost_skeleton: Skeleton3D
var ghost_index := 0
var result_text := ""
var result_life := 0.0
const ROUTE := [Vector3(-17,.1,12),Vector3(-17,5.1,25),Vector3(-9,5.8,26),Vector3(0,7.8,26),Vector3(6,.7,14),Vector3(19,-5.9,15)]
var save := "user://route_echo_v096.dat"
var route: Array[Vector3] = []
func setup(host: Node3D) -> void:
	game = host
	route.assign(ROUTE)
	if game.arena.punchline != null:
		save = "user://route_echo_district500_923.dat"
		route.assign([Vector3(-100,.15,-80),Vector3(-100,.15,-50),Vector3(-100,.15,-20),Vector3(-60,.15,-20),Vector3(-60,.15,-50),Vector3(-60,.15,-80)])
		for i in range(route.size()): route[i] *= game.arena.punchline.MAP_SCALE
	if FileAccess.file_exists(save):
		var file := FileAccess.open(save,FileAccess.READ)
		if file != null:
			var saved: Variant = file.get_var(false)
			if saved is Dictionary and saved.get("samples") is Array and saved.samples.size() > 1 and saved.samples.size() <= 1442:
				var valid := true
				for sample in saved.samples:
					valid = valid and sample is Dictionary and sample.get("position") is Vector3 and sample.get("bones") is Array and sample.bones.size() in [17,43,47,53] and sample.get("pelvis") is Vector3 and sample.has("time") and sample.has("rotation")
				if valid:
					best_time = float(saved.get("time",INF)); best_samples.assign(saved.samples)

func clear_record() -> void:
	cancel(); best_time = INF; best_samples.clear()
	DirAccess.remove_absolute(save)
func start() -> void:
	cancel(); game.reset_lab(); game.set_paused(false)
	game.player.position = route[0]+Vector3(0,1,3); game.player.velocity = Vector3.ZERO
	game.player.reset_physics_interpolation(); game.camera_initialized = false
	active = true; elapsed = 0; checkpoint = 0; sample_timer = 0; samples.clear(); result_text = ""
	for i in range(route.size()):
		var gate: Node3D = game.moves.frame(route[i],Color("d1ba81")); gate.scale = Vector3.ONE*.8
		var label := Label3D.new(); gate.add_child(label); label.text = "%02d / 06" % (i+1)
		label.position.y = 1.8; label.font_size = 36; label.pixel_size = .007; label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		gate.visible = i == 0; gates.append(gate)
	if not best_samples.is_empty(): create_ghost()
	game.presentation.comment("route_start")

func cancel() -> void:
	active = false
	for gate in gates:
		if is_instance_valid(gate): gate.queue_free()
	gates.clear()
	if is_instance_valid(ghost): ghost.queue_free()
	ghost = null; ghost_skeleton = null

func capture_sample() -> void:
	var sk: Skeleton3D = game.robots.current.skeleton if game.robots.active else game.visual_motion.skeleton
	var rotations: Array[Quaternion] = []
	for i in range(sk.get_bone_count()): rotations.append(sk.get_bone_pose_rotation(i))
	samples.append({"time":elapsed,"position":game.player.global_position,"rotation":game.rig_holder.rotation.y,"bones":rotations,"pelvis":sk.get_bone_pose_position(sk.find_bone(game.physical_ragdoll.pelvis_name())),"character":game.robots.NAMES[game.robots.index] if game.robots.active else "Naoya","scale":game.rig_holder.scale.x,"root_bone":game.physical_ragdoll.pelvis_name()})

func create_ghost() -> void:
	ghost = Node3D.new(); add_child(ghost); ghost.scale = Vector3.ONE*float(best_samples[0].get("scale",game.RIG_SCALE_ADJUST))
	var character: String = best_samples[0].get("character","Naoya")
	var path: String = "res://assets/characters/robots/"+character+"/model.gltf" if character in game.robots.NAMES else game.PLAYER_RIG_SCENE_PATH
	var rig: Node3D = load(path).instantiate(); ghost.add_child(rig)
	var animator: AnimationPlayer = game.find_animation_player(rig)
	if animator != null: animator.active = false
	ghost_skeleton = game.visual_motion.find_skeleton(rig)
	var meshes: Array[MeshInstance3D] = []; game.presentation.collect_meshes(rig,meshes)
	var material: StandardMaterial3D = game.presentation.transparent_material(Color("95c9e5"),.27)
	for mesh in meshes: mesh.material_override = material; mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ghost_index = 0

func playback() -> void:
	if not is_instance_valid(ghost) or best_samples.size() < 2: return
	while ghost_index < best_samples.size()-2 and best_samples[ghost_index+1].time < elapsed: ghost_index += 1
	var a: Dictionary = best_samples[ghost_index]; var b: Dictionary = best_samples[ghost_index+1]
	var weight := clampf((elapsed-float(a.time))/maxf(.001,float(b.time)-float(a.time)),0,1)
	ghost.global_position = a.position.lerp(b.position,weight)
	ghost.rotation.y = lerp_angle(a.rotation,b.rotation,weight)
	for i in range(mini(ghost_skeleton.get_bone_count(),mini(a.bones.size(),b.bones.size()))): ghost_skeleton.set_bone_pose_rotation(i,a.bones[i].slerp(b.bones[i],weight))
	ghost_skeleton.set_bone_pose_position(ghost_skeleton.find_bone(a.get("root_bone","Torso" if a.get("character","Naoya") in game.robots.NAMES else "B_Pelvis")),a.pelvis.lerp(b.pelvis,weight))
	ghost.visible = elapsed <= best_time

func tick(delta: float) -> void:
	result_life = maxf(0,result_life-delta)
	if result_life <= 0 and not active: result_text = ""
	if not active: return
	if game.form != "BASE" or elapsed >= 120:
		cancel(); result_text = "ECO / recorrido terminado · vuelve a intentarlo"; result_life = 6; return
	elapsed += delta; sample_timer -= delta
	if sample_timer <= 0: capture_sample(); sample_timer = 1.0/12
	playback()
	var offset: Vector3 = game.player.global_position-route[checkpoint]
	if Vector2(offset.x,offset.z).length() < 1.25 and absf(offset.y) < 1.4 and not game.player_ragdoll:
		gates[checkpoint].hide(); checkpoint += 1
		game.feedback.sound("checkpoint",game.player.global_position,-12)
		if checkpoint == route.size():
			capture_sample()
			var record := elapsed < best_time
			if record:
				best_time = elapsed; best_samples = samples.duplicate(true); game.presentation.comment("route_best")
				var file := FileAccess.open(save,FileAccess.WRITE)
				if file != null: file.store_var({"time":best_time,"samples":best_samples})
			result_text = "ECO / %.2f s%s · mejor %.2f s" % [elapsed," · NUEVO RÉCORD" if record else "",best_time]
			result_life = 10; cancel()
		else: gates[checkpoint].show()

func hud_text() -> String:
	if not active: return result_text
	return "ECO / %02d de 06 · %.2f s%s" % [checkpoint+1,elapsed," · récord %.2f s" % best_time if best_time < INF else ""]

extends SceneTree
var game: Node3D
var checks := 0
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func verify(ok: bool, description: String) -> void:
	checks += 1
	if not ok:failures += 1
	print(("PASS " if ok else "FAIL ")+description)
func frames(n: int) -> void:
	for i in range(n):await physics_frame
func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	game._unhandled_input(event)
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for enemy in game.enemies:enemy.body.position = Vector3(30,0,30)
	await frames(20)
	verify(not game.presentation.companion.visible,"Kogane comienza oculto")
	key(KEY_K)
	verify(game.presentation.companion.visible,"K invoca Kogane")
	key(KEY_K)
	await frames(40)
	verify(not game.presentation.companion.visible,"K retira Kogane")
	verify(game.rig_anim.has_animation("dance/RunningMan"),"Running Man instalado sobre rig de combate")
	var dance: Animation = game.rig_anim.get_animation("dance/RunningMan")
	verify(dance.get_track_count() == 54 and dance.loop_mode == Animation.LOOP_LINEAR,"baile tiene 53 huesos y cadera, loop cerrado")
	var path_ok := true
	for i in range(dance.get_track_count()):
		var path := dance.track_get_path(i)
		var sk: Skeleton3D = game.rig_anim.get_node(game.rig_anim.root_node).get_node(NodePath(path.get_concatenated_names()))
		path_ok = path_ok and sk.find_bone(path.get_subname(0)) >= 0
	verify(path_ok,"todas las pistas apuntan a huesos existentes")
	key(KEY_B)
	game.interface.choose_emote(0)
	verify(game.feedback.music.playing,"B inicia musica")
	await frames(150)
	verify(game.presentation.emote_time > 0 and game.feedback.music.playing,"baile y musica persisten mas de 2 segundos")
	key(KEY_ESCAPE)
	verify(game.feedback.music.stream_paused and not game.rig_anim.active,"pausa detiene musica y animacion")
	key(KEY_ESCAPE)
	verify(not game.feedback.music.stream_paused and game.rig_anim.active,"reanudar restaura musica y animacion")
	key(KEY_B)
	verify(not game.feedback.music.playing and game.presentation.emote_time == 0,"B corta baile y musica juntos")
	key(KEY_B)
	var event := InputEventKey.new()
	game.interface.choose_emote(0)
	event.keycode = KEY_W
	event.physical_keycode = KEY_W
	event.pressed = true
	Input.parse_input_event(event)
	await frames(3)
	verify(game.presentation.emote_time == 0 and not game.feedback.music.playing,"W cancela baile y musica")
	event.pressed = false
	Input.parse_input_event(event)
	await frames(3)
	for index in range(2):
		var skeleton: Skeleton3D = game.presentation.form_skeletons[index]
		verify(skeleton.get_bone_count() == 7,"fase %d tiene 7 huesos" % (index+1))
		var weights_ok := true
		for node in skeleton.get_children():
			if node is MeshInstance3D:
				for surface in range(node.mesh.get_surface_count()):
					var a: Array = node.mesh.surface_get_arrays(surface)
					var weights: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
					for v in range(0,weights.size(),4):
						weights_ok = weights_ok and absf(weights[v]+weights[v+1]+weights[v+2]+weights[v+3]-1.0) < 0.001
		verify(weights_ok,"fase %d tiene pesos normalizados" % (index+1))
	game.start_form("FORM1")
	await frames(130)
	verify(game.presentation.form_models[0].visible and not game.presentation.form_models[1].visible,"fase1 usa modelo worm enviado")
	var q: Quaternion = game.presentation.form_skeletons[0].get_bone_pose_rotation(3)
	await frames(10)
	verify(not q.is_equal_approx(game.presentation.form_skeletons[0].get_bone_pose_rotation(3)),"cuerpo se deforma mediante huesos")
	game.moves.phase_charge = 100
	key(KEY_G)
	verify(is_instance_valid(game.presentation.shell) and game.presentation.shell.visible,"evolucion tiene envoltura visible")
	await frames(56)
	verify((not is_instance_valid(game.presentation.shell) or not game.presentation.shell.visible) and game.presentation.form_models[1].visible,"envoltura rompe al desplegar fase2")
	await frames(60)
	verify(game.feedback.effects.is_empty(),"fragmentos y humo se limpian")
	verify(game.feedback.played > 0,"eventos de sonido ejecutados")
	game.end_form()
	key(KEY_B)
	game.respawn_player()
	verify(not game.feedback.music.playing and not game.presentation.busy(),"respawn detiene baile y musica")
	print("RESULTADO %d/%d" % [checks-failures,checks])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)

extends RefCounted
var markers: Array[Dictionary] = []
func mark(demo: SceneTree, text: String) -> void:
	demo.say(text)
	markers.append({"seconds":Engine.get_frames_drawn()/float(demo.capture_fps),"text":text})
func prepare(demo: SceneTree) -> void:
	demo.prepare()
	for enemy in demo.game.enemies: demo.game.set_dummy_mode(enemy,0)
	demo.game.feedback.audio_events.clear()
	demo.game.yaw = 0; demo.game.pitch = -.24; demo.game.zoom = 6.4
func combo(demo: SceneTree, variant: String) -> void:
	prepare(demo); await demo.frames(15)
	var game: Node3D = demo.game; var enemy: Dictionary = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,0,-1.8); await demo.frames(6)
	for i in range(3): game.punch(); await demo.frames(25)
	if variant == "uppercut":
		# El salto real entra por _input; el uppercut requiere estar ascendiendo.
		demo.key(KEY_SPACE); await demo.frames(6)
	elif variant == "downslam":
		# Preparación de laboratorio explícita: caída corta antes del cuarto M1.
		game.player.position.y = 1.4; game.player.velocity.y = -1; await demo.frames(1)
	game.punch(); await demo.frames(16); Input.action_release("jump")
	demo.verify(enemy.physics.active and enemy.physics.last_impact.kind == variant,"cuarto M1 y ragdoll real: "+variant)
	await demo.frames(70); demo.shot("v098_ragdoll_"+variant)
	await demo.frames(50)
	demo.verify(not enemy.physics.active and enemy.physics.skeleton.get_bone_count() == 53,"recuperación con rig unido: "+variant)
func play(demo: SceneTree) -> void:
	var game: Node3D = demo.game
	prepare(demo); await demo.frames(15)
	mark(demo,"0.9.8 / Distrito ampliado. Juego real; entradas y preparativos automatizados.")
	var overview := Camera3D.new(); game.add_child(overview); overview.current = true
	overview.position = Vector3(45,35,70); overview.look_at(Vector3(0,0,-4)); overview.fov = 75
	await demo.frames(110); demo.shot("v098_distrito_general")
	overview.queue_free(); game.camera.current = true
	mark(demo,"Bulevar / caminar, correr y dash sobre la calle real")
	game.arena.visit_zone("boulevard"); game.yaw = 0; await demo.frames(15)
	Input.action_press("forward"); Input.action_press("walk"); await demo.frames(80)
	Input.action_release("walk"); await demo.frames(65); demo.key(KEY_Q); await demo.frames(40); Input.action_release("forward")
	demo.verify(game.player.position.z < -8,"recorrido y dash físicos en bulevar")
	demo.shot("v098_bulevar")
	mark(demo,"Habilidad 1 / audio de la primera habilidad que adjuntaste; tono original")
	prepare(demo); await demo.frames(15); game.enemies[0].body.position = Vector3(0,.1,-5)
	demo.key(KEY_1); await demo.frames(20); demo.shot("v098_habilidad1")
	demo.verify(game.feedback.audio_events.any(func(e: Dictionary) -> bool: return e.id == "rush" and e.pitch == 1),"referencia reproducida por habilidad 1")
	await demo.frames(125)
	demo.verify(game.skill_active == "" and game.moves.gate_nodes.is_empty(),"habilidad termina y limpia fotogramas")
	mark(demo,"M1 / impacto horizontal, impulso en pelvis y recuperación")
	await combo(demo,"horizontal")
	mark(demo,"Uppercut / cuarto M1 durante el ascenso del salto; impulso en torso")
	await combo(demo,"uppercut")
	mark(demo,"Downslam / caída corta preparada; cuarto M1 real")
	await combo(demo,"downslam")
	mark(demo,"Bloqueo / NPC ataca y el jugador mantiene guardia")
	prepare(demo); await demo.frames(40)
	game.enemies[0].body.position = game.player.position+Vector3(0,0,-1.8); game.set_dummy_mode(game.enemies[0],2)
	Input.action_press("block"); await demo.frames(130); Input.action_release("block")
	demo.verify(game.hp == 100 and game.feedback.audio_events.any(func(e: Dictionary) -> bool: return e.id == "block"),"bloqueo real con sonido de referencia")
	mark(demo,"Cristalización / cinco segundos; revisión visual de ambas caras")
	prepare(demo); await demo.frames(15); game.moves.freeze_player(5); game.yaw = PI
	await demo.frames(110); demo.shot("v098_vidrio_frontal"); game.yaw = 0
	await demo.frames(110); demo.shot("v098_vidrio_trasero")
	demo.verify(game.moves.player_freeze > 0 and not game.rig_holder.visible,"malla 3D oculta mientras dura el vidrio")
	await demo.frames(95)
	demo.verify(game.moves.player_freeze <= 0 and game.rig_holder.visible,"restauración automática tras cinco segundos")
	mark(demo,"Azoteas / plataformas con colisión y pasarela conectada")
	game.arena.visit_zone("district_roof"); game.yaw = PI*.4; await demo.frames(90); demo.shot("v098_azotea")
	demo.verify(game.player.is_on_floor() and game.player.position.y > 6,"azotea transitada por el controlador real")
	mark(demo,"Noche / skybox Kenney y ajustes de mezcla de combate")
	game.arena.urban.set_lighting(true); await demo.frames(90); demo.shot("v098_noche")
	game.interface.open_menu("settings"); await demo.frames(100); demo.shot("v098_ajustes")
	game.set_paused(false)
	FileAccess.open(demo.output.path_join("markers_v098.json"),FileAccess.WRITE).store_string(JSON.stringify(markers,"  "))
	print("DEMO RESULT %d/%d" % [demo.checks-demo.failures,demo.checks])
	game.feedback.stop_all(); OS.delay_msec(150); game.queue_free(); await demo.process_frame; await demo.process_frame
	demo.quit(1 if demo.failures else 0)

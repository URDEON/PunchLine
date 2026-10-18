extends RefCounted
# Demostración del modelo integrado mediante acciones reales del laboratorio.
var demo
var game: Node3D

func prepare() -> void:
	demo.prepare()
	game.yaw = PI-0.35
	game.pitch = -0.15
	game.zoom = 5.1

func play(owner_demo: SceneTree) -> void:
	demo = owner_demo
	game = demo.game
	prepare()
	demo.say("Modelo enviado · rig de combate · texturas originales")
	await demo.frames(90)
	demo.verify(game.rig_enabled and game.rig_scene != null,"modelo con rig cargado")
	demo.shot("modelo_01_reposo")
	var start: Vector3 = game.player.position
	demo.say("WASD · movimiento y mezcla de locomoción")
	Input.action_press("forward")
	await demo.frames(90)
	Input.action_release("forward")
	await demo.frames(35)
	demo.verify(game.player.position.distance_to(start)>4,"locomocion mueve al personaje real")
	demo.shot("modelo_02_carrera")
	prepare()
	demo.say("F · guardia y recuperación de la pose")
	Input.action_press("block")
	await demo.frames(45)
	demo.verify(game.block,"guardia activa")
	demo.shot("modelo_03_guardia")
	Input.action_release("block")
	await demo.frames(30)
	demo.verify(not game.block,"guardia se libera")
	prepare()
	var enemy: Dictionary = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,0,-1.6)
	demo.say("Laboratorio: dummy pasivo delante · M1 real")
	await demo.frames(10)
	game.punch()
	await demo.frames(30)
	demo.verify(enemy.hp<100,"M1 conserva contacto y daño")
	demo.shot("modelo_04_m1")
	prepare()
	enemy.body.position = game.player.position+Vector3(0,0,-1.6)
	demo.say("4 · patada con el rig del nuevo modelo")
	await demo.frames(10)
	demo.key(KEY_4)
	await demo.frames(70)
	demo.verify(is_equal_approx(enemy.hp,100.0-game.tuning.kick_damage),"patada conserva el daño de la tabla actual")
	demo.shot("modelo_05_patada")
	prepare()
	demo.say("Q · dash y vuelta a locomoción")
	start = game.player.position
	demo.key(KEY_Q)
	await demo.frames(45)
	demo.verify(game.player.position.distance_to(start)>2,"dash mueve el cuerpo real")
	demo.shot("modelo_06_dash")
	prepare()
	demo.say("B · Running Man sobre los mismos huesos")
	demo.key(KEY_B)
	game.interface.choose_emote(0)
	await demo.frames(90)
	demo.verify(game.presentation.emote_time>0,"baile compatible con nuevo rig")
	demo.shot("modelo_07_baile")
	demo.key(KEY_B)
	prepare()
	demo.say("Laboratorio: energía 100 · G activa la transformación real")
	game.charge = 100
	demo.key(KEY_G)
	await demo.frames(145)
	demo.verify(game.form=="FORM1" and not game.rig_holder.visible,"transformacion sustituye modelo en su momento")
	demo.shot("modelo_08_fase1")
	demo.say("Reset del laboratorio · retorno al personaje enviado")
	game.reset_lab()
	for npc in game.enemies: npc.body.position = Vector3(40+int(npc.kind)*4,0.05,30)
	await demo.frames(60)
	demo.verify(game.form=="BASE" and game.rig_holder.visible,"reset restaura el modelo")
	demo.shot("modelo_09_regreso")
	demo.say("Prueba del modelo terminada · acciones automatizadas")
	await demo.frames(40)
	print("DEMO RESULT %d/%d" % [demo.checks-demo.failures,demo.checks])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await demo.process_frame
	await demo.process_frame
	demo.quit(1 if demo.failures else 0)

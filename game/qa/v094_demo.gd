extends RefCounted
# Preparativos explícitos del laboratorio; acciones y reglas reales del juego.
var demo
var game: Node3D

func prepare() -> void:
	demo.prepare()
	game.set_paused(false)
	game.preferences.values.hold_attack = false
	game.yaw = 0
	game.pitch = -0.18
	game.zoom = 6.4
	for enemy in game.enemies: game.set_dummy_mode(enemy,0)
	for i in range(game.enemies.size()): game.enemies[i].body.position = Vector3(35+i*4,0.05,30)

func play(owner_demo: SceneTree) -> void:
	demo = owner_demo
	game = demo.game
	prepare()
	demo.say("F + WASD · brazos en defensa y piernas en movimiento")
	await demo.frames(45)
	Input.action_press("block"); Input.action_press("forward")
	await demo.frames(90)
	demo.verify(game.block and game.player.velocity.length() > 2,"guardia con desplazamiento real")
	demo.shot("v094_01_guardia")
	Input.action_release("forward"); Input.action_press("right")
	await demo.frames(60)
	Input.action_release("right"); Input.action_release("block")
	await demo.frames(30)
	prepare()
	var enemy: Dictionary = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,0,-1.8)
	demo.say("M1 · contacto ajustado y tercer golpe del nuevo pack")
	await demo.frames(15)
	for i in range(4):
		game.punch()
		await demo.frames(25)
	demo.verify(enemy.hp == 77,"cuatro M1 mantienen daño y derribo")
	await demo.frames(45)
	prepare()
	enemy = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,0,-1.8)
	demo.say("4 · patada sincronizada con el impacto real")
	await demo.frames(15)
	demo.key(KEY_4)
	await demo.frames(55)
	demo.verify(is_equal_approx(enemy.hp,100-game.tuning.kick_damage),"patada mantiene daño")
	prepare()
	enemy = game.enemies[0]
	# Esperar la protección normal del reinicio antes de presentar un ataque.
	await demo.frames(65)
	game.set_dummy_mode(enemy,3)
	enemy.body.position = game.player.position+Vector3(0,0,-1.8)
	enemy.cd = 0
	demo.say("2 · counter ante ataque del NPC; vidrio y pose congelada 5 s")
	demo.key(KEY_2)
	await demo.frames(40)
	demo.verify(game.hp == 100 and enemy.hp == 92 and enemy.projection_freeze > 0,"counter responde al ataque real")
	if DisplayServer.get_name() != "headless":
		demo.verify(enemy.projection_frame.image_ready,"pose 2D capturada por el renderizador")
	demo.shot("v094_02_fotograma")
	await demo.frames(290)
	demo.verify(enemy.projection_freeze == 0 and enemy.rig_holder.visible,"al finalizar regresa el NPC 3D")
	prepare()
	demo.say("K · Skull Wisp como Kogane; preparación del laboratorio: energía 100")
	if not game.presentation.kogane_invoked: demo.key(KEY_K)
	game.charge = 100
	await demo.frames(70)
	demo.verify(game.presentation.companion_message.contains("Transformación lista"),"Kogane muestra estado real de energía")
	demo.shot("v094_03_kogane")
	demo.key(KEY_G)
	await demo.frames(145)
	game.moves.phase_charge = 100
	demo.say("Preparación del laboratorio: evolución 100 · G pasa a fase2")
	demo.key(KEY_G)
	await demo.frames(120)
	demo.verify(game.form == "FORM2","evolución activada con sus transiciones")
	demo.say("Fase2 · vertical en reposo; cabeza delante y boca abajo al avanzar")
	await demo.frames(75)
	var model: Node3D = game.presentation.form_models[1]
	demo.verify((-model.global_basis.z).normalized().dot(Vector3.UP) > 0.99,"reposo vertical con cabeza arriba")
	demo.shot("v095_04_reposo_horizontal")
	demo.say("W · postura horizontal durante el desplazamiento")
	Input.action_press("forward")
	await demo.frames(75)
	demo.verify(absf(model.global_basis.z.normalized().dot(Vector3.UP)) < 0.03,"movimiento horizontal")
	demo.shot("v094_05_horizontal")
	Input.action_release("forward")
	await demo.frames(65)
	demo.verify((-model.global_basis.z).normalized().dot(Vector3.UP) > .98,"reposo vuelve a vertical")
	enemy = game.enemies[0]
	game.set_dummy_mode(enemy,0)
	enemy.body.position = game.player.position+Vector3(3,0,0)
	demo.say("4 · dominio real con suelo y límite circulares")
	demo.key(KEY_4)
	await demo.frames(65)
	demo.verify(game.moves.domain_time > 0 and game.moves.domain_arena != null,"dominio se activa tras preparación")
	demo.shot("v094_06_dominio")
	Input.action_press("right")
	await demo.frames(50)
	Input.action_release("right")
	await demo.frames(30)
	demo.verify(game.player.is_on_floor(),"suelo circular sostiene al jugador")
	demo.say("Salida del dominio por su duración normal; regreso al escenario")
	await demo.frames(760)
	demo.verify(game.moves.domain_time == 0 and game.moves.domain_arena == null and game.moves.domain_exterior == null,"dominio termina y limpia ambos escenarios")
	demo.say("Esc > Pruebas · nuevos botones de fotograma; acciones automatizadas")
	game.interface.open_menu("test")
	await demo.frames(80)
	demo.shot("v094_07_menu_pruebas")
	game.set_paused(false)
	print("DEMO RESULT %d/%d" % [demo.checks-demo.failures,demo.checks])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await demo.process_frame
	await demo.process_frame
	demo.quit(1 if demo.failures else 0)

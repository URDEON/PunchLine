extends RefCounted
# Casos de la demo 0.9.1. Solo prepara estados del laboratorio; ejecuta las mecánicas reales.
var demo
var game: Node3D

func prepare() -> void:
	demo.prepare()
	for i in range(game.enemies.size()): game.enemies[i].kind = i

func simulation_seconds(seconds: float) -> void:
	# El Counter comienza al recibir el ataque, no al pulsar 2.
	# Esperar tiempo de física evita confundir preparación con duración del estado.
	var deadline: float = game.clock+seconds
	while game.clock < deadline:
		await demo.frames(1)

func play(owner_demo: SceneTree) -> void:
	demo = owner_demo
	game = demo.game
	prepare()
	demo.say("0.9.1.1 · autoapuntado integrado · sin fijación con la rueda")
	var enemy: Dictionary = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(1.4,0,-8)
	await demo.frames(35)
	demo.key(KEY_1)
	await demo.frames(115)
	demo.verify(enemy.hp == 82,"autoapuntado conecta18 contra objetivo lateral")
	demo.shot("091_01_autoapuntado")
	prepare()
	await demo.frames(10)
	demo.say("Ventana final de140ms · el dummy evita el impacto con dash real")
	enemy = game.enemies[0]
	enemy.kind = 4
	enemy.body.position = game.player.position+Vector3(0,0,-6)
	demo.key(KEY_1)
	await demo.frames(115)
	demo.verify(enemy.hp == 100 and game.moves.projection.last_result == "esquivado","dash final evita la habilidad sin invulnerabilidad nueva")
	demo.shot("091_02_esquiva")
	prepare()
	await demo.frames(10)
	demo.say("Variante cercana · contacto válido, órbita física y ráfaga limitada a18")
	enemy = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,0,-1.8)
	demo.key(KEY_1)
	await demo.frames(100)
	demo.verify(enemy.hp == 82 and game.moves.projection.last_close_variant,"secuencia cercana conecta18 y libera al enemigo")
	demo.shot("091_03_cercana")
	prepare()
	await demo.frames(10)
	demo.say("Counter · detención5s y captura de pose2D")
	enemy = game.enemies[2]
	enemy.kind = 3
	enemy.body.position = game.player.position+Vector3(0,0,-1.8)
	enemy.cd = 0
	demo.key(KEY_2)
	await demo.frames(35)
	demo.verify(enemy.hp == 92 and game.hp == 100 and enemy.projection_freeze > 4.5,"Counter responde a ataque real y activa frame")
	demo.shot("091_04_counter")
	demo.say("Corrección 0.9.1.1 · girar cámara y usar1 sobre el blanco cercano congelado")
	# El Counter conserva su recuperación: esperar el control real, no saltársela.
	for i in range(60):
		if game.moves.can_use(1): break
		await demo.frames(1)
	game.yaw += deg_to_rad(30)
	demo.key(KEY_1)
	await demo.frames(100)
	demo.verify(enemy.hp == 74 and game.moves.projection.damage_applied == 18,"1 conecta18 sobre blanco cercano lateral después del Counter")
	demo.shot("0911_04b_counter_proyeccion")
	await simulation_seconds(float(enemy.projection_freeze)+0.1)
	demo.verify(enemy.projection_freeze == 0 and enemy.rig_anim.speed_scale > 0,"frame termina sin bloquear animación")
	prepare()
	await demo.frames(10)
	demo.say("M1 · combo reducido a23 de daño · remate normal conservado")
	enemy = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,0,-1.8)
	for i in range(4):
		game.punch()
		await demo.frames(24)
	demo.verify(enemy.hp == 77 and enemy.ragdoll,"combo real conserva remate y knockdown")
	demo.shot("091_05_m1")
	prepare()
	await demo.frames(10)
	demo.say("Laboratorio · cinco modos de dummy para cada NPC")
	game.interface.open_menu("test")
	await demo.frames(110)
	demo.shot("091_06_laboratorio")
	game.set_paused(false)
	prepare()
	await demo.frames(10)
	demo.say("Laboratorio · HP1 y energía100 para comprobar muerte y renacimiento")
	enemy = game.enemies[2]
	enemy.kind = 3
	enemy.body.position = game.player.position+Vector3(0,0,-1.8)
	enemy.cd = 0
	game.hp = 1
	game.charge = 100
	for i in range(80):
		await demo.frames(1)
		if game.form == "FORM1": break
	demo.verify(game.form == "FORM1" and game.moves.phase_charge == 0,"muerte con barra llena comienza en fase1")
	# El laboratorio detiene al atacante después del primer golpe para observar la transición.
	enemy.kind = 0
	await demo.frames(145)
	demo.shot("091_07_renacimiento")
	enemy.kind = 0
	enemy.body.position = Vector3(35,0.05,30)
	demo.say("Laboratorio · evolución100 · fase2 exige pasar antes por fase1")
	game.moves.phase_charge = 100
	demo.key(KEY_G)
	await demo.frames(110)
	demo.verify(game.form == "FORM2","evolución continúa desde fase1")
	demo.shot("091_08_evolucion")
	demo.say("0.9.1.1 terminada · acciones automatizadas sobre el juego real")
	await demo.frames(60)
	print("DEMO RESULT %d/%d" % [demo.checks-demo.failures,demo.checks])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await demo.process_frame
	await demo.process_frame
	demo.quit(1 if demo.failures else 0)

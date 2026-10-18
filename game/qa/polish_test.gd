extends SceneTree

var game: Node3D
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures += 1
	print(("PASS " if condition else "FAIL ")+message)

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func reset() -> void:
	Input.action_release("forward")
	Input.action_release("attack")
	Input.action_release("block")
	game.reset_lab()
	game.preferences.values.hold_attack = false
	game.player_wakeup_protection = 0
	for enemy in game.enemies:
		enemy.body.position = Vector3(40+int(enemy.kind)*3,0.05,30)
	await frames(5)

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await frames(5)
	verify(game.rig_enabled and is_instance_valid(game.locomotion_tree),"rig original y mezcla de locomocion disponibles")
	await reset()
	Input.action_press("forward")
	await frames(2)
	var speed := Vector2(game.player.velocity.x,game.player.velocity.z).length()
	verify(speed > 0 and speed < game.SPEED,"arranque acelera sin salto instantaneo de velocidad")
	await frames(20)
	verify(is_equal_approx(Vector2(game.player.velocity.x,game.player.velocity.z).length(),game.SPEED),"aceleracion alcanza velocidad objetivo")
	verify(game.locomotion_tree.active and game.locomotion_vector.y < -0.7,"la mezcla sigue la velocidad real")
	Input.action_release("forward")
	await frames(2)
	verify(Vector2(game.player.velocity.x,game.player.velocity.z).length() > 0,"frenado conserva continuidad")
	await frames(10)
	verify(Vector2(game.player.velocity.x,game.player.velocity.z).length() < 0.01,"frenado termina sin deslizar indefinidamente")
	await reset()
	game.punch()
	await frames(17)
	game.attack_buffer = 0.16
	await frames(8)
	verify(game.combo == 2 and game.attack_anim > 0,"entrada anticipada encadena segundo M1")
	await reset()
	game.punch()
	await frames(17)
	game.buffered_ability = 4
	game.ability_buffer = 0.16
	await frames(8)
	verify(game.skill_active == "skill4","habilidad anticipada se ejecuta al terminar M1")
	await reset()
	game.jump_buffer = 0.12
	await frames(2)
	verify(game.player.velocity.y > 0,"salto en buffer se consume en suelo")
	await reset()
	var enemy: Dictionary = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,0,-3.4)
	game.moves.press(3)
	await frames(16)
	verify(float(enemy.hp) < 100 and float(enemy.hp) > 86,"rush inicia una rafaga con impactos separados")
	await frames(55)
	verify(float(enemy.hp) == 86 and game.charge == 14,"rush completo aplica14 dano y14 energia")
	verify(game.skill_active == "","rafaga termina sin bloquear el estado")
	await reset()
	enemy = game.enemies[1]
	enemy.body.position = game.player.position+Vector3(0,0,-1.8)
	await frames(2)
	game.combo = 4
	game.attack_variant = "downslam"
	game.resolve_punch_hit()
	verify(float(enemy.hp) == 90,"downslam atraviesa guardia frontal")
	await reset()
	enemy = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,5,-1.8)
	game.combo = 1
	game.resolve_punch_hit()
	verify(float(enemy.hp) == 100,"M1 no alcanza objetivos muy por encima del jugador")
	await reset()
	game.preferences.install_key("ability3",KEY_T)
	var input := InputEventKey.new()
	input.keycode = KEY_T
	input.pressed = true
	game._unhandled_input(input)
	verify(game.skill_active == "skill3","tecla reasignada activa la habilidad correcta")
	game.preferences.install_key("ability3",KEY_3)
	await reset()
	game.preferences.values.master = 0
	game.preferences.apply()
	verify(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")),"volumen cero silencia la mezcla")
	game.preferences.values.master = 0.85
	game.preferences.apply()
	game.interface.open_menu("settings")
	var previous_clock: float = game.clock
	await frames(10)
	verify(game.paused and game.clock == previous_clock and not game.rig_anim.active,"menu pausa simulacion y animaciones")
	verify(game.interface.menu.visible and game.interface.selected_tab == "settings","ajustes se abren dentro del menu")
	game.set_paused(false)
	await frames(2)
	verify(not game.paused and game.rig_anim.active,"continuar restaura juego y animaciones")
	for resolution in [Vector2i(1280,720),Vector2i(640,720),Vector2i(360,640),Vector2i(640,360),Vector2i(1920,1080)]:
		root.size = resolution
		await frames(5)
		var fits := true
		for card in game.interface.cards:
			var rect: Rect2 = card.panel.get_global_rect()
			fits = fits and rect.position.x >= 0 and rect.end.x <= game.interface.screen.size.x+1 and rect.end.y <= game.interface.screen.size.y+1
		verify(fits,"HUD cabe en %dx%d" % [resolution.x,resolution.y])
	root.size = Vector2i(1280,720)
	game.reset_lab()
	await frames(5)
	verify(game.form == "BASE" and game.hp == 100 and game.charge == 0 and game.skill_active == "","reinicio de laboratorio limpia forma y recursos")
	print("RESULT %d/%d OK" % [checks-failures,checks])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await process_frame
	await process_frame
	await process_frame
	quit(1 if failures else 0)

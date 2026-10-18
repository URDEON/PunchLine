extends SceneTree
# Prueba automatizada ejecutada por Godot. Los preparativos de laboratorio son explícitos.
var game: Node3D
var caption: Label
var failures := 0
var checks := 0
var output := ""
var capture_fps := 60

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	if OS.get_cmdline_user_args().has("--realtime"):
		await create_timer(float(count)/60.0, true, false).timeout
		return
	for i in range(ceili(float(count)*capture_fps/60.0)): await process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	game._unhandled_input(event)

func verify(condition: bool, name: String) -> void:
	checks += 1
	if not condition: failures += 1
	print(("PASS " if condition else "FAIL ")+name)

func shot(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		root.get_texture().get_image().save_png(output+"/"+name+".png")

func say(text: String) -> void:
	caption.text = "PRUEBA AUTOMÁTICA  /  NAOYA 0.9.8\n"+text
	print("DEMO "+text)

func prepare() -> void:
	game.reset_lab()
	for enemy in game.enemies: enemy.body.position = Vector3(40+int(enemy.kind)*4,0.05,30)
	game.yaw = 0.18
	game.pitch = -0.20
	game.zoom = 6.4

func run() -> void:
	output = ProjectSettings.globalize_path("user://review")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
		if argument.begins_with("--demo-fps="): capture_fps = clampi(int(argument.trim_prefix("--demo-fps=")),1,60)
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	layer.layer = 7
	caption = Label.new()
	layer.add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	caption.offset_top = 216
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",17)
	caption.add_theme_color_override("font_color",Color("efdcad"))
	caption.add_theme_color_override("font_outline_color",Color("141a23"))
	caption.add_theme_constant_override("outline_size",3)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--start-flag="):
			var flag := argument.trim_prefix("--start-flag=")
			await process_frame
			await process_frame
			var ready := FileAccess.open(output+"/demo_ready", FileAccess.WRITE)
			ready.store_string("Godot listo para captura real\n")
			ready.close()
			while not FileAccess.file_exists(flag): await process_frame
	if OS.get_cmdline_user_args().has("--v098"):
		await load("res://qa/v098_demo.gd").new().play(self)
		return
	if OS.get_cmdline_user_args().has("--v097"):
		await load("res://qa/v097_demo.gd").new().play(self)
		return
	if OS.get_cmdline_user_args().has("--v096"):
		await load("res://qa/v096_demo.gd").new().play(self)
		return
	if OS.get_cmdline_user_args().has("--v095"):
		var sequence = load("res://qa/v095_demo.gd").new()
		await sequence.play(self)
		return
	elif OS.get_cmdline_user_args().has("--v094"):
		await load("res://qa/v094_demo.gd").new().play(self)
		return
	if OS.get_cmdline_user_args().has("--modelo"):
		await load("res://qa/modelo_demo.gd").new().play(self)
		return
	if OS.get_cmdline_user_args().has("--hud"):
		await load("res://qa/hud_demo.gd").new().play(self)
		return
	if OS.get_cmdline_user_args().has("--revision"):
		await load("res://qa/revision_demo.gd").new().play(self)
		return
	if OS.get_cmdline_user_args().has("--short"):
		await short_demo()
		return
	prepare()
	say("Movimiento con aceleración y mezcla de animaciones")
	await frames(50)
	Input.action_press("forward")
	await frames(80)
	Input.action_release("forward")
	await frames(30)
	game.camera_lock = true
	Input.action_press("right")
	await frames(65)
	Input.action_release("right")
	await frames(25)
	game.camera_lock = false
	prepare()
	await frames(10)
	say("Combo M1 · cuatro golpes y derribo")
	var enemy: Dictionary = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,0,-2.0)
	for i in range(4):
		game.punch()
		await frames(24)
	verify(float(enemy.hp) == 77,"combo real inflige23 dano")
	shot("01_combate")
	await frames(65)
	prepare()
	await frames(10)
	say("Contra · una ventana frontal, sin invulnerabilidad permanente")
	enemy = game.enemies[2]
	enemy.body.position = game.player.position+Vector3(0,0,-1.8)
	enemy.cd = 0
	game.moves.press(2)
	await frames(40)
	verify(game.hp == 100 and float(enemy.hp) == 92,"contra detiene ataque real del NPC")
	await frames(35)
	prepare()
	await frames(10)
	say("Rush · avance y tres impactos separados")
	enemy = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,0,-3.4)
	key(KEY_3)
	await frames(65)
	verify(float(enemy.hp) == 86,"rafaga real suma14 dano")
	await frames(30)
	prepare()
	await frames(10)
	say("Dash y desplazamiento · cámara con seguimiento suave")
	key(KEY_Q)
	await frames(40)
	prepare()
	await frames(10)
	say("Kogane y emote · animación del pack original adaptada")
	game.yaw = PI-0.4
	game.zoom = 4.2
	key(KEY_K)
	key(KEY_B)
	game.interface.choose_emote(0)
	await frames(105)
	shot("02_emote")
	key(KEY_B)
	key(KEY_K)
	prepare()
	await frames(10)
	say("Menú de pruebas · estados preparados de forma explícita")
	game.interface.open_menu("test")
	await frames(55)
	shot("03_menu")
	game.interface.select_tab("settings")
	await frames(60)
	shot("04_ajustes")
	game.set_paused(false)
	say("Preparación del laboratorio: energía al 100% · G transforma")
	game.charge = 100
	key(KEY_G)
	await frames(145)
	verify(game.form == "FORM1" and game.presentation.transition_time == 0,"metamorfosis completa")
	shot("05_fase1")
	say("Fase 1 · embestida con barrido de colisiones")
	enemy = game.enemies[0]
	enemy.body.position = game.player.position+game.facing_forward()*5
	key(KEY_1)
	await frames(60)
	verify(float(enemy.hp) == 82,"embestida golpea una sola vez")
	game.moves.phase_charge = 100
	say("Preparación del laboratorio: evolución al 100% · G evoluciona")
	key(KEY_G)
	await frames(110)
	verify(game.form == "FORM2","segunda fase activada")
	shot("06_fase2")
	game.reset_enemy(enemy)
	enemy.body.position = game.player.position+game.facing_forward()*5
	say("Fase 2 · tentáculos, agarre y lanzamiento")
	key(KEY_2)
	await frames(90)
	verify(float(enemy.hp) == 82,"agarre inflige6+12 dano")
	game.reset_enemy(enemy)
	enemy.body.position = game.player.position+game.facing_forward()*8
	say("Aceleración · preparación, velocidad progresiva e impacto")
	key(KEY_3)
	await frames(120)
	verify(float(enemy.hp) == 74,"aceleracion inflige26 dano")
	game.player.position = Vector3(0,0.05,5)
	game.player.reset_physics_interpolation()
	game.model.rotation.y = 0
	game.yaw = 0.65
	game.zoom = 8
	for target in game.enemies: game.reset_enemy(target)
	game.enemies[0].body.position = Vector3(-4,0.05,2)
	game.enemies[1].body.position = Vector3(4,0.05,2)
	game.enemies[2].body.position = Vector3(0,0.05,-1)
	say("Dominio · el NPC quieto permanece a salvo; moverse activa la penalización")
	key(KEY_4)
	await frames(100)
	verify(game.moves.domain_time > 0,"dominio abre su arena")
	shot("07_dominio")
	await frames(100)
	verify(float(game.enemies[0].hp) == 100 and float(game.enemies[2].hp) < 100,"dominio distingue quietud de movimiento")
	await frames(705)
	verify(game.moves.domain_time == 0,"dominio finaliza y devuelve a los actores")
	say("Prueba terminada · HUD, combate, audio, transformaciones y dominio")
	await frames(70)
	shot("08_final")
	print("DEMO RESULT %d/%d" % [checks-failures,checks])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)

func short_demo() -> void:
	prepare()
	say("Movimiento · animaciones mezcladas y cámara suave")
	await frames(45)
	Input.action_press("forward")
	await frames(60)
	Input.action_release("forward")
	await frames(30)
	prepare()
	await frames(10)
	say("M1 · cuatro golpes, impactos y derribo")
	var enemy: Dictionary = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,0,-2.0)
	for i in range(4):
		game.punch()
		await frames(24)
	verify(float(enemy.hp) == 77,"combo real inflige23 dano")
	shot("01_combate")
	await frames(40)
	prepare()
	await frames(10)
	say("Contra · ventana frontal frente al ataque del NPC")
	enemy = game.enemies[2]
	enemy.body.position = game.player.position+Vector3(0,0,-1.8)
	enemy.cd = 0
	game.moves.press(2)
	await frames(50)
	verify(game.hp == 100 and float(enemy.hp) == 92,"contra detiene ataque real")
	prepare()
	await frames(10)
	say("Rush · avance y ráfaga de tres impactos")
	enemy = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,0,-3.4)
	key(KEY_3)
	await frames(65)
	verify(float(enemy.hp) == 86,"rush suma14 dano")
	await frames(25)
	prepare()
	await frames(10)
	say("Emote y Kogane · animación y audio")
	game.yaw = PI-0.4
	game.zoom = 4.2
	key(KEY_K)
	key(KEY_B)
	game.interface.choose_emote(0)
	await frames(105)
	shot("02_emote")
	key(KEY_B)
	key(KEY_K)
	prepare()
	await frames(10)
	say("HUD adaptable · menú de pruebas")
	game.interface.open_menu("test")
	await frames(90)
	shot("03_menu")
	say("Ajustes · audio, cámara, gráficos y controles")
	game.interface.select_tab("settings")
	await frames(90)
	shot("04_ajustes")
	game.set_paused(false)
	say("Preparación de laboratorio · energía al 100% para probar G")
	game.charge = 100
	key(KEY_G)
	await frames(145)
	verify(game.form == "FORM1","primera fase visible")
	shot("05_fase1")
	say("Preparación de laboratorio · evolución al 100%")
	game.moves.phase_charge = 100
	key(KEY_G)
	await frames(110)
	verify(game.form == "FORM2","segunda fase visible")
	shot("06_fase2")
	say("Fase 2 · embestida y barrido de colisiones")
	enemy = game.enemies[0]
	enemy.body.position = game.player.position+game.facing_forward()*5
	key(KEY_1)
	await frames(65)
	verify(float(enemy.hp) == 78,"embestida evolucionada inflige22 dano")
	say("Prueba breve terminada · ejecución real de Godot")
	await frames(75)
	shot("08_final")
	print("DEMO RESULT %d/%d" % [checks-failures,checks])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)

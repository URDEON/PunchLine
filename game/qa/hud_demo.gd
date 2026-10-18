extends RefCounted
# Recorrido automático del HUD sobre el proyecto real; preparativos de laboratorio rotulados.
var demo
var game: Node3D
func prepare() -> void:
	demo.prepare()
	for i in range(game.enemies.size()):
		game.enemies[i].kind = 0
		game.enemies[i].body.position = Vector3(35+i*4,0.05,30)
func click(position: Vector2) -> void:
	if DisplayServer.get_name() != "headless": Input.warp_mouse(position)
	var motion := InputEventMouseMotion.new()
	motion.position = position
	demo.root.push_input(motion,true)
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		demo.root.push_input(event,true)
func play(owner_demo: SceneTree) -> void:
	demo = owner_demo
	game = demo.game
	demo.root.size = Vector2i(1280,720)
	prepare()
	demo.say("HUD del boceto · retrato, estados, salud segmentada y fichas conectadas")
	await demo.frames(70)
	demo.verify(game.interface.cards[2].name.text == "Golpe veloz" and game.interface.identity.broken == [false,false,false],"HUD muestra habilidades y salud completas")
	demo.shot("092_01_hud")
	demo.say("Laboratorio · vida73 y energía62 para comprobar segmentos y lectura")
	game.hp = 73
	game.charge = 62
	await demo.frames(90)
	demo.verify(game.interface.identity.broken[2] and game.interface.health_text.text == "73 / 100","segmento vacío se marca y lectura coincide conHP")
	demo.shot("092_02_salud")
	prepare()
	await demo.frames(30)
	var enemy: Dictionary = game.enemies[0]
	enemy.kind = 3
	enemy.body.position = game.player.position+Vector3(0,0,-1.8)
	enemy.cd = 0
	demo.say("Counter contra ataque real · cabecera azul y cooldown visible")
	demo.key(KEY_2)
	await demo.frames(35)
	demo.verify(enemy.hp == 92 and game.interface.cards[1].panel.cooldown > 10,"Counter activa frame y cabecera de cooldown")
	demo.shot("092_03_counter")
	demo.say("P · lista bajo el retrato: Naoya, Robot y Coming Soon · combate pausado sin reiniciar recursos")
	demo.key(KEY_P)
	var clock: float = game.clock
	await demo.frames(100)
	demo.verify(game.paused and game.interface.character_popup.visible and game.clock == clock,"P abre selector y detiene reloj real")
	demo.shot("092_04_personaje")
	demo.key(KEY_P)
	await demo.frames(15)
	demo.say("Alt · clic en el triángulo relleno · lista bajo el retrato")
	demo.key(KEY_ALT)
	click(game.interface.identity.get_global_transform_with_canvas()*Vector2(54,130))
	await demo.frames(65)
	demo.verify(game.paused and game.interface.character_popup.visible,"clic automatizado en triángulo abre dropdown real")
	demo.shot("0921_05_triangulo")
	click(game.interface.character_rows[0].get_global_rect().get_center())
	var release := InputEventKey.new()
	release.keycode = KEY_ALT
	release.pressed = false
	game._unhandled_input(release)
	await demo.frames(15)
	demo.verify(not game.paused and not game.interface.character_popup.visible,"clic automatizado eligeNaoya y reanuda")
	prepare()
	demo.say("Esc · menú de pruebas, ajustes y controles")
	game.interface.open_menu("test")
	await demo.frames(90)
	demo.shot("092_05_pruebas")
	game.interface.select_tab("settings")
	await demo.frames(90)
	demo.verify(game.paused and game.interface.selected_tab == "settings","menú de ajustes mantiene pausa")
	demo.shot("092_06_ajustes")
	game.interface.menu_content.get_child(0).show_category("interface")
	game.interface.menu_content.get_child(0).fields.get_node("hud_scale").value = 0.5
	await demo.frames(60)
	demo.verify(is_equal_approx(game.interface.identity.scale.x,0.5),"ajuste reduce el HUD mientras menú conserva tamaño")
	demo.shot("0921_07_hud_50")
	game.interface.menu_content.get_child(0).fields.get_node("hud_scale").value = 0.8
	game.interface.select_tab("controls")
	await demo.frames(90)
	demo.shot("092_07_controles")
	game.set_paused(false)
	prepare()
	demo.say("Laboratorio · fase1 · solo Embestida disponible")
	game.start_form("FORM1",true)
	await demo.frames(150)
	demo.verify(game.interface.cards[1].panel.unavailable and game.interface.cards[3].detail.text == "FASE 2" and game.interface.cards[0].panel.icon_kind == "worm_charge","fase1 distingue habilidades bloqueadas")
	demo.shot("092_08_fase1")
	demo.say("Laboratorio · evolución100 · habilidades de fase2")
	game.moves.phase_charge = 100
	demo.key(KEY_G)
	await demo.frames(125)
	demo.verify(game.form == "FORM2" and game.interface.cards[3].name.text == "Dominio" and not game.interface.cards[3].panel.unavailable and game.interface.cards[0].panel.icon_kind == "evolved_charge","fase2 cambia fichas según estado real")
	demo.shot("092_09_fase2")
	demo.say("Demostración terminada · acciones automatizadas")
	await demo.frames(60)
	print("DEMO RESULT %d/%d" % [demo.checks-demo.failures,demo.checks])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await demo.process_frame
	await demo.process_frame
	demo.quit(1 if demo.failures else 0)

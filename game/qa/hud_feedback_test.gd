extends SceneTree
# Regresiones del feedback del HUD: eventos GUI, pausa, escala y dibujos por forma.
var game: Node3D
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func frames(count: int = 4) -> void:
	for i in range(count): await physics_frame
func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition: failures += 1
	print(("PASS " if condition else "FAIL ")+description)
func key(code: Key, pressed: bool = true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	game._unhandled_input(event)
func click(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	root.push_input(motion,true)
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event,true)
func fits(rect: Rect2, bounds: Vector2) -> bool:
	return rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= bounds.x+1 and rect.end.y <= bounds.y+1
func run() -> void:
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for enemy in game.enemies:
		enemy.kind = 0
		enemy.body.position = Vector3(40,0.1,30)
	await frames(12)
	var ui: CanvasLayer = game.interface
	verify(is_equal_approx(game.preferences.values.hud_scale,0.8),"HUD inicial80% para reducir ocupación")
	verify(ui.identity.find_children("*","Label").all(func(node: Label) -> bool: return not node.text.contains("PJ")),"retrato no contiene etiquetaP·PJ")
	var filled := false
	for command in ui.identity.draw_model():
		if command.type == "polygon" and command.color == Color("e6cc89") and command.points == PackedVector2Array(ui.identity.SELECTOR): filled = true
	verify(filled and ui.identity._has_point(Vector2(54,130)) and not ui.identity._has_point(Vector2(54,59)),"triángulo dorado completamente relleno y área clicable precisa")
	key(KEY_ALT)
	verify(game.hud_cursor and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,"Alt libera cursor para alcanzar el triángulo")
	var yaw: float = game.yaw
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(140,30)
	game._unhandled_input(motion)
	verify(game.yaw == yaw,"cursor libre no gira cámara al recorrer HUD")
	var triangle: Vector2 = ui.identity.get_global_transform_with_canvas()*Vector2(54,130)
	click(triangle)
	await frames(15)
	await frames()
	verify(ui.character_popup.visible and game.paused and not ui.menu.visible,"clic GUI real en triángulo abre lista sin menú central")
	verify(ui.character_rows.size() == 3 and ui.character_rows[0].text == "The Proyected" and ui.character_rows[1].text == "Robot" and ui.character_rows[2].text == "Coming Soon","lista tiene Naoya, Robot y Coming Soon")
	verify(not ui.character_rows[0].disabled and not ui.character_rows[1].disabled and ui.character_rows[2].disabled,"Naoya y Robot disponibles; casilla futura no seleccionable")
	verify(ui.character_popup.position.y > (ui.identity.get_global_transform_with_canvas()*Vector2(54,154)).y and absf(ui.character_popup.position.x-(ui.identity.position.x+18*ui.identity.scale.x)) < 1,"lista anclada debajo del retrato y triángulo")
	var clock: float = game.clock
	game.hp = 73
	game.moves.cooldowns.b1 = 4
	click(ui.character_rows[2].get_global_rect().get_center())
	await frames(10)
	verify(ui.character_popup.visible and game.clock == clock and game.hp == 73 and game.moves.cooldowns.b1 == 4,"clicComingSoon conserva pausa, recursos y selección")
	click(triangle)
	await frames(15)
	await frames()
	verify(not game.paused and not ui.character_popup.visible and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,"segundo clic cierra lista y respetaAlt todavía pulsado")
	key(KEY_ALT,false)
	verify(game.hud_mouse_mode() == Input.MOUSE_MODE_CAPTURED and not game.hud_cursor,"soltarAlt solicita captura del mouse para cámara")
	key(KEY_P)
	await frames(15)
	await frames()
	click(ui.screen.size*0.5)
	await frames(15)
	verify(not ui.character_popup.visible and not game.paused,"clic fuera cierra dropdown")
	key(KEY_P)
	await frames(15)
	await frames()
	for down in [true,false]:
		var accept := InputEventKey.new()
		accept.keycode = KEY_ENTER
		accept.pressed = down
		root.push_input(accept,true)
		await frames(15)
	verify(not game.paused and not ui.character_popup.visible,"Enter seleccionaNaoya desde el teclado")
	key(KEY_P)
	await frames(15)
	await frames()
	Input.action_press("attack")
	click(ui.character_rows[0].get_global_rect().get_center())
	await frames(15)
	verify(not game.paused and game.combo == 0 and game.attack_anim == 0,"seleccionarNaoya con clic mantenido no disparaM1 al cerrar")
	Input.action_release("attack")
	await frames()
	verify(not game.hud_attack_requires_release,"soltar clic permite volver a atacar")
	var attack := InputEventMouseButton.new()
	attack.button_index = MOUSE_BUTTON_LEFT
	attack.pressed = true
	game._unhandled_input(attack)
	verify(game.combo == 1,"M1 vuelve a funcionar después de soltar clic de selección")
	game.reset_lab()
	ui.open_menu("settings")
	await frames()
	var menu_size: Vector2 = ui.menu_panel.size
	var settings: Node = ui.menu_content.get_child(0)
	settings.show_category("interface")
	await frames()
	var slider: HSlider = settings.fields.get_node("hud_scale")
	verify(slider.min_value == 0.5 and slider.max_value == 1.0,"Ajustes ofrece50–100%")
	slider.value = 0.5
	await frames()
	verify(is_equal_approx(ui.identity.scale.x,0.5) and ui.menu_panel.size == menu_size,"deslizador reduce HUD en vivo sin achicar menú")
	var saved := ConfigFile.new()
	saved.load(game.preferences.FILE)
	verify(is_equal_approx(saved.get_value("settings","hud_scale",0),0.5),"tamaño elegido se guarda en disco")
	game.preferences.values.hud_scale = 1
	game.preferences.setup(game)
	verify(is_equal_approx(game.preferences.values.hud_scale,0.5) and is_equal_approx(ui.identity.scale.x,0.5),"recarga de preferencias restaura tamañoHUD")
	key(KEY_P)
	await frames(15)
	verify(ui.character_popup.visible and not ui.menu.visible,"P abre lista desde Ajustes")
	key(KEY_ESCAPE)
	await frames(15)
	verify(game.paused and ui.menu.visible and ui.selected_tab == "settings","Esc de lista conserva la pestaña y pausa previas")
	key(KEY_ESCAPE)
	await frames(15)
	verify(not game.paused,"Esc del menú permite continuar")
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(360,640),Vector2i(640,360),Vector2i(360,360)]:
		root.size = resolution
		for scale_value in [0.5,0.8,1.0]:
			game.preferences.set_value("hud_scale",scale_value)
			await frames(6)
			var contained := fits(ui.identity.get_global_rect(),ui.screen.size)
			for card in ui.cards: contained = contained and fits(card.panel.get_global_rect(),ui.screen.size)
			verify(contained,"HUD cabe en%d×%d a%.0f%%" % [resolution.x,resolution.y,scale_value*100])
			key(KEY_P)
			await frames(15)
			await frames(6)
			verify(fits(ui.character_popup.get_global_rect(),ui.screen.size),"dropdown cabe en%d×%d a%.0f%%" % [resolution.x,resolution.y,scale_value*100])
			key(KEY_P)
			await frames(15)
	root.size = Vector2i(1280,720)
	game.preferences.set_value("hud_scale",0.8)
	game.start_form("FORM1",true)
	await frames(130)
	var phase1: Array = []
	for card in ui.cards:
		phase1.append(preload("res://scripts/hud_ink.gd").drawing(card.panel.icon_kind))
		verify(card.panel.icon_kind.begins_with("worm_") and not phase1.back().is_empty(),"fase1 utiliza dibujo de criatura: "+card.panel.icon_kind)
	verify(ui.cards[1].panel.unavailable and ui.cards[3].detail.text == "FASE 2","dibujos de fase1 no habilitan habilidades de fase2")
	game.moves.phase_charge = 100
	key(KEY_G)
	await frames(130)
	verify(game.form == "FORM2","evolución real cambia a fase2")
	for i in range(4):
		var illustration: Array = preload("res://scripts/hud_ink.gd").drawing(ui.cards[i].panel.icon_kind)
		verify(ui.cards[i].panel.icon_kind.begins_with("evolved_") and illustration != phase1[i],"fase2 cambia silueta y dibujo de habilidad%d" % (i+1))
	game.end_form()
	ui.tick(0.016)
	verify(ui.cards.map(func(card: Dictionary) -> String: return card.panel.icon_kind) == ["projection","counter","rush","kick"],"volver a humano restaura cuatro dibujos del boceto")
	ui.open_menu("controls")
	var dash_button: Button
	settings=ui.menu_content.get_child(0)
	for row in settings.fields.get_children():
		if row is HBoxContainer and row.get_child(0).text == "Dash": dash_button = row.get_child(1)
	dash_button.pressed.emit()
	var reserved := InputEventKey.new()
	reserved.keycode = KEY_ALT
	reserved.pressed = true
	settings._input(reserved)
	verify(game.preferences.bindings.dash == KEY_Q and settings.notice.text.contains("reservadas"),"reasignarAlt se rechaza para conservar acceso al cursor")
	reserved.keycode = KEY_ESCAPE
	settings._input(reserved)
	verify(settings.awaiting == "" and dash_button.text == "Q","Esc cancela reasignación reservada y conserva dash")
	game.set_paused(false)
	verify(game.preferences.bindings.dash == KEY_Q and game.preferences.bindings.character == KEY_P,"Qdash yPselector conservados tras ajustes y fases")
	print("RESULT %d/%d OK" % [checks-failures,checks])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)

extends SceneTree
# Interfaz conectada a acciones reales; resolución y estados de laboratorio explícitos.
var game: Node3D
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func verify(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+description)
func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	game._unhandled_input(event)
func reset() -> void:
	Input.action_release("block")
	game.set_paused(false)
	game.reset_lab()
	game.player_wakeup_protection = 0
	game.preferences.values.hold_attack = false
	for i in range(game.enemies.size()):
		game.enemies[i].kind = 0
		game.enemies[i].body.position = Vector3(35+i*4,0.1,30)
	await frames(12)
func area(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(points.size()): total += points[i].cross(points[(i+1)%points.size()])
	return absf(total)*0.5
func world_points(card: Control) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in card.outline: points.append(card.position+point)
	return points
func contained(rectangle: Rect2, bounds: Vector2) -> bool:
	return rectangle.position.x >= -1 and rectangle.position.y >= -1 and rectangle.end.x <= bounds.x+1 and rectangle.end.y <= bounds.y+1
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await reset()
	var ui: CanvasLayer = game.interface
	verify(game.preferences.key_name("dash") == "Q" and game.preferences.key_name("character") == "P","Q dash y P personaje son teclas independientes")
	verify(ui.cards.size() == 4 and ui.cards[0].name.text == "Proyección" and ui.cards[2].name.text == "Golpe veloz","cuatro fichas mantienen los nombres del boceto")
	var overlap := 0.0
	for i in range(4):
		for j in range(i+1,4):
			for part in Geometry2D.intersect_polygons(world_points(ui.cards[i].panel),world_points(ui.cards[j].panel)): overlap += area(part)
	verify(overlap < 0.1,"los cuatro polígonos conservan separación sin montarse")
	verify(ui.cards[0].panel.position.y < ui.cards[1].panel.position.y and ui.cards[1].panel.position.x < ui.cards[2].panel.position.x and ui.cards[3].panel.position.x > ui.cards[2].panel.position.x,"silueta superior1, izquierda2, central3 y derecha4")
	for hp in [100.0,80.0,50.0,0.0]:
		game.hp = hp
		ui.tick(1)
		var expected := [hp == 0,hp <= 50,hp <= 80]
		verify(ui.identity.broken == expected and ui.health_text.text == "%d / 100" % int(hp),"salud%.0f marca segmentos vacíos y número real" % hp)
	await reset()
	var enemy: Dictionary = game.enemies[0]
	game.hit_player_from_enemy(enemy,Vector3.BACK)
	await frames(2)
	verify(game.hp == 94 and ui.health_text.text == "94 / 100" and ui.identity.segments[2] < 1,"daño real del enemigo actualiza vida del HUD")
	await reset()
	Input.action_press("block")
	await frames(2)
	verify(ui.identity.states[3],"icono de guardia responde al bloqueo real")
	Input.action_release("block")
	await frames(2)
	key(KEY_Q)
	await frames(2)
	verify(game.dash_time > 0 and ui.identity.states[1] and not game.paused,"Q activa dash e icono de velocidad")
	await reset()
	game.charge = 100
	await frames(2)
	verify(ui.identity.states[2] and ui.identity.energy == 100,"icono de forma y barra anuncian energía completa")
	game.player_ragdoll = true
	game.player_ragdoll_time = 1
	await frames(2)
	verify(ui.identity.states[0],"icono de caída responde al derribo")
	await reset()
	key(KEY_2)
	await frames(2)
	verify(ui.cards[1].panel.cooldown > 10 and ui.cards[1].panel.draw_model()[1].color == Color("3589cd"),"Counter real colorea solo cabecera azul durante cooldown")
	verify(ui.cards[1].name.visible and ui.cards[1].key.visible and ui.cards[1].detail.text.ends_with(" s"),"cooldown conserva nombre, tecla y segundos")
	await reset()
	game.moves.cooldowns.b2 = 0.1
	await frames(10)
	verify(ui.cards[1].panel.cooldown == 0 and ui.cards[1].detail.text == "LISTO","cabecera vuelve a lista al terminar enfriamiento real")
	await reset()
	game.hp = 73
	game.moves.cooldowns.b1 = 4
	ui.tick(0.016)
	key(KEY_P)
	await frames(15)
	verify(game.paused and ui.character_popup.visible and not ui.menu.visible,"P abre selector y pausa combate")
	var clock: float = game.clock
	await frames(8)
	verify(game.clock == clock and game.moves.cooldowns.b1 == 4,"selector no consume cooldown ni tiempo del juego")
	var select_button: Button = ui.character_rows[0]
	verify(ui.character_rows.size() == 3 and select_button.text == "The Proyected" and not select_button.disabled and not ui.character_rows[1].disabled and ui.character_rows[2].disabled,"selector incluye Naoya y Robot jugables y una casilla futura")
	select_button.pressed.emit()
	await frames(15)
	verify(not game.paused and game.hp == 73 and is_equal_approx(game.moves.cooldowns.b1,4.0-(game.clock-clock)),"elegir Naoya vuelve al combate sin reiniciar vida o habilidades")
	key(KEY_P)
	await frames(15)
	key(KEY_P)
	await frames(15)
	verify(not game.paused,"P permite cerrar su selector")
	key(KEY_ESCAPE)
	await frames(15)
	verify(game.paused and ui.selected_tab == "test","Esc abre menú de pruebas desde juego")
	key(KEY_P)
	await frames(15)
	verify(game.paused and ui.character_popup.visible and not ui.menu.visible,"P abre lista desde otra pestaña")
	key(KEY_ESCAPE)
	await frames(15)
	verify(game.paused and ui.menu.visible and not ui.character_popup.visible,"Esc devuelve al menú previo sin reanudar combate")
	key(KEY_ESCAPE)
	await frames(15)
	verify(not game.paused,"segundo Esc cierra menú previo y recupera juego")
	game.preferences.install_key("character",KEY_T)
	ui.tick(0.016)
	key(KEY_P)
	await frames(15)
	verify(not game.paused and ui.identity.selector_key == "T","reasignación actualiza acceso al triángulo y desactiva P anterior")
	key(KEY_T)
	await frames(15)
	verify(game.paused and ui.character_popup.visible,"tecla reasignada abre selector real")
	game.preferences.save()
	var saved := ConfigFile.new()
	saved.load(game.preferences.FILE)
	verify(saved.get_value("keys","character",0) == KEY_T,"tecla de selector persiste en configuración")
	game.preferences.install_key("character",KEY_P)
	await reset()
	game.start_form("FORM1",true)
	await frames(130)
	verify(not ui.cards[0].panel.unavailable and ui.cards[1].panel.unavailable and ui.cards[3].detail.text == "FASE 2","fase1 distingue habilidad disponible y bloqueadas")
	game.moves.phase_charge = 100
	game.moves.transform_input()
	await frames(110)
	verify(ui.cards[0].name.text == "Embestida" and ui.cards[3].name.text == "Dominio" and not ui.cards[3].panel.unavailable,"fase2 actualiza nombres, dibujos y disponibilidad")
	game.ult_time = 10
	ui.tick(0.016)
	verify(ui.cards[3].panel.unavailable and ui.cards[3].detail.text == "14.8 s","dominio explica tiempo mínimo insuficiente")
	game.domain_used = true
	ui.tick(0.016)
	verify(ui.cards[3].detail.text == "USADO","dominio usado conserva señal propia")
	await reset()
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(640,720),Vector2i(360,640),Vector2i(640,360),Vector2i(360,360)]:
		root.size = resolution
		await frames(6)
		var fits := contained(ui.identity.get_global_rect(),ui.screen.size)
		for card in ui.cards: fits = fits and contained(card.panel.get_global_rect(),ui.screen.size)
		verify(fits,"retratos y fichas caben en%d×%d" % [resolution.x,resolution.y])
		verify(not ui.identity.get_global_rect().intersects(ui.ability_cluster.get_global_rect()),"salud y habilidades no se superponen en%d×%d" % [resolution.x,resolution.y])
		verify(not ui.status.get_global_rect().intersects(ui.menu_button.get_global_rect()),"estado de combate y botón menú no se montan en%d×%d" % [resolution.x,resolution.y])
		var text_fits := true
		for card in ui.cards:
			for node in [card.name,card.key,card.detail]:
				var transform: Transform2D = node.get_global_transform_with_canvas()
				for corner in [Vector2.ZERO,Vector2(node.size.x,0),node.size,Vector2(0,node.size.y)]:
					var point: Vector2 = transform*corner
					text_fits = text_fits and point.x >= -1 and point.y >= -1 and point.x <= ui.screen.size.x+1 and point.y <= ui.screen.size.y+1
		verify(text_fits,"nombres, teclas y cooldowns permanecen en pantalla en%d×%d" % [resolution.x,resolution.y])
		for tab in ["character","test","settings","controls"]:
			ui.open_menu(tab)
			await frames(6)
			var menu_fits := contained(ui.menu_panel.get_global_rect(),ui.screen.size)
			menu_fits = menu_fits and ui.menu_content.size.x <= ui.scroll.size.x+1
			if not menu_fits: print("MENU_DIAG ",tab," ",resolution," panel=",ui.menu_panel.get_global_rect()," min=",ui.menu_panel.get_combined_minimum_size()," content=",ui.menu_content.size," scroll=",ui.scroll.size)
			verify(menu_fits,"menú%s cabe sin desbordamiento horizontal en%d×%d" % [tab,resolution.x,resolution.y])
			if tab == "controls":
				ui.scroll.scroll_vertical = 100000
				await frames(6)
				var settings: Control = ui.menu_content.get_child(ui.menu_content.get_child_count()-1)
				var last: Control = settings.fields.get_child(settings.fields.get_child_count()-1)
				var visible_area: Rect2 = ui.scroll.get_global_rect()
				verify(last.get_global_rect().end.y <= visible_area.end.y+1 and last.get_global_rect().position.y >= visible_area.position.y-1,"scroll permite llegar al último control en%d×%d" % [resolution.x,resolution.y])
		game.set_paused(false)
	root.size = Vector2i(1280,720)
	await frames(6)
	var legacy := ConfigFile.new()
	legacy.set_value("keys","ability3",KEY_P)
	legacy.set_value("settings","master",0.42)
	legacy.save(game.preferences.FILE)
	var restored := preload("res://scripts/preferences.gd").new()
	game.add_child(restored)
	restored.setup(game)
	verify(restored.bindings.character == KEY_P and restored.bindings.ability3 != KEY_P and restored.bindings.values().count(KEY_P) == 1,"configuración antigua conP no dispara personaje y habilidad a la vez")
	verify(restored.values.master == 0.42 and restored.binding_notice != "","migración conserva ajustes y avisa del cambio de tecla")
	print("RESULT %d/%d OK" % [checks-failures,checks])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)

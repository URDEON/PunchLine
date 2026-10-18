extends SceneTree
var checks := 0
var passed := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, title: String) -> void:
	checks += 1
	if ok: passed += 1
	print("PASS " if ok else "FAIL ",title)
func run() -> void:
	var arena: Node3D = preload("res://network/online.tscn").instantiate(); root.add_child(arena)
	for extent in [Vector2i(360,360),Vector2i(360,640),Vector2i(640,360),Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = extent
		for frame in range(5): await process_frame
		var rect: Rect2 = arena.panel.get_global_rect()
		check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= extent.x+1 and rect.end.y <= extent.y+1,"panel queda dentro de "+str(extent))
		check(arena.host_button.is_visible_in_tree() and arena.join_button.is_visible_in_tree(),"crear/unirse accesibles en "+str(extent))
	check(arena.session.join_game("",7777,"Jugador",0) == ERR_INVALID_PARAMETER,"IP vacía se rechaza antes de conectar")
	check(arena.session.host_game("Jugador",0,80) == ERR_INVALID_PARAMETER,"puerto inválido no crea partida")
	check(arena.session.clean_name("\n\t  Nombre\n") == "Nombre","nombre se normaliza")
	root.size = Vector2i(1280,720)
	await process_frame
	arena.name_field.grab_focus(); arena.name_field.select_all()
	for letter in "Edu Ñ P":
		var event := InputEventKey.new(); event.pressed = true; event.unicode = letter.unicode_at(0); event.keycode = letter.unicode_at(0) as Key
		Input.parse_input_event(event); await process_frame
		event = event.duplicate(); event.pressed = false; Input.parse_input_event(event); await process_frame
	check(arena.name_field.text == "Edu Ñ P","nombre acepta escritura real, espacios, Ñ y P")
	check(arena.menu_open and arena.name_field.has_focus(),"escribir P no cierra el formulario ni captura el mouse")
	check(arena.load_nickname() == "Edu Ñ P","nombre persiste en el perfil")
	arena.queue_free(); await process_frame; await process_frame
	print("RESULTADO ",passed,"/",checks); quit(0 if passed == checks else 1)

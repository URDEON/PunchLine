extends SceneTree
var checks := 0
var passed := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, title: String) -> void:
	checks += 1
	if ok: passed += 1
	print("PASS " if ok else "FAIL ",title)
func run() -> void:
	var game: Node3D = preload("res://main.tscn").instantiate(); root.add_child(game)
	for i in range(4): await physics_frame
	game.robots.forced = 1; game.robots.select(1); game.charge = 67
	for extent in [Vector2i(360,360),Vector2i(360,640),Vector2i(640,360),Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = extent
		for i in range(7): await process_frame
		game.interface.resize(); game.interface.tick(.1)
		var cards_inside := true
		for card in game.interface.cards:
			var rect: Rect2 = card.panel.get_global_rect()
			cards_inside = cards_inside and rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= extent.x+1 and rect.end.y <= extent.y+1
		check(cards_inside,"cuatro habilidades holográficas caben en "+str(extent))
		check(is_equal_approx(game.interface.identity.holo_energy.value,67),"Ultimate conserva su valor al redimensionar "+str(extent))
		game.interface.open_menu("settings")
		for i in range(10): await process_frame
		var panel: Rect2 = game.interface.menu_panel.get_global_rect()
		check(panel.position.x >= 0 and panel.position.y >= 0 and panel.end.x <= extent.x+1 and panel.end.y <= extent.y+1,"menú robótico cabe en "+str(extent))
		game.set_paused(false)
	game.robots.select(0); game.interface.tick(.1)
	check(not game.interface.identity.holographic,"cambiar a Naoya restaura estilo original")
	game.feedback.stop_all(); game.queue_free()
	var drain_until := Time.get_ticks_msec()+200
	while Time.get_ticks_msec() < drain_until: await process_frame
	print("RESULTADO ",passed,"/",checks); quit.call_deferred(0 if passed == checks else 1)

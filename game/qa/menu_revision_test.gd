extends SceneTree
var checks := 0
var passed := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,title: String) -> void:
	checks += 1
	if ok: passed += 1
	print("PASS " if ok else "FAIL ",title)
func run() -> void:
	var menu: Control = preload("res://launcher.tscn").instantiate(); root.add_child(menu)
	for extent in [Vector2i(360,360),Vector2i(360,640),Vector2i(640,360),Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = extent
		for page in ["home","play","controls"]:
			menu.page(page)
			for frame in range(5): await process_frame
			var bottom: float = menu.status.get_global_rect().end.y
			check(bottom <= extent.y+1,"menú "+page+" cabe en "+str(extent)+" (fin %.1f)" % bottom)
			check(not menu.buttons.is_empty() and menu.buttons[0].has_focus(),"teclado enfoca opción en "+page)
	menu.queue_free(); await process_frame; await process_frame
	print("RESULTADO ",passed,"/",checks); quit(0 if passed == checks else 1)

extends SceneTree
## Actual Forward+ screenshots. Requires desktop/Xvfb; never substitutes headless output.
var destination := ""

func _initialize() -> void:
	run.call_deferred()

func frames(count: int) -> void:
	for i in range(count): await process_frame

func capture(label: String) -> void:
	await frames(3)
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(destination.path_join(label+".png"))
	if error!=OK:
		push_error("Screenshot failed: "+error_string(error))
		quit(1)
	print("CAPTURE ",label)

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("A graphical renderer is required")
		quit(1)
		return
	destination = OS.get_environment("WARFARE_EVIDENCE_DIR")
	if destination.is_empty():
		push_error("Set WARFARE_EVIDENCE_DIR outside the project")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(destination)
	var menu: Control = load("res://ui/warfare_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await capture("menu")
	menu.start_practice()
	await frames(15)
	var game: Node3D = current_scene
	var player: CharacterBody3D = game.player
	if Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:
		push_error("Practice did not capture the mouse")
		quit(1)
		return
	player.view.pitch = -0.16
	await capture("tps_district500")
	player.view.set_first_person(true)
	player.view.pitch = -1.40
	await capture("fps_visible_body")
	player.view.pitch = -0.04
	root.get_node("WarfareSettings").values.lens = true
	await capture("bodycam")
	root.get_node("WarfareSettings").values.lens = false
	game.hud.toggle_pause()
	await capture("camera_options")
	game.hud.toggle_pause()
	if Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:
		push_error("Resume did not restore mouse capture")
		quit(1)
		return
	print("RENDER_WARFARE_DONE ",RenderingServer.get_current_rendering_method()," / ",RenderingServer.get_video_adapter_name())
	game.queue_free()
	await frames(5)
	quit()

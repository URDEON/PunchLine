extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var game: Node3D = load("res://main.tscn").instantiate(); root.add_child(game)
	for enemy in game.enemies: game.set_dummy_mode(enemy,0)
	var output := OS.get_environment("NAOYA_QA_OUTPUT")
	if output == "": output = ProjectSettings.globalize_path("user://render_v098")
	DirAccess.make_dir_recursive_absolute(output)
	for i in range(40): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("inicio.png"))
	game.player.position = Vector3(54,.2,0); game.player.velocity = Vector3.ZERO; game.yaw = PI*.55; game.pitch = -.25; game.camera_initialized = false
	for i in range(30): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("bulevar.png"))
	game.arena.urban.set_lighting(true)
	for i in range(30): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("noche.png"))
	game.set_paused(false); game.player.position = Vector3(0,.1,5); game.moves.freeze_player(5)
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("vidrio.png"))
	game.feedback.stop_all(); OS.delay_msec(150); game.queue_free(); await process_frame; await process_frame; quit()

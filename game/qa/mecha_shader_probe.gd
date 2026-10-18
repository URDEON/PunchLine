extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var demo: Node3D = preload("res://FusionDemo.tscn").instantiate(); demo.autoplay = false; demo.automatic_process = false
	root.add_child(demo)
	for frame in range(8): await process_frame
	demo.play_fusion(); demo.advance(8.7); demo.dust.clear(); demo.advance(2.15)
	for frame in range(8): await process_frame
	await RenderingServer.frame_post_draw
	var path := OS.get_environment("NAOYA_QA_OUTPUT")
	if path.is_empty(): path = ProjectSettings.globalize_path("user://mecha_shader_probe.png")
	root.get_texture().get_image().save_png(path)
	print("SHADERS_Y_TEXTURAS_RENDERIZADOS ",path)
	demo.stop(); demo.dust.clear(); demo.queue_free()
	await create_timer(.2).timeout
	quit.call_deferred()

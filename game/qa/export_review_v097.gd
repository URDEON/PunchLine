extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var output_dir := OS.get_environment("NAOYA_QA_OUTPUT")
	if output_dir == "": output_dir = ProjectSettings.globalize_path("user://revision_mapa_v097")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var game: Node3D = load("res://main.tscn").instantiate(); root.add_child(game)
	for i in range(5): await physics_frame
	var document := GLTFDocument.new(); var state := GLTFState.new()
	var error := document.append_from_scene(game.arena,state)
	if error == OK: error = document.write_to_filesystem(state,output_dir.path_join("district24.glb"))
	print("EXPORT_GEOMETRY ",error)
	game.feedback.stop_all(); OS.delay_msec(150); game.queue_free(); await process_frame; await process_frame; quit(error)

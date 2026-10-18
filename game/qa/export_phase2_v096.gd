extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var model: Node3D = load("res://assets/forms/evolved_rig.tscn").instantiate()
	root.add_child(model)
	var document := GLTFDocument.new(); var state := GLTFState.new()
	var error := document.append_from_scene(model,state)
	if error == OK: error = document.write_to_filesystem(state,"/workspace/qa_v096/phase2_raw.glb")
	print("EXPORT_PHASE2 ",error); quit(error)

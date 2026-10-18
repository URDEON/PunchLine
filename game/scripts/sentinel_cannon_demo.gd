extends "res://scripts/sentinel_cannon.gd"
## Taller independiente del material editable V8, sin controlar una partida.
func _ready() -> void:
	body = Node3D.new(); body.scale = Vector3.ONE*HEIGHT; add_child(body)
	model = JUNK.instantiate(); body.add_child(model)
	_lights_and_camera(); _assemble_sources(); _build_sparse_coupling()
	_build_interface(); _pose(0)
	autoplay = false; set_process(true); set_process_input(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file.call_deferred("res://launcher.tscn")
		return
	super._input(event)

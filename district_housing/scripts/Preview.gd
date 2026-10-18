extends Node3D
# Fly camera for geometric inspection; not a substitute for PunchLine gameplay.
func _process(delta: float) -> void:
	var camera := $Camera as Camera3D
	var move := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W): move.z -= 1
	if Input.is_physical_key_pressed(KEY_S): move.z += 1
	if Input.is_physical_key_pressed(KEY_A): move.x -= 1
	if Input.is_physical_key_pressed(KEY_D): move.x += 1
	if Input.is_physical_key_pressed(KEY_Q): move.y -= 1
	if Input.is_physical_key_pressed(KEY_E): move.y += 1
	camera.position += move * delta * 50

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		$Camera.rotation.x = clampf($Camera.rotation.x-event.relative.y*0.003,-1.55,1.55)
		$Camera.rotation.y -= event.relative.x*0.003

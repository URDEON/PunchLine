extends Node
const Command = preload("res://units/soldiers/soldier_command.gd")
var enabled := true

static func install_actions() -> void:
	var bindings := {"wf_left":KEY_A,"wf_right":KEY_D,"wf_forward":KEY_W,
		"wf_back":KEY_S,"wf_sprint":KEY_SHIFT,"wf_walk":KEY_ALT,
		"wf_jump":KEY_SPACE,"wf_crouch":KEY_CTRL,"wf_view":KEY_V,"wf_shoulder":KEY_B}
	for action in bindings:
		if InputMap.has_action(action): continue
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		InputMap.action_add_event(action,event)

func read(yaw: float) -> RefCounted:
	var command := Command.new()
	command.yaw = yaw
	# Headless has no captured cursor; still accept injected Input actions for QA.
	if not enabled: return command
	if DisplayServer.get_name()!="headless" and Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED: return command
	command.move = Input.get_vector("wf_left","wf_right","wf_forward","wf_back")
	command.sprint = Input.is_action_pressed("wf_sprint")
	command.walk = Input.is_action_pressed("wf_walk")
	command.crouch = Input.is_action_pressed("wf_crouch")
	command.jump = Input.is_action_just_pressed("wf_jump")
	return command

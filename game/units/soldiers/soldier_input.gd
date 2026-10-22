extends Node
const Command = preload("res://units/soldiers/soldier_command.gd")
var enabled := true

static func install_actions() -> void:
	var bindings := {"wf_left":KEY_A,"wf_right":KEY_D,"wf_forward":KEY_W,
		"wf_back":KEY_S,"wf_sprint":KEY_SHIFT,"wf_walk":KEY_ALT,
		"wf_jump":KEY_SPACE,"wf_crouch":KEY_CTRL,"wf_view":KEY_V,"wf_shoulder":KEY_B,
		"wf_reload":KEY_R,"wf_primary":KEY_1,"wf_secondary":KEY_2}
	for action in bindings:
		if InputMap.has_action(action): continue
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		InputMap.action_add_event(action,event)
	for pair in [["wf_fire",MOUSE_BUTTON_LEFT],["wf_aim",MOUSE_BUTTON_RIGHT]]:
		if InputMap.has_action(pair[0]): continue
		InputMap.add_action(pair[0])
		var event := InputEventMouseButton.new()
		event.button_index = pair[1]
		InputMap.action_add_event(pair[0],event)

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
	command.fire = Input.is_action_pressed("wf_fire")
	command.aim = Input.is_action_pressed("wf_aim")
	command.reload = Input.is_action_just_pressed("wf_reload")
	if Input.is_action_just_pressed("wf_primary"): command.weapon_slot = 0
	elif Input.is_action_just_pressed("wf_secondary"): command.weapon_slot = 1
	return command

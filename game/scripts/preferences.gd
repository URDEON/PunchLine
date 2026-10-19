extends Node

var game: Node3D
var binding_notice := ""
var values := {
	"fullscreen": false, "vsync": true, "ui_motion": 1.0,"chromatic":.3,"bloom":.35,"lens_dirt":.25,
	"master": 0.85, "sfx": 0.85, "music": 0.55, "sensitivity": 1.0,
	"fov": 75.0, "shake": 0.35, "effects": true, "hints": true,
	"hold_attack": true, "fps": false, "quality": 1, "hud_scale": 0.8,
	"graphics_preset":1,"debris_enabled":true, "grass_quality":2, "grass_wind":.55, "fog_enabled":true,"fog_amount":.35,
	"camera_distance": 5.5, "kogane_comments": true, "ambient": 0.35,
	"procedural_gait": true, "human_grounding": true, "robot_grounding": true, "body_lens": .14, "combat": 1.0, "reference_audio": true, "legacy_map": false
}
var bindings := {
	"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D,
	"jump": KEY_SPACE, "block": KEY_F, "dash": KEY_Q, "character": KEY_P, "walk": KEY_CTRL,
	"ability1": KEY_1, "ability2": KEY_2, "ability3": KEY_3,
	"ability4": KEY_4, "transform": KEY_G, "emote": KEY_B, "kogane": KEY_K, "interact": KEY_E, "lock": KEY_C, "spider_vision":KEY_T
}
const FILE := "user://preferences_v09.cfg"

func setup(host: Node3D) -> void:
	game = host
	# La versión cambia el nombre de la carpeta de usuario de Godot.
	# Copiar solo si falta, conservando preferencias y récord anteriores.
	for version in ["0.9.23","0.9.22","0.9.21","0.9.20","0.9.19","0.9.18","0.9.17","0.9.16","0.9.15","0.9.14","0.9.13","0.9.12","0.9.11","0.9.10","0.9.9","0.9.8","0.9.7","0.9.6"]:
		var previous := OS.get_user_data_dir().get_base_dir().path_join("Naoya - Laboratorio de combate "+version)
		for filename in ["preferences_v09.cfg","route_echo_punchline.dat","route_echo_v096.dat"]:
			var old_file := previous.path_join(filename); var destination := OS.get_user_data_dir().path_join(filename)
			if FileAccess.file_exists(old_file) and not FileAccess.file_exists(destination): DirAccess.copy_absolute(old_file,destination)
	var defaults := bindings.duplicate()
	var config := ConfigFile.new()
	if config.load(FILE) == OK:
		for key in values:
			values[key] = config.get_value("settings", key, values[key])
		for key in bindings:
			bindings[key] = int(config.get_value("keys", key, bindings[key]))
		# Al incorporar P a una configuración anterior, evitar que active dos acciones.
		if not config.has_section_key("keys","character"):
			for action in bindings:
				if action == "character" or int(bindings[action]) != KEY_P: continue
				var replacement: int = defaults[action]
				if bindings.values().has(replacement):
					for candidate in [KEY_O,KEY_L,KEY_J,KEY_H,KEY_U,KEY_I,KEY_Y,KEY_T]:
						if not bindings.values().has(candidate):
							replacement = candidate
							break
				bindings[action] = replacement
				binding_notice = "P quedó para Personaje. Revisa tus teclas en esta pestaña."
	for action in bindings:
		install_key(action, int(bindings[action]))
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", mouse)
	for name in ["SFX", "Music", "UI", "Combat"]:
		if AudioServer.get_bus_index(name) < 0:
			AudioServer.add_bus()
			var index := AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(index, name)
	AudioServer.set_bus_send(AudioServer.get_bus_index("Combat"),"SFX")
	var master := AudioServer.get_bus_index("Master")
	if AudioServer.get_bus_effect_count(master) == 0:
		var limiter := AudioEffectLimiter.new()
		limiter.ceiling_db = -0.8
		AudioServer.add_bus_effect(master, limiter)
	apply()

func install_key(action: String, code: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var event := InputEventKey.new()
	event.keycode = code as Key
	InputMap.action_add_event(action, event)
	bindings[action] = code

func key_name(action: String) -> String:
	return OS.get_keycode_string(int(bindings.get(action, 0)))

func apply() -> void:
	Engine.set_meta("punchline_ui_motion",float(values.ui_motion))
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if bool(values.fullscreen) else DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(values.vsync) else DisplayServer.VSYNC_DISABLED)
	for pair in [["Master", "master"], ["SFX", "sfx"], ["Music", "music"], ["UI", "sfx"], ["Combat","combat"]]:
		var level: float = clampf(float(values[pair[1]]), 0, 1)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(pair[0]), linear_to_db(maxf(0.0001, level)))
		AudioServer.set_bus_mute(AudioServer.get_bus_index(pair[0]), level <= 0.001)
	var quality: int = clampi(int(values.quality), 0, 2)
	get_viewport().msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][quality]
	get_tree().call_group("district_ambience","apply_settings",values)
	values.hud_scale = clampf(float(values.hud_scale),0.5,1.0)
	values.camera_distance = clampf(float(values.camera_distance),0.0,10.0)
	game.zoom = float(values.camera_distance)
	if is_instance_valid(game.interface) and game.interface.screen != null:
		game.interface.resize()

func set_preset(preset:int)->void:
	values.graphics_preset=clampi(preset,0,2)
	values.quality=values.graphics_preset
	values.grass_quality=[1,2,3][values.graphics_preset]
	values.fog_amount=[.18,.35,.48][values.graphics_preset]
	values.debris_enabled=values.graphics_preset>0
	apply();save()
func set_value(key: String, value: Variant) -> void:
	values[key] = value
	apply()
	save()

func save() -> void:
	var config := ConfigFile.new()
	for key in values:
		config.set_value("settings", key, values[key])
	for key in bindings:
		config.set_value("keys", key, bindings[key])
	config.save(FILE)

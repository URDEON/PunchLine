extends Node
## Separate settings file: legacy PunchLine preferences remain recoverable.
signal changed
const DEFAULTS := {"fov":85.0,"sensitivity":0.0025,"invert_y":false,
	"bodycam":true,"bob":true,"shake":0.35,"lens":false,"distance":3.4,
	"fullscreen":false,"grass_quality":1,"fog_amount":0.15,"animation_style":0}
var values: Dictionary = DEFAULTS.duplicate()

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://warfare_settings.cfg") == OK:
		for key in DEFAULTS:
			var value: Variant = config.get_value("warfare",key,DEFAULTS[key])
			if typeof(value) == typeof(DEFAULTS[key]): values[key] = value
	values.fov = clampf(values.fov,65,110)
	values.sensitivity = clampf(values.sensitivity,0.0005,0.008)
	values.shake = clampf(values.shake,0,1)
	values.distance = clampf(values.distance,1.8,5.0)
	values.grass_quality = clampi(values.grass_quality,0,3)
	values.fog_amount = clampf(values.fog_amount,0,1)
	values.animation_style = clampi(values.animation_style,0,1)
	apply_display()

func set_value(key: String,value: Variant) -> void:
	if not DEFAULTS.has(key): return
	values[key] = value
	apply_display()
	changed.emit()
	var config := ConfigFile.new()
	for item in values: config.set_value("warfare",item,values[item])
	var error := config.save("user://warfare_settings.cfg")
	if error != OK: push_warning("Cannot save Warfare settings: "+error_string(error))

func apply_display() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if values.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

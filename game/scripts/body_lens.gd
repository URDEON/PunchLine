extends CanvasLayer
## Una pasada de pantalla; HUD y menús se dibujan después sin distorsión.
var screen: ColorRect
var options:Dictionary={"chromatic":.3,"bloom":.35,"lens_dirt":.25}
func _ready() -> void:
	layer = 1
	screen = ColorRect.new(); screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new(); material.shader = preload("res://shaders/body_lens.gdshader")
	screen.material = material; add_child(screen); screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hide()
func set_strength(value: float) -> void:
	visible = value > .001 or float(options.chromatic)+float(options.bloom)+float(options.lens_dirt)>.001
	if screen != null: screen.material.set_shader_parameter("strength",clampf(value,0,.35))
func configure(settings:Dictionary)->void:
	for key in options:
		options[key]=float(settings.get(key,options[key])) if bool(settings.get("effects",true)) else 0.0
		if screen!=null:screen.material.set_shader_parameter(key,options[key])

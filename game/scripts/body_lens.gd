extends CanvasLayer
## Una pasada de pantalla; HUD y menús se dibujan después sin distorsión.
var screen: ColorRect
func _ready() -> void:
	layer = 1
	screen = ColorRect.new(); screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new(); material.shader = preload("res://shaders/body_lens.gdshader")
	screen.material = material; add_child(screen); screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hide()
func set_strength(value: float) -> void:
	visible = value > .001
	if screen != null: screen.material.set_shader_parameter("strength",clampf(value,0,.35))

extends Button
var target := 0.0
var blend := 0.0
var resting_position := Vector2.ZERO
var holographic := false
func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	paint_skin()
	mouse_entered.connect(func() -> void: target = 1.0)
	mouse_exited.connect(func() -> void: target = 1.0 if has_focus() else 0.0)
	focus_entered.connect(func() -> void: target = 1.0)
	focus_exited.connect(func() -> void: target = 0.0)

func set_holographic(value: bool) -> void:
	if value == holographic: return
	holographic = value
	if is_inside_tree(): paint_skin()

func paint_skin() -> void:
	if holographic:
		for state_name in ["normal","hover","pressed","disabled","focus"]:
			var state_file: String = "focused" if state_name == "focus" else state_name
			var skin := StyleBoxTexture.new()
			skin.texture = load("res://assets/ui/holo/buttons/btn_wide_192x48_"+state_file+".svg")
			skin.texture_margin_left = 56; skin.texture_margin_right = 24; skin.texture_margin_top = 14; skin.texture_margin_bottom = 14
			skin.content_margin_left = 48; skin.content_margin_right = 22; skin.content_margin_top = 8; skin.content_margin_bottom = 8
			add_theme_stylebox_override(state_name,skin)
		for state_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: add_theme_color_override(state_name,Color("c1f3ff"))
		add_theme_color_override("font_disabled_color",Color("497b8a")); add_theme_constant_override("outline_size",0)
		return
	var shadow := StyleBoxTexture.new(); shadow.texture = preload("res://assets/ui/ink/shadow.svg"); shadow.content_margin_left = 22; shadow.content_margin_right = 22; shadow.content_margin_top = 12; shadow.content_margin_bottom = 12
	var brush := StyleBoxTexture.new(); brush.texture = preload("res://assets/ui/ink/selection.svg"); brush.content_margin_left = 22; brush.content_margin_right = 22; brush.content_margin_top = 12; brush.content_margin_bottom = 12
	add_theme_stylebox_override("normal",shadow); add_theme_stylebox_override("hover",brush); add_theme_stylebox_override("pressed",brush); add_theme_stylebox_override("focus",brush)
	add_theme_color_override("font_color",Color("cfd8d6")); add_theme_color_override("font_hover_color",Color("172126")); add_theme_color_override("font_pressed_color",Color("111b20")); add_theme_color_override("font_focus_color",Color("172126"))
	add_theme_color_override("font_disabled_color",Color("64716f"))
	add_theme_constant_override("outline_size",0)
func _process(delta: float) -> void:
	blend = target if float(Engine.get_meta("punchline_ui_motion",1.0)) <= 0 else lerpf(blend,target,1-exp(-delta*16)); queue_redraw()
func _draw() -> void:
	if blend > .01: draw_line(Vector2(22,size.y-9),Vector2(22+(size.x-44)*blend,size.y-9),Color(.6,.72,.68,.7*blend),1,true)

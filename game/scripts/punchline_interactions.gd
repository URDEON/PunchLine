extends "res://scripts/urban_arena.gd"
# Conserva los ejercicios E; la puerta de tránsito pertenece al laboratorio viejo.
func setup(host: Node3D, terrain: Node3D) -> void:
	game = host; arena = terrain; name = "PunchLineExercises"
	expansion = preload("res://scripts/district_expansion.gd").new(); add_child(expansion); expansion.game = game
	# Old launch platform, breakable panes and terminals belonged to the removed city.
	# Keep the interaction adapter API without placing props on District500 masks.
	# No crear edificios, carreteras o muros del mapa anterior.
	var layer := CanvasLayer.new(); add_child(layer)
	prompt = Label.new(); layer.add_child(prompt)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -270; prompt.offset_right = 270; prompt.offset_top = -85; prompt.offset_bottom = -62
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size",16); prompt.hide()

func station(id: String, caption: String, _point: Vector3) -> void:
	if id == "gate": return
	var positions := {"guard":Vector3(0,.15,-35),"duel":Vector3(0,.15,-29),"route":Vector3(0,.15,-23),"lighting":Vector3(0,.15,3),"reset_glass":Vector3(0,.15,-16)}
	super.station(id,caption,positions[id])

extends Control
var wheel: Control
func _draw() -> void:
	if wheel == null: return
	for i in range(wheel.host.presentation.emote_entries().size()):
		draw_colored_polygon(wheel.segment(i),Color(.65,.84,.93,.35 if i == wheel.selected else .13))

extends Control
var host: Node3D
var selected := -1
var radius := 180.0
func setup(game: Node3D) -> void:
	host = game; mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)

func _draw() -> void:
	var center := size*.5
	radius = minf(190,minf(size.x,size.y)*.33)
	draw_rect(Rect2(Vector2.ZERO,size),Color(.02,.025,.05,.9))
	var font := ThemeDB.fallback_font
	for i in range(6):
		var polygon := PackedVector2Array()
		var start := -PI*.5+TAU*i/6+.035
		var end := start+TAU/6-.07
		for k in range(17): polygon.append(center+Vector2.from_angle(lerpf(start,end,k/16.0))*radius)
		for k in range(16,-1,-1): polygon.append(center+Vector2.from_angle(lerpf(start,end,k/16.0))*radius*.38)
		draw_colored_polygon(polygon,Color("55445f") if i == selected else Color("202330"))
		draw_polyline(polygon,Color("d7ba7b") if i == selected else Color("4d425d"),1.5,true)
		var point := center+Vector2.from_angle((start+end)*.5)*radius*.66
		draw_string(font,point+Vector2(-6,-15),str(i+1),HORIZONTAL_ALIGNMENT_CENTER,-1,18,Color("d7ba7b"))
		# Siluetas de gesto; etiquetas completas debajo evitan depender del icono.
		draw_circle(point+Vector2(0,0),5,Color("e6dce9"),false,1.6,true)
		draw_line(point+Vector2(0,5),point+Vector2(0,21),Color("e6dce9"),2,true)
		draw_line(point+Vector2(0,10),point+Vector2(-13,6+i*2),Color("e6dce9"),2,true)
		draw_line(point+Vector2(0,10),point+Vector2(13,-4+i*4),Color("e6dce9"),2,true)
		draw_line(point+Vector2(0,21),point+Vector2(-9,32),Color("e6dce9"),2,true)
		draw_line(point+Vector2(0,21),point+Vector2(10,29),Color("e6dce9"),2,true)
	draw_string(font,center+Vector2(-45,-8),"EMOTES",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("e6dce9"))
	draw_string(font,center+Vector2(-30,15),"B / ESC",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("9b95aa"))
	var title: String = host.presentation.emote_entries()[selected].name if selected >= 0 else "Elige un gesto · teclas 1–6 o clic"
	var title_width := font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x
	draw_string(font,Vector2(center.x-title_width*.5,center.y+radius+35),title,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("e7d3a9"))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var offset: Vector2 = event.position-size*.5
		selected = posmod(int(floor((offset.angle()+PI*.5)/ (TAU/6))),6) if offset.length() > radius*.38 and offset.length() < radius else -1
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and selected >= 0:
		host.interface.choose_emote(selected); accept_event()

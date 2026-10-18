extends Control
## Cabina original de PunchLine; datos del controlador, sin cámara o mundo adicional.
var host: Node3D
var clock := 0.0
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	clock += delta; queue_redraw()
func poly(points: Array,color: Color) -> void:
	var vertices := PackedVector2Array()
	for p in points: vertices.append(Vector2(p[0]*size.x,p[1]*size.y))
	draw_colored_polygon(vertices,color)
func label_at(position: Vector2,value: String,color: Color,font_size: int = 14) -> void:
	draw_string(ThemeDB.fallback_font,position,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _draw() -> void:
	if not is_instance_valid(host): return
	var steel := Color("18252b"); var dark := Color("091115"); var edge := Color("607679"); var cyan := Color("a1ebee")
	# Vigas en perspectiva: capas con biseles, volumen en esquinas, centro libre.
	poly([[0,0],[1,0],[.94,.045],[.72,.055],[.67,.035],[.33,.035],[.28,.055],[.06,.045]],dark)
	poly([[0,0],[.055,.04],[.11,.16],[.065,.47],[.04,.82],[0,.94]],dark)
	poly([[1,0],[.945,.04],[.89,.16],[.935,.47],[.96,.82],[1,.94]],dark)
	poly([[.015,.08],[.043,.10],[.077,.19],[.039,.62],[.017,.62]],steel)
	poly([[.985,.08],[.957,.10],[.923,.19],[.961,.62],[.983,.62]],steel)
	poly([[0,1],[0,.91],[.13,.945],[.24,.98],[.76,.98],[.87,.945],[1,.91],[1,1]],dark)
	for side in [0,1]:
		var x := .055 if side == 0 else .945
		draw_line(Vector2(x*size.x,.10*size.y),Vector2((x+(.025 if side==0 else -.025))*size.x,.20*size.y),edge,2,true)
		for i in range(4):
			var point := Vector2((.025 if side==0 else .975)*size.x,(.28+i*.095)*size.y)
			draw_circle(point,3,Color("0a0f12")); draw_arc(point,3,0,TAU,12,edge,1,true)
	var center := size*.5
	for sign_value in [-1,1]:
		draw_line(center+Vector2(sign_value*13,-7),center+Vector2(sign_value*21,-7),cyan,1,true)
		draw_line(center+Vector2(sign_value*21,-7),center+Vector2(sign_value*21,7),cyan,1,true)
	draw_circle(center,1.5,cyan)
	var speed := Vector2(host.player.velocity.x,host.player.velocity.z).length()*3.6
	var small := size.x < 800; var font_size := 11 if small else 14
	var base := Vector2(size.x*.34,size.y*.91)
	label_at(base,"SENTINEL  /  PILOTO CONECTADO",cyan,font_size)
	label_at(base+Vector2(0,20),"%.1f KM/H    ESTABILIDAD %.1f%%" % [speed,clampf(host.hp/maxf(1,host.max_hp)*100,0,100)],Color("c1c9c9"),font_size)
	var combat: Node = host.fusion.combat
	var mode := "EN LÍNEA"
	if combat.current.get("id","") == "cannon": mode = "APUNTANDO / SOLTAR 1" if combat.cannon_phase == "hold" else "REPLEGANDO"
	elif combat.cooldowns[0] > 0: mode = "RECARGA %.1f" % combat.cooldowns[0]
	label_at(Vector2(size.x*.61,size.y*.16),"CAÑÓN  /  "+mode,cyan,font_size)
	# Nivel de horizonte derivado de la cámara; no falsea la puntería.
	var pitch: float = host.camera.rotation.x
	for i in range(-2,3):
		var y := center.y+float(i)*30+pitch*45
		if absf(y-center.y) > 85: continue
		draw_line(Vector2(center.x-80,y),Vector2(center.x-64,y),Color(.5,.8,.82,.35),1,true)
		draw_line(Vector2(center.x+64,y),Vector2(center.x+80,y),Color(.5,.8,.82,.35),1,true)

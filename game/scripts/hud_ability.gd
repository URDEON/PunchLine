@static_unload
extends Control
var artwork: Texture2D
var _artwork_key := ""
static var artwork_cache: Dictionary = {}
static var artwork_loads := 0
static var live_cards := 0
var key_font_size := -1
func _enter_tree() -> void: live_cards += 1
func _exit_tree() -> void:
	live_cards -= 1
	if live_cards <= 0: artwork_cache.clear()
const Ink := preload("res://scripts/hud_ink.gd")
const SHAPES := [
	{"points":[[166,126],[196,76],[322,20],[474,95],[440,139],[310,185],[203,156]],"header":[[196,76],[322,20],[474,95],[456,120],[322,51],[185,102]],"key":[[445,80],[474,95],[456,120],[427,105]],"title":[219,76],"rotation":-0.39,"number":[447,93],"icon":[218,101,180,65],"detail":[291,154]},
	{"points":[[12,178],[143,134],[193,172],[151,300],[34,320],[0,224]],"header":[[12,178],[143,134],[163,150],[22,199]],"key":[[163,150],[193,172],[183,197],[153,175]],"title":[33,169],"rotation":-0.32,"number":[170,165],"icon":[27,208,133,86],"detail":[40,296]},
	{"points":[[201,190],[373,147],[453,253],[409,328],[234,310],[160,290]],"header":[[201,190],[373,147],[389,172],[194,215]],"key":[[373,147],[393,174],[383,193],[362,166]],"title":[220,190],"rotation":-0.22,"number":[373,167],"icon":[214,226,162,72],"detail":[275,301]},
	{"points":[[457,165],[520,135],[609,181],[580,291],[481,316],[435,237]],"header":[[457,165],[520,135],[609,181],[599,204],[520,159],[469,186]],"key":[[580,166],[609,181],[599,204],[570,190]],"title":[480,171],"rotation":-0.34,"number":[587,179],"icon":[481,210,96,77],"detail":[490,287]}
]
var index := 0
var outline := PackedVector2Array()
var header := PackedVector2Array()
var corner := PackedVector2Array()
var title_label: Label
var key_label: Label
var detail_label: Label
var icon_kind := "projection"
var cooldown := 0.0
var cooldown_total := 1.0
var unavailable := false
var active := false
var origin := Vector2.ZERO
var icon_rect: Rect2
var holographic := false
var ink_layout: Dictionary = {}
var holo_compact := false

func points(source: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in source: result.append(Vector2(p[0],p[1])-origin)
	return result

func text_node(text: String, pos: Vector2, font_size: int) -> Label:
	var node := Label.new()
	add_child(node)
	node.text = text
	node.position = pos-origin
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",Ink.PAPER)
	node.add_theme_color_override("font_outline_color",Ink.DARK)
	node.add_theme_constant_override("outline_size",3)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func setup(number: int) -> void:
	index = number
	var data: Dictionary = SHAPES[index]
	# La pieza central baja un poco para conservar los separadores del boceto.
	if index == 2:
		data = data.duplicate(true)
		for field in ["points","header","key"]:
			for p in data[field]: p[1] += 24
		for field in ["title","number","detail","icon"]: data[field][1] += 24
	var global_points := PackedVector2Array()
	for p in data.points: global_points.append(Vector2(p[0],p[1]))
	var minimum := global_points[0]
	var maximum := minimum
	for p in global_points:
		minimum = minimum.min(p)
		maximum = maximum.max(p)
	origin = minimum
	position = minimum
	size = maximum-minimum
	outline = points(data.points)
	header = points(data.header)
	corner = points(data.key)
	icon_rect = Rect2(Vector2(data.icon[0],data.icon[1])-origin,Vector2(data.icon[2],data.icon[3]))
	title_label = text_node(["Proyección","Counter","Golpe veloz","Patada"][index],Vector2(data.title[0],data.title[1]),22)
	title_label.rotation = data.rotation
	title_label.position.y -= 11 if index == 0 else (6 if index == 2 else (17 if index == 3 else 0))
	key_label = text_node(str(index+1),Vector2(data.number[0],data.number[1])-Vector2(6,10),20)
	detail_label = text_node("LISTO",Vector2(data.detail[0],data.detail[1])-Vector2(0,7),20)
	mouse_filter = Control.MOUSE_FILTER_PASS
	ink_layout = {"position":position,"size":size,"outline":outline,"header":header,"corner":corner,"icon":icon_rect,"title_pos":title_label.position,"title_rotation":title_label.rotation,"key_pos":key_label.position,"detail_pos":detail_label.position}
	queue_redraw()

func set_holographic(value: bool, compact: bool = false) -> void:
	if value == holographic and (not value or compact == holo_compact): return
	holographic = value; holo_compact = compact
	if value:
		position = Vector2(8+float(index%2)*308,128+floori(float(index)/2)*120) if compact else Vector2(4+index*154,198)
		size = Vector2(300,112) if compact else Vector2(148,162)
		outline = PackedVector2Array([Vector2(8,0),Vector2(size.x-10,0),Vector2(size.x,10),Vector2(size.x,size.y-9),Vector2(size.x-9,size.y),Vector2(0,size.y),Vector2(0,8)])
		header = PackedVector2Array([Vector2(8,0),Vector2(size.x-10,0),Vector2(size.x,10),Vector2(size.x,46),Vector2(0,46),Vector2(0,8)])
		icon_rect = Rect2(180,38,100,61) if compact else Rect2(14,50,120,70)
		title_label.rotation = 0; title_label.position = Vector2(10,7); title_label.size = Vector2(248 if compact else 105,42)
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; title_label.add_theme_font_size_override("font_size",22 if compact else 20)
		key_label.position = Vector2(size.x-27,9)
		detail_label.position = Vector2(12,76 if compact else 126); detail_label.size = Vector2(140 if compact else 116,28); detail_label.add_theme_font_size_override("font_size",20)
	else:
		position = ink_layout.position; size = ink_layout.size; outline = ink_layout.outline; header = ink_layout.header; corner = ink_layout.corner; icon_rect = ink_layout.icon
		title_label.position = ink_layout.title_pos; title_label.rotation = ink_layout.title_rotation; title_label.autowrap_mode = TextServer.AUTOWRAP_OFF; title_label.size = Vector2.ZERO; title_label.add_theme_font_size_override("font_size",22)
		key_label.position = ink_layout.key_pos; detail_label.position = ink_layout.detail_pos; detail_label.size = Vector2.ZERO; detail_label.add_theme_font_size_override("font_size",20)
	queue_redraw()

func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point,outline)

func set_state(title: String, key: String, illustration: String, seconds: float, total: float, disabled: bool, detail: String, executing: bool) -> void:
	title_label.text = title
	key_label.text = key if key.length() <= 3 else key.left(3).to_upper()
	var font_size := 20 if key.length() <= 1 else 13
	if font_size != key_font_size:
		key_font_size = font_size
		key_label.add_theme_font_size_override("font_size",font_size)
	icon_kind = illustration
	var art_path := "res://assets/ui/skill_renders/"+illustration+".png"
	# Las tarjetas cambian de estado cada frame, pero no deben recargar la textura.
	if _artwork_key != illustration:
		_artwork_key = illustration
		if not artwork_cache.has(illustration):
			artwork_cache[illustration] = load(art_path) if ResourceLoader.exists(art_path) else null
			artwork_loads += 1
		artwork = artwork_cache[illustration]
	cooldown = maxf(0,seconds)
	cooldown_total = maxf(0.01,total)
	unavailable = disabled
	active = executing
	detail_label.text = ("NO DISP." if disabled else ("%.1f s" % seconds if seconds > 0 else "LISTO")) if holographic else detail
	tooltip_text = title+" · "+key+"\n"+detail
	queue_redraw()

func draw_model() -> Array:
	var border := Ink.GOLD if active else (Color("677182") if unavailable else Ink.EDGE)
	var heading := Color("344052") if unavailable else (Ink.BLUE if cooldown > 0 else Color("314655"))
	var result := [Ink.polygon(outline,Color("121b29ec")),Ink.polygon(header,heading),Ink.polygon(corner,Color("24334b"))]
	for shape in [outline,header,corner]:
		var closed: PackedVector2Array = shape.duplicate()
		closed.append(shape[0])
		result.append({"type":"line","points":closed,"color":border,"width":2.0})
	var illustration: Array = [] if artwork != null else Ink.fit(Ink.drawing(icon_kind),icon_rect)
	if unavailable:
		for item in illustration: item.color = Color("7c899b")
	result.append_array(illustration)
	if unavailable: result.append_array(Ink.fit(Ink.drawing("lock"),Rect2(icon_rect.position+Vector2(8,6),Vector2(24,24))))
	return result

func _draw() -> void:
	if not holographic:
		Ink.paint(self,draw_model())
		paint_artwork()
		return
	var cyan := Color("64e7ff")
	draw_colored_polygon(outline,Color(.015,.06,.08,.86))
	draw_colored_polygon(header,Color(.025,.25,.32,.9) if active else Color(.02,.13,.18,.9))
	var edge := outline.duplicate(); edge.append(outline[0]); draw_polyline(edge,cyan if active else Color(.22,.63,.75,.7),1.4,true)
	var illustration: Array = [] if artwork != null else Ink.fit(Ink.drawing(icon_kind),icon_rect)
	for command in illustration: command.color = Color("4a7583") if unavailable else cyan
	Ink.paint(self,illustration)
	paint_artwork()
	var radius := 19.0
	var point := Vector2(size.x-26,size.y-25)
	draw_texture_rect(preload("res://assets/ui/holo/gauges/gauge_ring_track_128.svg"),Rect2(point-Vector2.ONE*radius,Vector2.ONE*radius*2),false,Color(.6,.85,1,.6))
	var ready := 1-clampf(cooldown/cooldown_total,0,1)
	if ready > .001: draw_arc(point,radius*.68,PI*1.25,PI*1.25+ready*TAU*.75,28,cyan if not unavailable else Color("467281"),2,true)
	if unavailable: Ink.paint(self,Ink.fit(Ink.drawing("lock"),Rect2(icon_rect.position+Vector2(8,6),Vector2(24,24))))

func paint_artwork() -> void:
	if artwork == null: return
	# Poses renderizadas de los modelos reales. La tecla, el nombre y el estado
	# permanecen como texto legible, separados de la imagen.
	var rect := icon_rect.grow(4)
	var tint := Color(.5,.55,.6,.6) if unavailable else Color.WHITE
	var extent := Vector2(artwork.get_size())
	var factor := minf(rect.size.x/extent.x,rect.size.y/extent.y)
	var fitted := extent*factor
	draw_texture_rect(artwork,Rect2(rect.get_center()-fitted*.5,fitted),false,tint)

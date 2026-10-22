extends Control
## Layout guided by the supplied HUD reference, using original vector drawing.
var game: Node3D
var minimap: Control
var hit_time := 0.0
var elapsed := 0.0
const WHITE := Color("e2e8e5")
const CYAN := Color("71c5cf")
const ORANGE := Color("cf885e")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if game.player.unit_id=="soldier":
		minimap = preload("res://ui/military_minimap.gd").new()
		minimap.game = game
		minimap.size = Vector2(190,190)
		add_child(minimap)
	game.player.equipment.fired.connect(_hit)

func _hit(hit: Dictionary) -> void:
	if not hit.is_empty() and hit.collider.has_method("apply_hit"): hit_time = 0.14

func _process(delta: float) -> void:
	hit_time = maxf(0,hit_time-delta)
	elapsed += delta
	if minimap!=null: minimap.position = Vector2(24,size.y-minimap.size.y-24)
	if elapsed>=0.05: elapsed = 0; queue_redraw()

func text(point: Vector2,value: String,font_size: int = 16,color: Color = WHITE) -> void:
	draw_string(ThemeDB.fallback_font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw() -> void:
	if game==null or game.player==null: return
	var body: CharacterBody3D = game.player
	var equipment: Node = body.equipment
	var mid := size.x*0.5
	var score: int = game.objective.score if game.objective!=null else 0
	draw_rect(Rect2(mid-180,18,360,66),Color(0.02,0.04,0.04,0.55))
	text(Vector2(mid-166,39),"AURORA  %03d" % score,15,CYAN)
	text(Vector2(mid+64,39),"UMBRA  000",15,ORANGE)
	draw_line(Vector2(mid-165,48),Vector2(mid-8,48),CYAN,3,true)
	draw_line(Vector2(mid+8,48),Vector2(mid+165,48),ORANGE,3,true)
	text(Vector2(mid-35,74),"A",18,CYAN if game.objective.captured else WHITE)
	text(Vector2(mid-10,73),"PRÁCTICA",12)
	if not game.objective.captured: draw_arc(Vector2(mid-29,67),12,-PI*0.5,-PI*0.5+maxf(0.001,game.objective.progress)*TAU,24,CYAN,2,true)
	var compass := posmod(int(-rad_to_deg(body.view.yaw)),360)
	text(Vector2(mid-20,106),"%03d°" % compass,13)
	var center := size*0.5
	for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]: draw_line(center+direction*4,center+direction*9,WHITE,1,true)
	if hit_time>0:
		for sign_x in [-1.0,1.0]:
			for sign_y in [-1.0,1.0]: draw_line(center+Vector2(sign_x,sign_y)*10,center+Vector2(sign_x,sign_y)*16,CYAN,2,true)
	var corner := Vector2(size.x-252,size.y-120)
	draw_rect(Rect2(corner-Vector2(12,19),Vector2(240,116)),Color(0.025,0.04,0.04,0.72))
	text(corner,equipment.data.display_name,18)
	text(corner+Vector2(0,40),"%02d" % equipment.magazines[equipment.index],40)
	text(corner+Vector2(64,39),"/ %03d  %s" % [equipment.reserves[equipment.data.ammo_type],equipment.data.ammo_type],18)
	text(corner+Vector2(0,67),"R · RECARGAR" if equipment.reload_remaining<=0 else "RECARGANDO %.1f s" % equipment.reload_remaining,13,CYAN)
	if equipment.reload_remaining>0:
		draw_line(corner+Vector2(0,78),corner+Vector2(210*(1-equipment.reload_remaining/equipment.data.reload_seconds),78),CYAN,3)
	if body.unit_id=="soldier":
		var health_origin := Vector2(24,size.y-232)
		text(health_origin,"+ %03d" % body.health.current,20)
		draw_line(health_origin+Vector2(74,-6),health_origin+Vector2(190,-6),Color("4e625e"),4)
		draw_line(health_origin+Vector2(74,-6),health_origin+Vector2(74+116*body.health.current/body.health.maximum,-6),WHITE,4)
		text(Vector2(24,size.y-248),"1 · M4A1    2 · MP5A5",12)
	text(Vector2(24,26),"D500 / "+body.view.mode_label(),12)
	if not body.health.alive: text(center+Vector2(-140,70),"FUERA DE COMBATE · REAPARECIENDO",18,ORANGE)

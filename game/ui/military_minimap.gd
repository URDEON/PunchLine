extends Control
## Actual District500 vector layers, centered on the player's current position.
var game: Node3D
var rings: Array[Dictionary] = []
var elapsed := 0.0
const CYAN := Color("77cbd0")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/vector_meshes.json"))
	for feature in map.features:
		for original in feature.rings:
			var points := PackedVector2Array()
			for point in original: points.append(Vector2(point[0],point[1]))
			rings.append({"points":points,"color":Color("65716c") if feature.layer=="Lots" else Color("a5aeaa")})

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed>=0.1: elapsed = 0; queue_redraw()

func map_point(world: Vector3) -> Vector2:
	var player: Vector3 = game.player.global_position
	return size*0.5+(Vector2(world.x,world.z)-Vector2(player.x,player.z))*1.7

func _draw() -> void:
	if game==null: return
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.035,0.055,0.055,0.82))
	var center: Vector3 = game.player.global_position
	var offset := Vector2(center.x,center.z)*1.7
	for ring in rings:
		var points := PackedVector2Array()
		for point in ring.points: points.append(point*1.7-offset+size*0.5)
		draw_polyline(points,ring.color*Color(1,1,1,0.55),1,true)
	for target in game.targets:
		var point := map_point(target.global_position)
		draw_circle(point,3,Color("d28a56"))
	if game.objective!=null:
		var point := map_point(game.objective.global_position)
		draw_circle(point,7,CYAN if game.objective.captured else Color("dad6b1"),false,2,true)
		draw_string(ThemeDB.fallback_font,point+Vector2(-4,5),"A",HORIZONTAL_ALIGNMENT_LEFT,-1,12,CYAN)
	var yaw: float = game.player.view.yaw
	var arrow := PackedVector2Array([Vector2(0,-8),Vector2(-5,6),Vector2(0,3),Vector2(5,6)])
	for i in range(arrow.size()): arrow[i] = arrow[i].rotated(-yaw)+size*0.5
	draw_colored_polygon(arrow,CYAN)
	draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color("a3bab7"),false,1)
	draw_string(ThemeDB.fallback_font,Vector2(size.x*0.5-5,17),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)

extends RefCounted
# Trazos vectoriales compartidos por el HUD y su exportación de diseño.
# Coordenadas normalizadas a 100×100; figuras simples del boceto, sin imágenes generadas.
const PAPER := Color("eef2f5")
const EDGE := Color("9eacc0")
const BLUE := Color("3589cd")
const MINT := Color("91dcc5")
const GOLD := Color("e6cc89")
const DARK := Color("121b29")

static func path(points: Array, color: Color = PAPER, width: float = 2.2, closed: bool = false) -> Dictionary:
	var packed := PackedVector2Array()
	for p in points: packed.append(Vector2(p[0],p[1]))
	if closed and not packed.is_empty(): packed.append(packed[0])
	return {"type":"line","points":packed,"color":color,"width":width}

static func circle(center: Vector2, radius: float, color: Color = PAPER, filled: bool = false, width: float = 2.2) -> Dictionary:
	return {"type":"circle","center":center,"radius":radius,"color":color,"filled":filled,"width":width}

static func polygon(points: PackedVector2Array, color: Color) -> Dictionary:
	return {"type":"polygon","points":points,"color":color}

static func figure(head: Vector2, joints: Array, radius: float = 6.0) -> Array:
	return [circle(head,radius),path(joints)]

# Dos siluetas de criatura; las habilidades conservan trazos simples del boceto.
static func creature(evolved: bool) -> Array:
	if not evolved:
		return [path([[9,77],[16,61],[31,61],[43,48],[53,29],[66,22],[81,29],[86,43],[77,56],[63,59],[52,70],[33,82],[9,77]],PAPER,2.2),path([[17,62],[22,80]]),path([[31,61],[37,80]]),path([[43,49],[55,65]]),path([[53,32],[68,57]]),circle(Vector2(72,36),3),path([[79,43],[71,49],[63,45]])]
	return [path([[12,78],[26,70],[33,51],[41,39],[40,26],[54,15],[68,23],[76,37],[68,52],[52,56],[46,73],[28,85],[12,78]],PAPER,2.2),path([[41,29],[30,17],[32,33]]),path([[65,25],[79,16],[75,35]]),path([[35,51],[49,61]]),path([[29,64],[44,73]]),path([[19,74],[29,84]]),path([[40,39],[55,32],[71,39]],GOLD),path([[54,15],[55,32],[52,56]],EDGE),circle(Vector2(62,37),3),path([[61,47],[72,47],[69,52]])]

static func drawing(kind: String) -> Array:
	var out: Array = []
	match kind:
		"spider_scan":
			out=[circle(Vector2(50,50),36,MINT),circle(Vector2(50,50),22,MINT),path([[50,14],[50,50],[77,28]],MINT),circle(Vector2(28,62),4,PAPER,true),circle(Vector2(68,62),3,GOLD,true)]
		"spider_cloak":
			out=[circle(Vector2(50,39),13,MINT),path([[37,52],[28,70],[37,87],[63,87],[72,70],[63,52]],MINT),path([[12,14],[88,86]],PAPER,4),path([[14,35],[27,29]],EDGE),path([[74,29],[87,35]],EDGE),path([[9,62],[23,62]],EDGE),path([[77,62],[91,62]],EDGE)]
		"projection":
			out = [path([[8,22],[23,12],[23,76],[8,89]],PAPER,2.2,true),path([[34,22],[46,12],[46,76],[34,89]],PAPER,2.2,true),path([[18,20],[15,39],[20,46],[15,60]]),path([[42,23],[37,37],[44,48],[38,64]]),path([[2,44],[5,49],[1,54]],EDGE),path([[29,33],[32,38],[28,42]],EDGE),path([[49,17],[52,23],[48,27]],EDGE)]
			out += figure(Vector2(65,31),[[65,39],[56,59],[73,65],[88,58]])
			out += [path([[58,50],[49,59]]),path([[61,42],[75,51],[87,43]]),path([[72,65],[65,84],[78,87]]),path([[85,16],[81,21],[87,23]],EDGE)]
		"counter":
			out = [path([[59,10],[90,7],[90,90],[59,93]],PAPER,2.2,true)]
			out += figure(Vector2(30,26),[[30,34],[29,59],[16,77],[27,91]])
			out += [path([[29,44],[42,53],[52,45]]),path([[29,59],[45,73],[50,89]])]
			out += figure(Vector2(75,31),[[75,39],[75,58],[67,77],[69,86]],5)
			out += [path([[74,47],[66,51],[65,40]]),path([[75,58],[84,75],[84,87]]),path([[80,15],[85,12]]),path([[87,21],[92,18]])]
		"rush":
			out = [path([[2,25],[35,25]],EDGE),path([[0,40],[27,40]],EDGE),path([[5,56],[34,56]],EDGE),path([[9,73],[29,73]],EDGE)]
			out += figure(Vector2(61,26),[[61,34],[48,61],[67,63],[57,82],[68,88]])
			out += [path([[55,44],[79,45],[92,42]]),circle(Vector2(95,42),3),path([[50,49],[41,52],[38,43]]),path([[48,61],[32,76],[42,86]])]
		"cannon":
			out = [path([[10,53],[48,53],[48,30],[87,30],[87,52],[48,52],[36,73],[10,73]],PAPER,3,true),path([[88,25],[99,19]],GOLD,3),path([[90,42],[100,42]],GOLD,3),path([[87,59],[99,68]],GOLD,3),circle(Vector2(24,62),8)]
		"ground_slam":
			out = [path([[22,17],[43,17],[43,56],[22,56]],PAPER,3,true),path([[57,17],[78,17],[78,56],[57,56]],PAPER,3,true),path([[10,74],[35,68],[48,82],[64,69],[90,76]],GOLD,3),path([[50,45],[50,66]],EDGE,3)]
		"stomp":
			out = [path([[37,13],[62,13],[62,49],[83,60],[83,73],[30,73],[30,52],[37,49]],PAPER,3,true),path([[10,82],[31,77],[45,89],[61,80],[92,87]],GOLD,3)]
		"ram":
			out = [path([[37,27],[68,20],[87,45],[68,73],[37,64]],PAPER,3,true),path([[5,30],[30,30]],EDGE,3),path([[2,47],[28,47]],GOLD,3),path([[7,65],[30,65]],EDGE,3),path([[48,35],[66,44],[48,56]],GOLD,3)]
		"punch":
			out = figure(Vector2(33,24),[[33,32],[38,59],[24,85],[35,89]],7)
			out += [path([[35,41],[65,42],[85,35]]),circle(Vector2(89,34),7),path([[37,48],[23,53],[16,43]]),path([[38,59],[56,80],[72,84]]),path([[72,15],[82,12]],EDGE),path([[95,19],[99,15]],EDGE)]
		"kick":
			out = figure(Vector2(40,20),[[40,29],[39,58],[27,85],[41,87]],7)
			out += [path([[40,39],[59,47],[77,37]]),path([[39,58],[83,45],[90,27],[39,58]]),path([[40,37],[28,47],[30,57]])]
		"tendril":
			out = drawing("counter")
			out += [path([[35,61],[48,73],[58,62],[47,40],[58,24],[78,26]],GOLD)]
		"speed":
			out = drawing("rush")
			out += [path([[45,9],[37,25],[48,24],[42,39]],GOLD)]
		"domain":
			out = [circle(Vector2(50,48),39),path([[11,48],[89,48]],EDGE),path([[25,20],[38,75],[50,86],[62,75],[75,20]],EDGE),path([[24,77],[38,22],[50,9],[62,22],[76,77]],EDGE)]
		"worm_charge", "evolved_charge":
			out = creature(kind.begins_with("evolved"))
			out += [path([[4,27],[30,27]],EDGE),path([[0,41],[23,41]],EDGE),path([[2,53],[18,53]],EDGE),path([[84,67],[96,55],[87,55]],GOLD)]
		"worm_tendrils", "evolved_tendrils":
			out = fit(creature(kind.begins_with("evolved")),Rect2(0,28,55,65))
			out += figure(Vector2(81,22),[[81,30],[80,52],[71,76],[78,85]],5)
			out += [path([[80,38],[69,45],[63,37]]),path([[80,52],[93,66],[91,81]]),path([[39,55],[58,64],[74,57],[85,40],[93,44],[84,60],[65,64],[48,76]],GOLD),path([[39,64],[53,48],[67,52],[70,39]],PAPER)]
		"worm_speed", "evolved_speed":
			out = creature(kind.begins_with("evolved"))
			out += [path([[2,21],[22,21]],EDGE),path([[0,38],[23,38]],EDGE),path([[1,53],[23,53]],EDGE),path([[88,9],[76,25],[89,25],[80,42]],GOLD),path([[12,92],[42,92],[63,84]],EDGE)]
		"worm_domain", "evolved_domain":
			out = drawing("domain")
			out += fit(creature(kind.begins_with("evolved")),Rect2(23,28,55,53))
		"kogane":
			out = [circle(Vector2(50,39),15,GOLD,true),circle(Vector2(50,39),15),path([[41,24],[37,14],[30,11]]),path([[59,24],[63,14],[70,11]]),circle(Vector2(44,39),2.5,DARK,true),circle(Vector2(56,39),2.5,DARK,true),path([[34,48],[22,56],[17,75],[29,87],[50,91],[71,87],[83,75],[78,56],[66,48]]),path([[19,65],[9,52],[8,74],[24,90]],GOLD),path([[81,65],[91,52],[92,74],[76,90]],GOLD)]
		"fall": out = [path([[50,15],[50,70],[28,49]]),path([[50,70],[72,49]]),path([[22,86],[78,86]],EDGE)]
		"motion": out = [path([[15,34],[44,34]]),path([[8,50],[37,50]]),path([[15,66],[44,66]]),path([[55,23],[82,50],[55,77]])]
		"form": out = [path([[50,12],[61,36],[86,50],[61,62],[50,87],[39,62],[14,50],[39,36]],PAPER,2.2,true)]
		"guard": out = [circle(Vector2(50,50),33),circle(Vector2(50,50),20)]
		"lock": out = [path([[30,44],[30,27],[38,17],[61,17],[70,27],[70,44]]),path([[23,44],[77,44],[77,86],[23,86]],PAPER,2.2,true),circle(Vector2(50,62),4)]
	return out

static func fit(commands: Array, rectangle: Rect2) -> Array:
	var result: Array = []
	for command in commands:
		var item: Dictionary = command.duplicate()
		if item.has("points"):
			var points := PackedVector2Array()
			for point in item.points: points.append(rectangle.position+point*rectangle.size/100.0)
			item.points = points
		else:
			item.center = rectangle.position+item.center*rectangle.size/100.0
			item.radius *= minf(rectangle.size.x,rectangle.size.y)/100.0
		result.append(item)
	return result

static func paint(target: Control, commands: Array) -> void:
	for item in commands:
		match item.type:
			"polygon": target.draw_colored_polygon(item.points,item.color)
			"line": target.draw_polyline(item.points,item.color,item.width,true)
			"circle": target.draw_circle(item.center,item.radius,item.color,item.filled,-1.0 if item.filled else item.width,true)

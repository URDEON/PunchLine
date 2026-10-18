extends RefCounted
## Punto real más cercano del volumen receptor del mega mecha.
## Los personajes normales conservan los alcances anteriores.
static func point(enemy: Dictionary, source: Vector3) -> Vector3:
	var origin: Vector3 = enemy.body.global_position
	if not bool(enemy.get("mega",false)): return origin+Vector3.UP
	var yaw: float = enemy.get("mega_yaw",0.0)
	var local := (source-origin).rotated(Vector3.UP,-yaw)
	local = local.clamp(Vector3(-1.5,0,-.85),Vector3(1.5,4.0,.85))
	return origin+local.rotated(Vector3.UP,yaw)

static func offset(enemy: Dictionary, source_feet: Vector3) -> Vector3:
	return point(enemy,source_feet+Vector3.UP)-(source_feet+Vector3.UP) if bool(enemy.get("mega",false)) else enemy.body.global_position-source_feet

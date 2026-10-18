extends RefCounted
## Barrido completo de la cápsula: no atraviesa paredes ni techos para subir.
static func prepare(body: CharacterBody3D, delta: float, height: float = .42) -> bool:
	if not body.is_on_floor() or body.velocity.y > .1: return false
	var motion := Vector3(body.velocity.x,0,body.velocity.z)*delta
	if motion.length() < .001: return false
	var wall := KinematicCollision3D.new()
	if not body.test_move(body.global_transform,motion,wall): return false
	if wall.get_normal().dot(Vector3.UP) > .95: return false
	var raised := body.global_transform
	if body.test_move(raised,Vector3.UP*height): return false
	raised.origin.y += height
	var forward := motion+motion.normalized()*.06
	if body.test_move(raised,forward): return false
	raised.origin += forward
	var down := KinematicCollision3D.new()
	if not body.test_move(raised,Vector3.DOWN*(height+.08),down): return false
	# A capsule touching the curb's corner reports a diagonal normal even
	# though the landing surface is flat. Validate that surface separately.
	if down.get_normal().y < .15: return false
	var radius := .32
	for child in body.get_children():
		if child is CollisionShape3D and child.shape is CapsuleShape3D: radius = child.shape.radius
	var sample := body.global_position+motion.normalized()*(radius+.08)
	var ray := PhysicsRayQueryParameters3D.create(sample+Vector3.UP*(height+.02),sample-Vector3.UP*.08,1)
	ray.exclude = [body.get_rid()]
	var landing := body.get_world_3d().direct_space_state.intersect_ray(ray)
	if landing.is_empty() or landing.normal.y < .71: return false
	var rise: float = float(landing.position.y)-body.global_position.y
	if rise < .015 or rise > height: return false
	body.global_position.y += rise+.003
	body.velocity.y = 0
	return true

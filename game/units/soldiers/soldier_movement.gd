extends Node
## Capsule movement, full-volume clearance and the existing swept stair helper.
signal landed(speed: float)
const Steps = preload("res://scripts/terrain_steps.gd")
var crouched := false
var coyote := 0.0
var jump_buffer := 0.0
var locomotion_speed := 0.0
var clearance := CapsuleShape3D.new()
var query := PhysicsShapeQueryParameters3D.new()

func step(body: CharacterBody3D,command: RefCounted,delta: float) -> void:
	var tuning: Resource = body.tuning
	var was_grounded := body.is_on_floor()
	coyote = 0.1 if was_grounded else maxf(0,coyote-delta)
	jump_buffer = 0.12 if command.jump else maxf(0,jump_buffer-delta)
	if command.crouch:
		crouched = true
	elif crouched:
		clearance.height = tuning.standing_height
		clearance.radius = tuning.radius
		query.shape = clearance
		query.transform = Transform3D(Basis.IDENTITY,body.global_position+Vector3.UP*(tuning.standing_height*0.5+0.025))
		query.collision_mask = 1
		query.exclude = [body.get_rid()]
		crouched = not body.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
	var height: float = tuning.crouching_height if crouched else tuning.standing_height
	body.collider.shape.height = height
	body.collider.position.y = height*0.5
	var direction := Vector3(command.move.x,0,command.move.y).rotated(Vector3.UP,command.yaw)
	if direction.length_squared() > 1: direction = direction.normalized()
	var speed: float = tuning.run_speed
	if command.sprint and command.move.y < -0.1: speed = tuning.sprint_speed
	if command.walk: speed = tuning.walk_speed
	if crouched: speed = tuning.crouch_speed
	var acceleration: float = tuning.acceleration if direction.length_squared()>0.001 else tuning.braking
	if not was_grounded: acceleration *= 0.35
	body.velocity.x = move_toward(body.velocity.x,direction.x*speed,acceleration*delta)
	body.velocity.z = move_toward(body.velocity.z,direction.z*speed,acceleration*delta)
	body.rotation.y = command.yaw
	if jump_buffer>0 and coyote>0 and not crouched:
		body.velocity.y = tuning.jump_speed
		jump_buffer = 0
		coyote = 0
	else:
		body.velocity.y -= tuning.gravity*delta
	Steps.prepare(body,delta,tuning.max_step_height)
	var fall_speed := body.velocity.y
	body.move_and_slide()
	locomotion_speed = Vector2(body.velocity.x,body.velocity.z).length()
	if not was_grounded and body.is_on_floor() and fall_speed < -1.5: landed.emit(-fall_speed)

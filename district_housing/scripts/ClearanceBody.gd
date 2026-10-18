extends CharacterBody3D
## Adapter for measured capsule bodies. Never scales the mesh or disables collision.
## Real rig IK/skill blending must be connected by PunchLine's character controller.
signal posture_changed(crouch_fraction: float)
@export var standing_height := 0.0
@export var crouched_height := 0.0
@export var body_width := 0.0
@export var transition_speed := 2.0
var current_height := 0.0
var crouch_requested := false
var clear_seconds := 0.0
var collision: CollisionShape3D
var probe: ShapeCast3D

func _ready() -> void:
	assert(body_width > 0 and crouched_height >= body_width and standing_height > crouched_height)
	collision = CollisionShape3D.new()
	collision.shape = CapsuleShape3D.new()
	collision.shape.radius = body_width/2
	add_child(collision)
	probe = ShapeCast3D.new()
	probe.shape = CapsuleShape3D.new()
	probe.shape.radius = body_width/2
	probe.target_position = Vector3.ZERO
	probe.add_exception(self)
	add_child(probe)
	current_height = standing_height
	apply_height()

func fits(height: float, offset := Vector3.ZERO) -> bool:
	probe.shape.height = height
	probe.position = offset + Vector3(0,height/2+0.02,0)
	probe.force_shapecast_update()
	return not probe.is_colliding()

func can_fuse(fused_shape: Shape3D, at: Transform3D) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = fused_shape
	query.transform = at
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func apply_height() -> void:
	collision.shape.height = current_height
	collision.position.y = current_height/2
	posture_changed.emit((standing_height-current_height)/(standing_height-crouched_height))

func update_posture(delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return # Host controller must replicate authoritative height/transform to clients.
	var can_stand := fits(standing_height)
	clear_seconds = clear_seconds + delta if can_stand else 0.0
	var target := crouched_height if crouch_requested or clear_seconds < 0.2 else standing_height
	var proposed := move_toward(current_height,target,transition_speed*delta)
	if proposed <= current_height or fits(proposed):
		current_height = proposed
		apply_height()

func move_authoritative(wanted_velocity: Vector3, delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	update_posture(delta)
	velocity = wanted_velocity
	# Dash and combat supply desired velocity; move_and_slide still enforces wall/door width.
	move_and_slide()

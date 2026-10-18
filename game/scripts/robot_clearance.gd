extends Node
## Physical posture is authoritative; renderers only consume its compression.
const FUSED_MIN_HEIGHT := 2.7
var game: Node3D
var blend := 0.0
var current_height := 0.0
var full_height := 2.0
var minimum := 1.3
var target_height := 2.0
var last_check := 0.0
var capsule: CapsuleShape3D
var probe := CapsuleShape3D.new()
var shape_query := PhysicsShapeQueryParameters3D.new()
var checks := 0
var expansion_clear_time := 0.0
var fused_before := false

func setup(host: Node3D) -> void:
	game = host
	shape_query.shape = probe
	shape_query.collision_mask = 1
	shape_query.margin = .015

func restore() -> void:
	blend = 0; current_height = 0; target_height = 2; last_check = 0; expansion_clear_time = 0
	capsule = null
	if is_instance_valid(game) and is_instance_valid(game.fusion.sequence) and game.fusion.sequence.articulation != null:
		game.fusion.sequence.articulation.crouch_weight = 0

func collision_node() -> CollisionShape3D:
	return game.robots.naoya.get("collision")

func tick(delta: float) -> void:
	checks = 0
	if not is_instance_valid(game) or not is_instance_valid(game.player): return
	if not game.robots.active and not game.fusion.fused:
		if capsule != null: restore()
		return
	if game.fusion.cinematic or game.paused or game.player_ragdoll or game.physical_ragdoll.active: return
	var col := collision_node()
	if not is_instance_valid(col) or not col.shape is CapsuleShape3D: return
	var fused: bool = game.fusion.fused
	full_height = 4.0 if fused else 2.0
	minimum = FUSED_MIN_HEIGHT if fused else 1.3
	# Respawn and fusion replace the shape even if its radius is unchanged.
	if capsule != col.shape or fused_before != fused:
		capsule = col.shape.duplicate()
		col.shape = capsule
		current_height = full_height; target_height = full_height
		blend = 0; last_check = 0; fused_before = fused
	minimum = maxf(minimum,capsule.radius*2+.04)
	last_check -= delta
	var inspect_ahead := last_check <= 0
	if inspect_ahead:
		last_check = .05
	var safe_height := available_height(inspect_ahead)
	target_height = safe_height if inspect_ahead else minf(target_height,safe_height)
	# Shrink before move_and_slide: an overlapping tall capsule is otherwise
	# depenetrated DOWN into the ground by the ceiling contact.
	expansion_clear_time = expansion_clear_time + delta if target_height > current_height+.01 else 0.0
	var expansion_target := target_height if expansion_clear_time >= .15 else current_height
	var proposed := target_height if target_height < current_height else move_toward(current_height,expansion_target,delta*3.5)
	if proposed > current_height+.0001 and not volume_free(proposed): proposed = current_height
	current_height = clampf(proposed,minimum,full_height)
	capsule.height = current_height
	col.position.y = current_height*.5
	blend = clampf((full_height-current_height)/maxf(.01,full_height-minimum),0,1)
	if fused and is_instance_valid(game.fusion.sequence) and game.fusion.sequence.articulation != null:
		game.fusion.sequence.articulation.crouch_weight = blend

func available_height(include_ahead: bool = true) -> float:
	var feet: Vector3 = game.player.global_position
	var velocity: Vector3 = game.player.velocity; velocity.y = 0
	var direction: Vector3 = velocity.normalized() if velocity.length() > .1 else game.movement().normalized()
	direction.y = 0
	var ahead := direction*(capsule.radius+.35+minf(.5,velocity.length()*.08))
	var side := Vector3(-direction.z,0,direction.x)*capsule.radius*.75
	if side.length() < .01: side = Vector3.RIGHT*capsule.radius*.75
	var result := full_height
	var offsets: Array[Vector3] = [Vector3.ZERO,side,-side]
	if include_ahead:
		# Probe the swept approach, not only its endpoint: a thin lintel can
		# lie between the feet and the old single look-ahead ray.
		for fraction in [.25,.5,.75,1.0]:
			var offset: Vector3 = ahead*fraction
			offsets.append_array([offset,offset+side,offset-side])
	for offset in offsets:
		var origin: Vector3 = feet+offset+Vector3.UP*.12
		var ray := PhysicsRayQueryParameters3D.create(origin,feet+offset+Vector3.UP*(full_height+.15),1)
		ray.exclude = [game.player.get_rid()]
		var hit := game.get_world_3d().direct_space_state.intersect_ray(ray); checks += 1
		if not hit.is_empty() and hit.normal.y < -.35:
			var ceiling: float = hit.position.y-feet.y-.10
			if ceiling >= minimum: result = minf(result,ceiling)
	return clampf(result,minimum,full_height)

func volume_free(height: float) -> bool:
	probe.radius = capsule.radius; probe.height = height
	shape_query.transform = Transform3D(Basis.IDENTITY,game.player.global_position+Vector3.UP*(height*.5+.03))
	shape_query.exclude = [game.player.get_rid()]
	checks += 1
	return game.get_world_3d().direct_space_state.intersect_shape(shape_query,1).is_empty()

func apply_base_pose() -> void:
	pass # Applied once by robot_procedural_motion after original animation.

func snapshot() -> Dictionary:
	return {"height":current_height,"full":full_height,"blend":blend}

func apply_snapshot(value: Dictionary) -> void:
	current_height = float(value.get("height",2)); full_height = float(value.get("full",2))
	blend = clampf(float(value.get("blend",0)),0,1)
	if is_instance_valid(game.fusion.sequence) and game.fusion.sequence.articulation != null:
		game.fusion.sequence.articulation.crouch_weight = blend
	var col := collision_node()
	if is_instance_valid(col) and col.shape is CapsuleShape3D and current_height > .1:
		col.shape.height = maxf(col.shape.radius*2,current_height); col.position.y = current_height*.5

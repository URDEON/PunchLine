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
var contacts: Dictionary = {}
var pressure := 0.0

func setup(host: Node3D) -> void:
	game = host
	shape_query.shape = probe
	shape_query.collision_mask = 1
	shape_query.margin = .015

func restore() -> void:
	blend = 0; current_height = 0; target_height = 2; last_check = 0; expansion_clear_time = 0
	capsule = null
	contacts.clear(); pressure = 0
	if is_instance_valid(game) and is_instance_valid(game.fusion.sequence) and game.fusion.sequence.articulation != null:
		game.fusion.sequence.articulation.crouch_weight = 0
		game.fusion.sequence.articulation.confinement_state = {}

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
	if inspect_ahead: sample_contacts()
	var wanted: float = blend*.65
	for contact in contacts.values(): wanted = maxf(wanted,float(contact.weight))
	pressure = lerpf(pressure,wanted,1-exp(-delta*9))
	if fused and is_instance_valid(game.fusion.sequence) and game.fusion.sequence.articulation != null:
		game.fusion.sequence.articulation.crouch_weight = blend
		game.fusion.sequence.articulation.confinement_state = contact_state()

func sample_contacts() -> void:
	contacts.clear()
	if not game.fusion.fused: return
	var feet: Vector3 = game.player.global_position
	# The assembled source rig faces the opposite axis to the player model.
	# Sample from its actual shoulders so contacts reach the matching hand.
	var art: Node3D = game.fusion.sequence.articulation
	var right: Vector3 = art.global_basis.x.normalized()
	var forward: Vector3 = art.global_basis.z.normalized()
	for side in ["Der","Izq"]:
		var sign_side := 1.0 if side=="Der" else -1.0
		var best: Dictionary = {}
		var closest := 2.35
		for fraction in [.60,.76]:
			for lead in [0.0,.48]:
				var origin: Vector3 = feet+Vector3.UP*current_height*fraction
				var direction: Vector3 = (right*sign_side+forward*lead).normalized()
				var hit: Dictionary = contact_ray(origin,origin+direction*2.35)
				if not hit.is_empty() and absf(hit.normal.y)<.45:
					var distance: float = origin.distance_to(hit.position)
					if distance<closest:
						closest=distance
						best={"point":hit.position,"normal":hit.normal,"weight":1-smoothstep(1.55,2.25,distance),"kind":"wall"}
		if not best.is_empty() and best.weight>.01: contacts[side]=best
	# An overhead ray supplies a palm target on the actual ceiling.
	# Prefer the free left hand under a low roof.
	var origin: Vector3 = feet-right*.80+forward*.15+Vector3.UP*.45
	var roof: Dictionary = contact_ray(origin,origin+Vector3.UP*(full_height+.1))
	if not roof.is_empty() and roof.normal.y<-.5:
		var weight: float = clampf((full_height+.15-(roof.position.y-feet.y))/1.3,0,1)
		if weight>.12 and not contacts.has("Izq"):
			contacts.Izq={"point":roof.position,"normal":roof.normal,"weight":weight,"kind":"ceiling"}

func contact_ray(from: Vector3,to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from,to,1)
	query.exclude=[game.player.get_rid()]; checks+=1
	return game.get_world_3d().direct_space_state.intersect_ray(query)

func contact_state() -> Dictionary:
	return {"contacts":contacts.duplicate(true),"pressure":pressure,"compression":blend}

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
	# Keep the back of the capsule compressed until it clears a stairwell lip.
	# Only probing the approach lets the head expand into the slab behind it.
	var back:Vector3=-direction*capsule.radius*.85
	offsets.append_array([back,back+side*.7,back-side*.7])
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
	return {"height":current_height,"full":full_height,"blend":blend,"contacts":contacts.duplicate(true),"pressure":pressure}

func apply_snapshot(value: Dictionary) -> void:
	current_height = float(value.get("height",2)); full_height = float(value.get("full",2))
	blend = clampf(float(value.get("blend",0)),0,1)
	contacts = value.get("contacts",{}).duplicate(true)
	pressure = clampf(float(value.get("pressure",0)),0,1)
	if is_instance_valid(game.fusion.sequence) and game.fusion.sequence.articulation != null:
		game.fusion.sequence.articulation.crouch_weight = blend
		game.fusion.sequence.articulation.confinement_state = contact_state()
	var col := collision_node()
	if is_instance_valid(col) and col.shape is CapsuleShape3D and current_height > .1:
		col.shape.height = maxf(col.shape.radius*2,current_height); col.position.y = current_height*.5

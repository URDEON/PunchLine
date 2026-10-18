extends Node
const BAKED_HULLS = preload("res://assets/physics/contact_hulls_v0924.tres")
var hull_profile := ""
# Equivalente local de Create Physical Skeleton; nunca modifica la escena importada.
var skeleton: Skeleton3D
var physics_skeleton: Skeleton3D
var simulator: PhysicalBoneSimulator3D
var holder: Node3D
var actor: Node3D
var animator: AnimationPlayer
var animation_tree: AnimationTree
var bodies: Array[PhysicalBone3D] = []
var active := false
var saved_holder := Transform3D.IDENTITY
var saved_layer := 0
var saved_mask := 0
var recovering := 0.0
var recovery_rotations: Array[Quaternion] = []
var recovery_positions: Array[Vector3] = []
var initialized := false
var paused := false
var paused_velocities: Array[Dictionary] = []
var rest_positions: Array[Vector3] = []
var pelvis_index := -1
var joints: Array[Joint3D] = []
var joint_profiles: Dictionary = {}
var rest_rotations: Array[Quaternion] = []
var saved_interpolation := Node.PHYSICS_INTERPOLATION_MODE_INHERIT
var contact_hulls: Dictionary = {}
var visual_ground_lift := 0.0
var last_impact: Dictionary = {}

func pelvis_name() -> String: return "B_Pelvis"
func torso_name() -> String: return "B_Spine2"
func segment_fallback() -> float: return 22.0
func physical_definitions() -> Array:
	var definitions: Array = [["B_Pelvis","B_Spine",16.0,8.0],["B_Spine2","B_Neck",17.0,12.0],["B_Head","",15.0,4.0]]
	for side in ["L","R"]:
		definitions.append_array([["B_"+side+"_UpperArm","B_"+side+"_Forearm",8.0,2.0],["B_"+side+"_Forearm","B_"+side+"_Hand",6.5,1.5],["B_"+side+"_Thigh","B_"+side+"_Calf",11.0,5.0],["B_"+side+"_Calf","B_"+side+"_Foot",8.0,3.0],["B_"+side+"_Foot","B_"+side+"_Toe0",7.0,1.0]])
	return definitions
func hinge_bone(name: String) -> bool: return "Forearm" in name or "Calf" in name
func knee_bone(name: String) -> bool: return "Calf" in name
func hip_bone(name: String) -> bool: return "Thigh" in name
func right_elbow_bone(name: String) -> bool: return name == "B_R_Forearm"
func dynamic_translation(index: int) -> bool: return index == pelvis_index
func joint_parent(index: int, physical: Dictionary) -> int:
	var parent := physics_skeleton.get_bone_parent(index)
	while parent >= 0 and not physical.has(parent): parent = physics_skeleton.get_bone_parent(parent)
	return parent

func setup(owner_actor: Node3D, visual_holder: Node3D, sk: Skeleton3D, player: AnimationPlayer, tree: AnimationTree = null) -> void:
	actor = owner_actor; holder = visual_holder; skeleton = sk; animator = player; animation_tree = tree
	pelvis_index = skeleton.find_bone(pelvis_name())
	for i in range(skeleton.get_bone_count()):
		rest_positions.append(skeleton.get_bone_rest(i).origin)
		rest_rotations.append(skeleton.get_bone_rest(i).basis.orthonormalized().get_rotation_quaternion())
	var profiles: Dictionary = BAKED_HULLS.get_meta("profiles",{})
	var profile: Dictionary = profiles.get(hull_profile,{})
	var compatible: bool = not profile.is_empty() and profile.bones.size() == skeleton.get_bone_count()
	if compatible:
		for i in range(skeleton.get_bone_count()):
			if profile.bones[i] != skeleton.get_bone_name(i): compatible = false; break
	if compatible: contact_hulls = profile.hulls.duplicate()
	else: prepare_contact_hulls(skeleton)
	# Copia local del esqueleto en metros: las formas físicas no heredan la escala .01 del GLB.
	var units_to_meters := skeleton.global_basis.get_scale().x
	physics_skeleton = Skeleton3D.new(); physics_skeleton.name = "MeterPhysicalSkeleton"
	physics_skeleton.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	holder.add_child(physics_skeleton)
	physics_skeleton.global_transform = Transform3D(skeleton.global_basis.orthonormalized(),skeleton.global_position)
	for i in range(skeleton.get_bone_count()):
		physics_skeleton.add_bone(skeleton.get_bone_name(i))
		physics_skeleton.set_bone_parent(i,skeleton.get_bone_parent(i))
		var rest := skeleton.get_bone_rest(i); rest.origin *= units_to_meters
		physics_skeleton.set_bone_rest(i,rest)
		physics_skeleton.set_bone_pose_position(i,skeleton.get_bone_pose_position(i)*units_to_meters)
		physics_skeleton.set_bone_pose_rotation(i,skeleton.get_bone_pose_rotation(i))
	simulator = PhysicalBoneSimulator3D.new()
	simulator.name = "LocalPhysicalBoneSimulator"
	physics_skeleton.add_child(simulator)
	var definitions := physical_definitions()
	for entry in definitions:
		var index := physics_skeleton.find_bone(entry[0])
		if index < 0: continue
		var rest := physics_skeleton.get_bone_global_rest(index)
		var child_index := physics_skeleton.find_bone(entry[1])
		var direction := Vector3.UP*segment_fallback()*units_to_meters if child_index < 0 else physics_skeleton.get_bone_global_rest(child_index).origin-rest.origin
		if direction.length() < .001: direction = Vector3.UP*segment_fallback()*.82*units_to_meters
		var y_axis := direction.normalized()
		var x_axis := Vector3.RIGHT if absf(y_axis.dot(Vector3.RIGHT)) < .85 else Vector3.FORWARD
		var z_axis := x_axis.cross(y_axis).normalized(); x_axis = y_axis.cross(z_axis).normalized()
		var body_transform := Transform3D(Basis(x_axis,y_axis,z_axis),rest.origin+direction*.5)
		var bone := PhysicalBone3D.new()
		bone.name = "Physics_"+str(entry[0]); bone.bone_name = entry[0]
		bone.body_offset = rest.affine_inverse()*body_transform
		bone.mass = entry[3]; bone.linear_damp = .6; bone.angular_damp = 1.7
		bone.friction = .85; bone.bounce = 0.0
		bone.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		bone.collision_layer = 4; bone.collision_mask = 1
		var hinge: bool = hinge_bone(entry[0])
		bone.joint_type = PhysicalBone3D.JOINT_TYPE_HINGE if hinge else PhysicalBone3D.JOINT_TYPE_CONE
		# Hinge gira sobre Z; Cone limita el giro alrededor de X. Ambos marcos
		# deben expresarse en espacio de esqueleto antes de pasar al cuerpo.
		var axis := Vector3.RIGHT if knee_bone(entry[0]) else Vector3.UP
		var axis_x := Vector3.FORWARD if absf(axis.dot(Vector3.FORWARD)) < .9 else Vector3.RIGHT
		var axis_y := axis.cross(axis_x).normalized(); axis_x = axis_y.cross(axis).normalized()
		var joint_basis := Basis(axis_x,axis_y,axis) if hinge else Basis(y_axis,z_axis,x_axis)
		bone.joint_offset = body_transform.affine_inverse()*Transform3D(joint_basis,rest.origin)
		if hinge:
			bone.set("joint_constraints/angular_limit_enabled",true)
			var right_elbow: bool = right_elbow_bone(entry[0])
			# PhysicalBone3D inspector properties receive DEGREES (not radians).
			bone.set("joint_constraints/angular_limit_lower",-6.0 if right_elbow else -125.0)
			bone.set("joint_constraints/angular_limit_upper",125.0 if right_elbow else 6.0)
		else:
			var swing := 65.0 if "UpperArm" in entry[0] else (45.0 if hip_bone(entry[0]) else 22.0)
			var twist := 30.0 if "UpperArm" in entry[0] else (20.0 if hip_bone(entry[0]) else 12.0)
			bone.set("joint_constraints/swing_span",swing)
			bone.set("joint_constraints/twist_span",twist)
		# Anclas explícitas en la pose del impacto. El rig tiene huesos intermedios
		# sin cuerpo físico; reconstruir solo joint_offset no era suficiente.
		joint_profiles[entry[0]] = {"hinge":hinge,"basis":joint_basis,
			"lower":-6.0 if right_elbow_bone(entry[0]) else -125.0,
			"upper":125.0 if right_elbow_bone(entry[0]) else 6.0,
			"swing":65.0 if "UpperArm" in entry[0] else (45.0 if hip_bone(entry[0]) else 22.0),
			"twist":30.0 if "UpperArm" in entry[0] else (20.0 if hip_bone(entry[0]) else 12.0)}
		bone.joint_type = PhysicalBone3D.JOINT_TYPE_NONE
		var shape := CapsuleShape3D.new()
		shape.radius = float(entry[2])*units_to_meters
		shape.height = maxf(direction.length(),shape.radius*2.05)
		var collision := CollisionShape3D.new(); collision.shape = shape
		bone.add_child(collision); simulator.add_child(bone); bodies.append(bone)
		PhysicsServer3D.body_set_enable_continuous_collision_detection(bone.get_rid(),true)
		if actor is PhysicsBody3D: bone.add_collision_exception_with(actor)
	initialized = bodies.size() >= 11
	simulator.physical_bones_stop_simulation()
	for bone in bodies: bone.collision_layer = 0; bone.collision_mask = 0
	process_priority = 100
	set_process(true)

func _process(delta: float) -> void:
	if paused: return
	if active: transfer_physical_pose()
	elif recovering > 0: blend_recovery(delta)

func transfer_physical_pose() -> void:
	# El solver puede acelerar un miembro pequeño al resolver un contacto.
	# Limitar la velocidad angular física evita latigazos sin bloquear la junta.
	for bone in bodies:
		if bone.angular_velocity.length_squared() > 144:
			bone.angular_velocity = bone.angular_velocity.limit_length(12.0)
	var inverse := skeleton.global_transform.affine_inverse()
	var poses: Array[Transform3D] = []
	var physical: Dictionary = {}
	for bone in bodies: physical[skeleton.find_bone(bone.bone_name)] = bone.global_transform*bone.body_offset.affine_inverse()
	var cache: Dictionary = {}
	for i in range(skeleton.get_bone_count()):
		var pose: Transform3D = inverse*world_bone_pose(i,physical,cache)
		# El cambio metros → centímetros afecta las posiciones, no la escala de los huesos.
		pose.basis = pose.basis.orthonormalized()
		poses.append(pose)
	for i in range(skeleton.get_bone_count()):
		var parent := skeleton.get_bone_parent(i)
		var local: Transform3D = poses[i] if parent < 0 else poses[parent].affine_inverse()*poses[i]
		# La física decide rotaciones; la cadena visual conserva sus longitudes originales.
		# Copiar traslaciones independientes estiraba hombros, cuello y extremidades.
		skeleton.set_bone_pose_position(i,local.origin if dynamic_translation(i) else rest_positions[i])
		skeleton.set_bone_pose_rotation(i,bounded_rotation(i,local.basis.orthonormalized().get_rotation_quaternion()))
		skeleton.set_bone_pose_scale(i,Vector3.ONE)
	align_visual_to_ground()

func prepare_contact_hulls(node: Node) -> void:
	if node is MeshInstance3D and node.skin != null and node.mesh != null:
		var mesh: MeshInstance3D = node
		for surface in range(mesh.mesh.get_surface_count()):
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var count := indices.size()/vertices.size()
			for i in range(vertices.size()):
				var dominant := 0; var maximum := -1.0
				for j in range(count):
					if weights[i*count+j] > maximum: maximum = weights[i*count+j]; dominant = indices[i*count+j]
				var bone := mesh.skin.get_bind_bone(dominant)
				if mesh.skin.get_bind_name(dominant) != &"": bone = skeleton.find_bone(mesh.skin.get_bind_name(dominant))
				var point := mesh.skin.get_bind_pose(dominant)*vertices[i]
				if not contact_hulls.has(bone): contact_hulls[bone] = AABB(point,Vector3.ZERO)
				else: contact_hulls[bone] = (contact_hulls[bone] as AABB).expand(point)
	for child in node.get_children(): prepare_contact_hulls(child)

func align_visual_to_ground() -> void:
	visual_ground_lift = 0
	if contact_hulls.is_empty(): return
	skeleton.force_update_all_bone_transforms()
	var pelvis := pelvis_world()
	var ray := PhysicsRayQueryParameters3D.create(pelvis+Vector3.UP*.5,pelvis-Vector3.UP*2.5,1)
	var ground := actor.get_world_3d().direct_space_state.intersect_ray(ray)
	if ground.is_empty(): return
	var minimum := INF
	for index in contact_hulls:
		var transform: Transform3D = skeleton.global_transform*skeleton.get_bone_global_pose(index)
		var bounds: AABB = contact_hulls[index]
		for corner in range(8): minimum = minf(minimum,(transform*bounds.get_endpoint(corner)).y)
	visual_ground_lift = clampf(float(ground.position.y)+.018-minimum,0,.6)
	if visual_ground_lift <= 0: return
	# La corrección es exclusivamente visual: las cápsulas siguen simulándose.
	# Las rotaciones anatómicas limitadas no pueden hundir la piel en el suelo.
	var parent := skeleton.get_bone_parent(pelvis_index)
	var parent_basis := skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var local_offset := (skeleton.global_basis*parent_basis).inverse()*(Vector3.UP*visual_ground_lift)
	skeleton.set_bone_pose_position(pelvis_index,skeleton.get_bone_pose_position(pelvis_index)+local_offset)

func bounded_rotation(index: int, rotation: Quaternion) -> Quaternion:
	if index == pelvis_index: return rotation.normalized()
	var name := skeleton.get_bone_name(index)
	var limit := 35.0
	if "UpperArm" in name: limit = 100.0
	elif hinge_bone(name): limit = 130.0
	elif hip_bone(name): limit = 75.0
	elif "Finger" in name: limit = 65.0
	elif "Head" in name or "Neck" in name: limit = 32.0
	elif "Spine" in name or name in ["Torso","Chest"]: limit = 25.0
	elif "Foot" in name or "Toe" in name: limit = 25.0
	var rest := rest_rotations[index]
	var angle := rest.angle_to(rotation)
	return rest.slerp(rotation,minf(1,deg_to_rad(limit)/maxf(angle,.0001))).normalized()

func create_joints() -> void:
	clear_joints()
	var physical := {}
	for bone in bodies: physical[physics_skeleton.find_bone(bone.bone_name)] = bone
	for bone in bodies:
		var index := physics_skeleton.find_bone(bone.bone_name)
		var parent := joint_parent(index,physical)
		if parent < 0: continue
		var profile: Dictionary = joint_profiles[bone.bone_name]
		var joint: Joint3D = HingeJoint3D.new() if profile.hinge else ConeTwistJoint3D.new()
		physics_skeleton.add_child(joint)
		joint.name = "ImpactJoint_"+bone.bone_name
		var pose: Transform3D = bone.global_transform*bone.body_offset.affine_inverse()
		var delta_basis := pose.basis.orthonormalized()*physics_skeleton.get_bone_global_rest(index).basis.orthonormalized().inverse()
		joint.global_transform = Transform3D(delta_basis*profile.basis,pose.origin)
		joint.node_a = joint.get_path_to(physical[parent]); joint.node_b = joint.get_path_to(bone)
		joint.exclude_nodes_from_collision = true
		if joint is HingeJoint3D:
			joint.set_flag(HingeJoint3D.FLAG_USE_LIMIT,true)
			joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER,deg_to_rad(profile.lower))
			joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER,deg_to_rad(profile.upper))
		else:
			joint.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN,deg_to_rad(profile.swing))
			joint.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN,deg_to_rad(profile.twist))
		joints.append(joint)

func clear_joints() -> void:
	for joint in joints:
		if is_instance_valid(joint): joint.free()
	joints.clear()

func world_bone_pose(index: int, physical: Dictionary, cache: Dictionary) -> Transform3D:
	if cache.has(index): return cache[index]
	if physical.has(index): cache[index] = physical[index]; return cache[index]
	var parent := physics_skeleton.get_bone_parent(index)
	var ancestor: Transform3D = physics_skeleton.global_transform if parent < 0 else world_bone_pose(parent,physical,cache)
	cache[index] = ancestor*physics_skeleton.get_bone_pose(index)
	return cache[index]

func start(velocity: Vector3 = Vector3.ZERO, impact: Dictionary = {}) -> bool:
	if active or not initialized: return false
	active = true; recovering = 0
	var factor := skeleton.global_basis.get_scale().x
	physics_skeleton.global_transform = Transform3D(skeleton.global_basis.orthonormalized(),skeleton.global_position)
	for i in range(skeleton.get_bone_count()):
		physics_skeleton.set_bone_pose_position(i,skeleton.get_bone_pose_position(i)*factor)
		physics_skeleton.set_bone_pose_rotation(i,skeleton.get_bone_pose_rotation(i))
	physics_skeleton.force_update_all_bone_transforms()
	saved_holder = holder.transform
	saved_interpolation = holder.physics_interpolation_mode
	holder.set_as_top_level(true)
	holder.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	holder.reset_physics_interpolation()
	if animation_tree != null: animation_tree.active = false
	if animator != null: animator.active = false
	if actor is CollisionObject3D:
		saved_layer = actor.collision_layer; saved_mask = actor.collision_mask
		actor.collision_layer = 0; actor.collision_mask = 0
	for bone in bodies: bone.collision_layer = 4; bone.collision_mask = 1
	# Todos los cuerpos deben estar colocados antes de que se calcule una sola
	# articulación. El simulador no garantiza ese orden al arrancar por sí solo.
	var initial_body_poses: Array[Transform3D] = []
	for bone in bodies:
		var index := physics_skeleton.find_bone(bone.bone_name)
		bone.global_transform = physics_skeleton.global_transform*physics_skeleton.get_bone_global_pose(index)*bone.body_offset
		initial_body_poses.append(bone.global_transform)
	simulator.physical_bones_start_simulation()
	# Sincroniza también el servidor físico. El transform del Node3D por sí
	# solo puede seguir mostrando el frame anterior durante el arranque.
	for i in range(bodies.size()):
		bodies[i].global_transform = initial_body_poses[i]
		PhysicsServer3D.body_set_state(bodies[i].get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,initial_body_poses[i])
	create_joints()
	for bone in bodies: bone.linear_velocity = velocity; bone.angular_velocity = Vector3.ZERO
	last_impact.clear()
	if not impact.is_empty(): apply_hit_impulse(velocity,impact)
	return true

func apply_hit_impulse(velocity: Vector3, impact: Dictionary) -> void:
	var kind: String = impact.get("kind","horizontal")
	var direction: Vector3 = impact.get("direction",Vector3(velocity.x,0,velocity.z))
	direction.y = 0
	if direction.length_squared() < .001: direction = -actor.global_basis.z
	direction = direction.normalized()
	var target_name: String = impact.get("bone",torso_name() if kind == "uppercut" else pelvis_name())
	var selected: PhysicalBone3D
	for bone in bodies:
		if str(bone.bone_name) == target_name: selected = bone; break
	if selected == null: return
	var side := clampf(float(impact.get("side",1)), -1, 1)
	var right := direction.cross(Vector3.UP).normalized()
	# Descentrar el contacto crea el giro por r × impulso. Los cuerpos vecinos
	# reciben la reacción por sus articulaciones, no una rotación visual impuesta.
	var contact_offset: Vector3 = right*.10*side+Vector3.UP*.07
	var delta_velocity := direction*1.35
	if kind == "uppercut":
		delta_velocity = Vector3.UP*2.0+direction*.45
		contact_offset = direction*.16+right*.04*side
	elif kind == "downslam":
		delta_velocity = Vector3.DOWN*1.8
		contact_offset = direction*.12
	var contact: Vector3 = impact.get("position",selected.global_position+contact_offset)
	# Las coordenadas de contacto son globales, pero el servidor físico espera
	# un desplazamiento respecto al centro del cuerpo expresado en ejes globales.
	var offset := (contact-selected.global_position).limit_length(.22)
	var impulse := delta_velocity*selected.mass
	PhysicsServer3D.body_apply_impulse(selected.get_rid(),impulse,offset)
	last_impact = {"kind":kind,"bone":target_name,"point":contact,"impulse":impulse,"offset":offset}
	# Respuesta inicial de miembros libre pero acotada; se simula en Jolt.
	for bone in bodies:
		if "UpperArm" in bone.bone_name:
			bone.angular_velocity = right*(.35 if kind == "uppercut" else -.22)
		elif "Forearm" in bone.bone_name:
			bone.angular_velocity = right*(.55 if kind == "uppercut" else -.35)
	# El contacto localizado puede causar una velocidad angular muy elevada
	# en cuerpos pequeños. Acotar solo el arranque conserva la estabilidad.
	var spin: Vector3 = PhysicsServer3D.body_get_state(selected.get_rid(),PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY)
	PhysicsServer3D.body_set_state(selected.get_rid(),PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY,spin.limit_length(6.0))
	last_impact["initial_spin"] = spin.limit_length(6.0)

func pelvis_world() -> Vector3:
	for bone in bodies:
		if bone.bone_name == pelvis_name(): return (bone.global_transform*bone.body_offset.affine_inverse()).origin
	return actor.global_position

func follow_actor() -> void:
	if not active: return
	var pelvis := pelvis_world()
	transfer_physical_pose()
	actor.global_position.x = pelvis.x; actor.global_position.z = pelvis.z
	actor.global_position.y = pelvis.y-.65

func grounded() -> bool:
	if not active: return false
	var pelvis := pelvis_world()
	var ray := PhysicsRayQueryParameters3D.create(pelvis,pelvis-Vector3.UP*.55,1)
	return not actor.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func stop(recover: bool = true) -> void:
	if not active: return
	transfer_physical_pose()
	var pelvis := pelvis_world()
	var old_world := skeleton.global_transform
	var poses: Array[Transform3D] = []
	for i in range(skeleton.get_bone_count()): poses.append(old_world*skeleton.get_bone_global_pose(i))
	clear_joints()
	simulator.physical_bones_stop_simulation()
	for bone in bodies: bone.collision_layer = 0; bone.collision_mask = 0
	active = false
	if recover:
		var ray := PhysicsRayQueryParameters3D.create(pelvis+Vector3.UP*2,pelvis-Vector3.UP*8,1)
		var ground := actor.get_world_3d().direct_space_state.intersect_ray(ray)
		actor.global_position = Vector3(pelvis.x,float(ground.position.y)+.05 if not ground.is_empty() else maxf(.05,pelvis.y-.65),pelvis.z)
	holder.set_as_top_level(false); holder.transform = saved_holder
	holder.physics_interpolation_mode = saved_interpolation
	holder.reset_physics_interpolation()
	if actor is CollisionObject3D: actor.collision_layer = saved_layer; actor.collision_mask = saved_mask
	recovery_rotations.clear(); recovery_positions.clear()
	if recover:
		var inverse := skeleton.global_transform.affine_inverse()
		var locals: Array[Transform3D] = []
		for pose in poses:
			var local: Transform3D = inverse*pose
			local.basis = local.basis.orthonormalized()
			locals.append(local)
		for i in range(skeleton.get_bone_count()):
			var parent := skeleton.get_bone_parent(i)
			var local: Transform3D = locals[i] if parent < 0 else locals[parent].affine_inverse()*locals[i]
			recovery_rotations.append(local.basis.orthonormalized().get_rotation_quaternion())
			recovery_positions.append(local.origin)
			# La traslación de pelvis se alinea con el controlador; los miembros conservan pose.
			if skeleton.get_bone_name(i) != pelvis_name(): skeleton.set_bone_pose_rotation(i,recovery_rotations[i])
		recovering = .34
		# Reinicia traslaciones de reposo; la recuperación mezcla las rotaciones físicas.
		for i in range(skeleton.get_bone_count()): skeleton.set_bone_pose_position(i,skeleton.get_bone_rest(i).origin)
	else:
		skeleton.reset_bone_poses()
	if animator != null: animator.active = not paused

func blend_recovery(delta: float) -> void:
	if recovering <= 0 or active: return
	recovering = maxf(0,recovering-delta)
	var weight := smoothstep(0.0,.34,recovering)
	for i in range(skeleton.get_bone_count()):
		if skeleton.get_bone_name(i) == pelvis_name(): continue
		skeleton.set_bone_pose_rotation(i,skeleton.get_bone_pose_rotation(i).slerp(recovery_rotations[i],weight))

func cancel() -> void:
	stop(false)
	recovering = 0
	paused_velocities.clear()

func pause_simulation(value: bool) -> void:
	if paused == value: return
	paused = value
	if not active: return
	if value:
		paused_velocities.clear()
		for bone in bodies:
			paused_velocities.append({"linear":bone.linear_velocity,"angular":bone.angular_velocity})
			PhysicsServer3D.body_set_mode(bone.get_rid(),PhysicsServer3D.BODY_MODE_STATIC)
	else:
		for i in range(bodies.size()):
			PhysicsServer3D.body_set_mode(bodies[i].get_rid(),PhysicsServer3D.BODY_MODE_RIGID)
			if i < paused_velocities.size():
				bodies[i].linear_velocity = paused_velocities[i].linear
				bodies[i].angular_velocity = paused_velocities[i].angular
		paused_velocities.clear()

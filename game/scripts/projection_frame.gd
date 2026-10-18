extends Node3D
# Un único panel original. La fotografía usa otro World3D y no duplica actores.
const PANE_SCENE: PackedScene = preload("res://assets/projection/GlassPane.glb")
const GLASS: ShaderMaterial = preload("res://materials/projection_glass.tres")
const PANE_SCALE := 2.30 / 1.899356723
const PHOTO_SIZE := Vector2(1.487114072 * PANE_SCALE, 2.30)
var pane: Node3D
var portrait: MeshInstance3D
var capture_viewport: SubViewport
var rear_viewport: SubViewport
var rear_portrait: MeshInstance3D
enum State { CAPTURING, FROZEN, RELEASING, RELEASED }
var state := State.CAPTURING
signal ended(reason: String)
var original_visual: Node3D
var original_visible := true
var driver_states: Array[Dictionary] = []
var game: Node3D
var released := false
var image_ready := false
var capture_requested := false
var capture_supported := false
var photo_size := PHOTO_SIZE
var capture_camera: Camera3D
const SNAP = preload("res://scripts/mesh_pose_snapshot.gd")

func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node
	for child in node.get_children():
		var found := find_skeleton(child)
		if found != null: return found
	return null

func pose_bounds(visual: Node3D) -> AABB:
	var sk := find_skeleton(visual)
	if sk != null: sk.force_update_all_bone_transforms()
	var meshes: Array[MeshInstance3D] = []; SNAP.collect(visual,meshes)
	var result := AABB(); var first := true
	for mesh in meshes:
		var transform := global_transform.affine_inverse()*(sk.global_transform if mesh.skin != null and sk != null else mesh.global_transform)
		for surface in range(mesh.mesh.get_surface_count()):
			var points: PackedVector3Array = SNAP.vertices(mesh,sk,surface) if mesh.skin != null and sk != null else mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for point in points:
				var local: Vector3 = transform*point
				result = AABB(local,Vector3.ZERO) if first else result.expand(local); first = false
	return result

func bake_pose(visual: Node3D) -> Node3D:
	var world := Node3D.new(); world.name = "BakedFrozenPose"
	var sk := find_skeleton(visual)
	if sk != null: sk.force_update_all_bone_transforms()
	var meshes: Array[MeshInstance3D] = []; SNAP.collect(visual,meshes)
	for source in meshes:
		var transform := global_transform.affine_inverse()*(sk.global_transform if source.skin != null and sk != null else source.global_transform)
		if source.skin == null:
			# Piezas mecánicas rígidas: una fotografía no necesita reconstruir
			# cientos de miles de triángulos ni recalcular sus tangentes.
			var rigid := MeshInstance3D.new(); rigid.mesh = source.mesh
			rigid.transform = transform
			for surface in range(source.mesh.get_surface_count()): rigid.set_surface_override_material(surface,source.get_active_material(surface))
			rigid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			world.add_child(rigid)
			continue
		for surface in range(source.mesh.get_surface_count()):
			var arrays: Array = source.mesh.surface_get_arrays(surface).duplicate()
			var points: PackedVector3Array = SNAP.vertices(source,sk,surface) if source.skin != null and sk != null else arrays[Mesh.ARRAY_VERTEX]
			for i in range(points.size()): points[i] = transform*points[i]
			arrays[Mesh.ARRAY_VERTEX] = points; arrays[Mesh.ARRAY_BONES] = null; arrays[Mesh.ARRAY_WEIGHTS] = null
			arrays[Mesh.ARRAY_NORMAL] = null; arrays[Mesh.ARRAY_TANGENT] = null
			var mesh := ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			var tool := SurfaceTool.new(); tool.create_from(mesh,0); tool.generate_normals()
			if arrays[Mesh.ARRAY_TEX_UV] != null: tool.generate_tangents()
			var baked := MeshInstance3D.new(); baked.mesh = tool.commit()
			baked.material_override = source.get_active_material(surface)
			baked.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			world.add_child(baked)
	return world

func setup(_ability_color: Color = Color("bfe5ff")) -> void:
	pane = PANE_SCENE.instantiate()
	pane.name = "OriginalGlassPane"
	add_child(pane)
	pane.scale = Vector3.ONE * PANE_SCALE
	pane.position = -Vector3(-0.002185285, -0.001676619, -0.001784755) * PANE_SCALE
	apply_material(pane)

func apply_material(node: Node) -> void:
	if node is MeshInstance3D:
		node.material_override = GLASS
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children(): apply_material(child)

func remove_animation_drivers(node: Node) -> void:
	for child in node.get_children():
		if child is AnimationPlayer or child is AnimationTree or child is PhysicalBoneSimulator3D or child.name == "MeterPhysicalSkeleton":
			node.remove_child(child)
			child.free()
		else: remove_animation_drivers(child)

func copy_poses(source: Node, copy: Node) -> void:
	if source is Skeleton3D:
		for i in range(source.get_bone_count()):
			copy.set_bone_pose_position(i, source.get_bone_pose_position(i))
			copy.set_bone_pose_rotation(i, source.get_bone_pose_rotation(i))
			copy.set_bone_pose_scale(i, source.get_bone_pose_scale(i))
		copy.force_update_all_bone_transforms()
	# duplicate() sanea nombres automáticos (@Node3D -> _Node3D).
	# Recorrer la misma estructura evita depender de esos nombres temporales.
	for i in range(source.get_child_count()):
		var child := source.get_child(i)
		if not (child is AnimationPlayer or child is AnimationTree or child is PhysicalBoneSimulator3D): copy_poses(child,copy.get_child(i))

func hold_drivers(node: Node) -> void:
	if node is AnimationPlayer or node is AnimationTree:
		driver_states.append({"node":node,"mode":node.process_mode,"active":node.active})
		node.active = false
		node.process_mode = Node.PROCESS_MODE_DISABLED
	for child in node.get_children(): hold_drivers(child)

func collect_bounds(node: Node, relative: Transform3D, boxes: Array[AABB]) -> void:
	if node is Node3D and not node.is_visible_in_tree(): return
	if node is MeshInstance3D and node.mesh != null:
		boxes.append(relative*node.global_transform*node.get_aabb())
	if node is Skeleton3D:
		for i in range(node.get_bone_count()):
			var point: Vector3 = relative*node.global_transform*node.get_bone_global_pose(i).origin
			boxes.append(AABB(point,Vector3.ZERO))
	for child in node.get_children(): collect_bounds(child,relative,boxes)

func fit_pose(visual: Node3D) -> void:
	var bounds := pose_bounds(visual)
	bounds = bounds.grow(0.12)
	var aspect := PHOTO_SIZE.x/PHOTO_SIZE.y
	var height := maxf(PHOTO_SIZE.y,maxf(bounds.size.y,bounds.size.x/aspect))
	photo_size = Vector2(height*aspect,height)
	global_position += global_basis*Vector3(bounds.get_center().x,bounds.get_center().y,0)
	var factor := height/1.899356723
	pane.scale = Vector3.ONE*factor
	pane.position = -Vector3(-0.002185285,-0.001676619,-0.001784755)*factor

func capture(visual: Node3D, host: Node3D) -> void:
	game = host
	original_visual = visual
	original_visible = visual.visible
	fit_pose(visual)
	capture_requested = true
	capture_supported = DisplayServer.get_name() != "headless"
	var copy: Node3D = bake_pose(visual)
	copy.visible = true
	copy.process_mode = Node.PROCESS_MODE_DISABLED
	capture_viewport = SubViewport.new()
	capture_viewport.name = "PoseCapture"
	capture_viewport.size = Vector2i(400, 512)
	capture_viewport.transparent_bg = true
	capture_viewport.own_world_3d = true
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(capture_viewport)
	var capture_world := Node3D.new()
	capture_world.name = "IsolatedSnapshotWorld"
	capture_viewport.add_child(capture_world)
	capture_world.add_child(copy)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0,0,0,0)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	capture_world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25,-25,0)
	light.light_energy = 1.2
	light.shadow_enabled = false
	capture_world.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = photo_size.y
	camera.position = Vector3(0,0,6)
	camera.near = 0.01
	camera.far = 40
	capture_world.add_child(camera)
	camera.current = true
	capture_camera = camera
	rear_viewport = SubViewport.new()
	rear_viewport.name = "BackPoseCapture"
	rear_viewport.size = capture_viewport.size
	rear_viewport.transparent_bg = true
	rear_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(rear_viewport)
	rear_viewport.world_3d = capture_viewport.find_world_3d()
	var rear_camera := Camera3D.new()
	rear_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	rear_camera.size = photo_size.y
	rear_camera.position = Vector3(0,0,-6)
	rear_camera.rotation.y = PI
	rear_camera.near = 0.01
	rear_camera.far = 40
	rear_viewport.add_child(rear_camera)
	rear_camera.current = false
	portrait = MeshInstance3D.new()
	portrait.name = "FrozenPose2D"
	var quad := QuadMesh.new()
	quad.size = photo_size
	portrait.mesh = quad
	portrait.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_BACK
	material.albedo_texture = capture_viewport.get_texture()
	material.render_priority = 1
	portrait.material_override = material
	add_child(portrait)
	portrait.position.z = 0.002
	rear_portrait = MeshInstance3D.new()
	rear_portrait.name = "FrozenBackPose2D"
	rear_portrait.mesh = quad
	rear_portrait.rotation.y = PI
	rear_portrait.position.z = -0.002
	rear_portrait.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rear_material := material.duplicate() as StandardMaterial3D
	rear_material.albedo_texture = rear_viewport.get_texture()
	rear_portrait.material_override = rear_material
	add_child(rear_portrait)
	hold_drivers(visual)
	visual.hide()
	# Dummy no genera píxeles. Las pruebas sin imagen solo validan el ciclo de vida.
	if not capture_supported:
		portrait.hide()
		rear_portrait.hide()
		state = State.FROZEN
		return
	finish_capture(material,rear_material)

func finish_capture(material: StandardMaterial3D,rear_material: StandardMaterial3D) -> void:
	await RenderingServer.frame_post_draw
	if released or not is_instance_valid(capture_viewport): return
	var image := capture_viewport.get_texture().get_image()
	# Dos vistas consecutivas de la misma geometría congelada: una cámara,
	# un render target y dos ImageTexture independientes, sin cámaras compartidas.
	capture_camera.position = Vector3(0,0,-6); capture_camera.rotation.y = PI
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if released or not is_instance_valid(capture_viewport): return
	var rear_image := capture_viewport.get_texture().get_image()
	if image == null or image.is_empty() or rear_image == null or rear_image.is_empty():
		portrait.hide()
		rear_portrait.hide()
		# Nunca superponer el actor 3D con un vidrio activo si falla la captura.
		push_warning("No se pudo capturar el fotograma 2D; revisar el renderizador gráfico.")
	else:
		material.albedo_texture = ImageTexture.create_from_image(image)
		rear_material.albedo_texture = ImageTexture.create_from_image(rear_image)
		image_ready = true
	state = State.FROZEN
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	capture_viewport.queue_free()
	capture_viewport = null
	rear_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	rear_viewport.queue_free()
	rear_viewport = null

func enforce() -> void:
	if state not in [State.CAPTURING,State.FROZEN]: return
	if is_instance_valid(original_visual): original_visual.hide()
	for saved in driver_states:
		if is_instance_valid(saved.node): saved.node.active = false

func dissolve(reason: String = "timeout") -> bool:
	if state in [State.RELEASING,State.RELEASED]: return false
	state = State.RELEASING
	if is_instance_valid(game):
		game.feedback.crystal_break(global_transform,photo_size,reason == "hit")
	release()
	ended.emit(reason)
	queue_free()
	return true

func release() -> void:
	if released: return
	released = true
	state = State.RELEASED
	hide()
	if is_instance_valid(original_visual): original_visual.visible = original_visible
	for state in driver_states:
		if not is_instance_valid(state.node): continue
		var paused: bool = is_instance_valid(game) and game.paused
		state.node.process_mode = Node.PROCESS_MODE_DISABLED if paused else state.mode
		state.node.active = state.active and not paused
	driver_states.clear()
	if is_instance_valid(capture_viewport):
		capture_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		capture_viewport.queue_free()
	capture_viewport = null
	if is_instance_valid(rear_viewport):
		rear_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		rear_viewport.queue_free()
	rear_viewport = null

func _exit_tree() -> void: release()

extends RefCounted
# Skinning CPU para siluetas y pruebas geométricas. No toca pesos ni huesos.
static func vertices(mesh: MeshInstance3D, skeleton: Skeleton3D, surface: int) -> PackedVector3Array:
	var arrays := mesh.mesh.surface_get_arrays(surface)
	var source: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if mesh.skin == null: return source
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var transforms: Array[Transform3D] = []
	for i in range(mesh.skin.get_bind_count()):
		var bone := mesh.skin.get_bind_bone(i)
		if mesh.skin.get_bind_name(i) != &"": bone = skeleton.find_bone(mesh.skin.get_bind_name(i))
		transforms.append(skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(i))
	var result := PackedVector3Array(); result.resize(source.size())
	var count := bones.size()/source.size()
	for i in range(source.size()):
		var value := Vector3.ZERO
		for j in range(count):
			var weight := weights[i*count+j]
			if weight > 0: value += transforms[bones[i*count+j]]*source[i]*weight
		result[i] = value
	return result
static func collect(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and node.mesh != null and node.is_visible_in_tree(): meshes.append(node)
	for child in node.get_children(): collect(child,meshes)
static func silhouette(visual: Node3D, skeleton: Skeleton3D, frame: Transform3D) -> ArrayMesh:
	var result := ArrayMesh.new()
	var meshes: Array[MeshInstance3D] = []; collect(visual,meshes)
	if skeleton != null: skeleton.force_update_all_bone_transforms()
	var inverse := frame.affine_inverse()
	for mesh in meshes:
		for surface in range(mesh.mesh.get_surface_count()):
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var points: PackedVector3Array = vertices(mesh,skeleton,surface) if mesh.skin != null and skeleton != null else arrays[Mesh.ARRAY_VERTEX]
			var transform := inverse*(skeleton.global_transform if mesh.skin != null else mesh.global_transform)
			for i in range(points.size()):
				points[i] = transform*points[i]; points[i].z = .008
			arrays[Mesh.ARRAY_VERTEX] = points
			arrays[Mesh.ARRAY_BONES] = null; arrays[Mesh.ARRAY_WEIGHTS] = null
			arrays[Mesh.ARRAY_NORMAL] = null; arrays[Mesh.ARRAY_TANGENT] = null
			result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return result

extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		meshes(child,result)
func run() -> void:
	for entry in [["worm.gltf","worm_rig.tscn",2.8],["evolved.glb","evolved_rig.tscn",3.1]]:
		var original: Node3D = load("res://assets/forms/"+entry[0]).instantiate()
		root.add_child(original)
		var sources: Array[MeshInstance3D] = []
		meshes(original,sources)
		var bounds := AABB()
		var first := true
		for source in sources:
			var box: AABB = source.global_transform*source.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		var axis := bounds.size.max_axis_index()
		var turn := Basis.IDENTITY
		if axis == Vector3.AXIS_X:
			turn = Basis(Vector3.UP,PI/2)
		elif axis == Vector3.AXIS_Y:
			turn = Basis(Vector3.RIGHT,-PI/2)
		else:
			turn = Basis(Vector3.UP,PI)
		var length: float = entry[2]
		var factor: float = length/bounds.size[axis]
		var holder := Node3D.new()
		holder.name = "Creature"
		root.add_child(holder)
		var skeleton := Skeleton3D.new()
		holder.add_child(skeleton)
		skeleton.name = "Skeleton3D"
		skeleton.owner = holder
		for i in range(7):
			skeleton.add_bone("Body"+str(i))
			if i > 0:
				skeleton.set_bone_parent(i,i-1)
			skeleton.set_bone_rest(i,Transform3D(Basis.IDENTITY,Vector3(0,0,-length*0.35 if i == 0 else length*0.12)))
		skeleton.reset_bone_poses()
		var skin := skeleton.create_skin_from_rest_transforms()
		for source in sources:
			var result := ArrayMesh.new()
			for surface in range(source.mesh.get_surface_count()):
				var arrays: Array = source.mesh.surface_get_arrays(surface)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				var bones := PackedInt32Array()
				var weights := PackedFloat32Array()
				bones.resize(vertices.size()*4)
				weights.resize(vertices.size()*4)
				for i in range(vertices.size()):
					vertices[i] = turn*(source.global_transform*vertices[i]-bounds.get_center())*factor
					if normals.size() > i:
						normals[i] = (turn*source.global_basis.inverse().transposed()*normals[i]).normalized()
					var along := clampf((vertices[i].z+length*0.35)/(length*0.12),0,6)
					var lower := mini(5,int(floor(along)))
					bones[i*4] = lower
					bones[i*4+1] = lower+1
					weights[i*4] = 1.0-(along-lower)
					weights[i*4+1] = along-lower
				arrays[Mesh.ARRAY_VERTEX] = vertices
				arrays[Mesh.ARRAY_NORMAL] = normals
				arrays[Mesh.ARRAY_TANGENT] = null
				arrays[Mesh.ARRAY_BONES] = bones
				arrays[Mesh.ARRAY_WEIGHTS] = weights
				result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				result.surface_set_material(surface,source.get_active_material(surface))
			var node := MeshInstance3D.new()
			skeleton.add_child(node)
			node.owner = holder
			node.mesh = result
			node.skin = skin
			node.skeleton = NodePath("..")
			node.extra_cull_margin = 2.0
		var scene := PackedScene.new()
		scene.pack(holder)
		assert(ResourceSaver.save(scene,"res://assets/forms/"+entry[1]) == OK)
		print("RIG ",entry[0]," meshes ",sources.size()," bounds ",bounds," longaxis ",axis," factor ",factor)
		holder.queue_free()
		original.queue_free()
	quit()

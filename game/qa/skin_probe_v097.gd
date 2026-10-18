extends SceneTree
var game: Node3D
var meshes: Array[MeshInstance3D] = []
var output_dir := ""
func _initialize() -> void: run.call_deferred()
func collect(node: Node) -> void:
	if node is MeshInstance3D and node.skin != null: meshes.append(node)
	for child in node.get_children(): collect(child)
func skin_vertices(mesh: MeshInstance3D, sk: Skeleton3D, surface: int) -> PackedVector3Array:
	var arrays := mesh.mesh.surface_get_arrays(surface)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var transforms: Array[Transform3D] = []
	for i in range(mesh.skin.get_bind_count()):
		var bone := mesh.skin.get_bind_bone(i)
		if mesh.skin.get_bind_name(i) != &"": bone = sk.find_bone(mesh.skin.get_bind_name(i))
		transforms.append(sk.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(i))
	var result := PackedVector3Array()
	var count := bones.size()/vertices.size()
	for i in range(vertices.size()):
		var v := Vector3.ZERO
		for j in range(count):
			var weight := weights[i*count+j]
			if weight > 0: v += transforms[bones[i*count+j]]*vertices[i]*weight
		result.append(v)
	return result
func snapshot(tag: String, save: bool = false) -> void:
	var sk: Skeleton3D = game.physical_ragdoll.skeleton
	sk.force_update_all_bone_transforms()
	var output := {"tag":tag,"scale":str(sk.global_basis.get_scale()),"bones":[],"meshes":[]}
	for i in range(sk.get_bone_count()): output.bones.append({"name":sk.get_bone_name(i),"rest_rotation":str(sk.get_bone_rest(i).basis.get_rotation_quaternion()),"rotation":str(sk.get_bone_pose_rotation(i))})
	for mesh in meshes:
		for surface in range(mesh.mesh.get_surface_count()):
			var points := skin_vertices(mesh,sk,surface)
			var bounds := AABB(points[0],Vector3.ZERO)
			for point in points: bounds = bounds.expand(point)
			output.meshes.append({"name":mesh.name,"vertices":points.size(),"bounds":str(bounds)})
			if save:
				var arrays := mesh.mesh.surface_get_arrays(surface)
				arrays[Mesh.ARRAY_VERTEX] = points
				arrays[Mesh.ARRAY_BONES] = null; arrays[Mesh.ARRAY_WEIGHTS] = null
				arrays[Mesh.ARRAY_NORMAL] = null; arrays[Mesh.ARRAY_TANGENT] = null
				var baked := ArrayMesh.new(); baked.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				var tool := SurfaceTool.new(); tool.create_from(baked,0); tool.generate_normals(); baked = tool.commit()
				var instance := MeshInstance3D.new(); root.add_child(instance); instance.mesh = baked
				instance.global_transform = mesh.global_transform
				instance.material_override = mesh.get_active_material(surface)
				var doc := GLTFDocument.new(); var state := GLTFState.new()
				doc.append_from_scene(instance,state)
				doc.write_to_filesystem(state,output_dir.path_join("skin_"+tag+"_"+str(surface)+".glb"))
				instance.free()
	var file := FileAccess.open(output_dir.path_join("skin_"+tag+".json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	print("SKIN ",tag," ",output.meshes)
func run() -> void:
	output_dir = OS.get_environment("NAOYA_QA_OUTPUT")
	if output_dir == "": output_dir = ProjectSettings.globalize_path("user://revision_malla_v097")
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = load("res://main.tscn").instantiate(); root.add_child(game)
	for i in range(5): await physics_frame
	game.set_physics_process(false); game.set_process(false)
	collect(game.rig_scene)
	game.locomotion_tree.active = false; game.rig_anim.active = false
	game.physical_ragdoll.skeleton.reset_bone_poses()
	snapshot("rest",true)
	game.rig_anim.active = true; game.play_rig_animation("combat/Uppercut",0,1,true); game.rig_anim.seek(.15,true)
	snapshot("impact",true)
	game.physical_ragdoll.start(Vector3(5,3,-2))
	for i in range(180):
		await physics_frame; game.physical_ragdoll.follow_actor()
		if i in [0,20,60,179]: snapshot(str(i),true)
	game.physical_ragdoll.stop(true)
	game.feedback.stop_all(); OS.delay_msec(150)
	game.queue_free(); await process_frame; await process_frame; quit()

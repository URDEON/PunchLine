extends SceneTree
# Offline bake: aplica deltas globales respecto al reposo, conserva longitudes
# del rig destino y convierte a rotaciones locales en orden de jerarquía.
func _initialize() -> void:
	call_deferred("run")
func skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found := skeleton(child)
		if found != null:
			return found
	return null
func animator(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := animator(child)
		if found != null:
			return found
	return null
func run() -> void:
	var source: Node3D = load("res://assets/dance/running_man.fbx").instantiate()
	var target: Node3D = load("res://assets/rpg_animations/Unarmed.glb").instantiate()
	root.add_child(source)
	root.add_child(target)
	var ss := skeleton(source)
	var ts := skeleton(target)
	var sa := animator(source)
	var ta := animator(target)
	var pairs := {"B_Pelvis":"B-hips", "B_Spine":"B-spine", "B_Spine2":"B-chest", "B_Neck":"B-neck", "B_Head":"B-head"}
	for side in ["L", "R"]:
		for pair in [["Clavicle","shoulder"],["UpperArm","upperArm"],["Forearm","forearm"],["Hand","hand"],["Thigh","thigh"],["Calf","shin"],["Foot","foot"],["Toe0","toe"]]:
			pairs["B_"+side+"_"+pair[0]] = "B-"+pair[1]+"."+side
		for finger in range(5):
			var src: String = ["thumb","indexFinger","middleFinger","ringFinger","pinky"][finger]
			for j in range(3):
				var dst: String = "B_"+side+"_Finger"+str(finger)+(str(j) if j > 0 else "")
				if side == "R" and finger == 0 and j > 0:
					dst = "B_R_Finger0.00"+str(j)
				pairs[dst] = "B-"+src+"0"+str(j+1)+"."+side
	var source_clip := ""
	for name in sa.get_animation_list():
		if str(name) != "RESET":
			source_clip = name
	var src_animation := sa.get_animation(source_clip)
	var out := Animation.new()
	out.resource_name = "RunningMan"
	out.length = src_animation.length
	out.loop_mode = Animation.LOOP_LINEAR
	var target_path := ta.get_node(ta.root_node).get_path_to(ts)
	var tracks := {}
	var mapping := {}
	for bone in range(ts.get_bone_count()):
		var name := ts.get_bone_name(bone)
		if pairs.has(name):
			var src := ss.find_bone(pairs[name])
			assert(src >= 0, "Hueso fuente ausente: "+str(pairs[name]))
			mapping[bone] = src
		var tr := out.add_track(Animation.TYPE_ROTATION_3D)
		out.track_set_path(tr, NodePath(str(target_path)+":"+name))
		tracks[bone] = tr
	var hip := ts.find_bone("B_Pelvis")
	var source_hip := ss.find_bone("B-hips")
	var pos_track := out.add_track(Animation.TYPE_POSITION_3D)
	out.track_set_path(pos_track, NodePath(str(target_path)+":B_Pelvis"))
	var ratio := ts.get_bone_global_rest(hip).origin.y / ss.get_bone_global_rest(source_hip).origin.y
	sa.play(source_clip)
	var samples := ceili(out.length*60)
	for k in range(samples+1):
		var time := out.length*float(k)/samples
		sa.seek(minf(time,out.length-0.00001),true)
		ss.force_update_all_bone_transforms()
		var globals: Array[Basis] = []
		for bone in range(ts.get_bone_count()):
			var parent := ts.get_bone_parent(bone)
			var parent_basis := globals[parent] if parent >= 0 else Basis.IDENTITY
			var local_basis := ts.get_bone_rest(bone).basis.orthonormalized()
			if mapping.has(bone):
				var src: int = mapping[bone]
				var delta := ss.get_bone_global_pose(src).basis.orthonormalized()*ss.get_bone_global_rest(src).basis.orthonormalized().inverse()
				var desired := delta*ts.get_bone_global_rest(bone).basis.orthonormalized()
				local_basis = parent_basis.inverse()*desired
			out.rotation_track_insert_key(tracks[bone],time,local_basis.get_rotation_quaternion().normalized())
			globals.append(parent_basis*local_basis)
		var offset := ss.get_bone_pose_position(source_hip)-ss.get_bone_rest(source_hip).origin
		# Conservar el rebote; eliminar desplazamiento horizontal para bailar in-place.
		out.position_track_insert_key(pos_track,time,ts.get_bone_rest(hip).origin+Vector3(0,offset.y*ratio,0))
	# Cierre exacto del loop evita saltos al reiniciar.
	for tr in range(out.get_track_count()):
		out.track_set_key_value(tr,out.track_get_key_count(tr)-1,out.track_get_key_value(tr,0))
	var lib := AnimationLibrary.new()
	lib.add_animation("RunningMan",out)
	assert(ResourceSaver.save(lib,"res://assets/dance/running_man.tres") == OK)
	print("RETARGET ",mapping.size()," huesos, ",out.length," s, ratio ",ratio," target ",target_path)
	var audit := {"source_clip":source_clip,"duration":out.length,"mapped_bones":mapping.size(),"height_ratio":ratio,"pairs":pairs}
	FileAccess.open("res://assets/dance/retarget.json",FileAccess.WRITE).store_string(JSON.stringify(audit,"  "))
	quit()

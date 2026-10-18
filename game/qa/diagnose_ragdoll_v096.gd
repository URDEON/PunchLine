extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var lab: Node3D = load("res://main.tscn").instantiate()
	root.add_child(lab)
	await physics_frame
	lab.set_physics_process(false); lab.set_process(false)
	var ctl: Node = lab.physical_ragdoll
	lab.play_rig_animation("combat/Uppercut",0,1,true); lab.rig_anim.seek(.15,true)
	var sk: Skeleton3D = ctl.skeleton
	sk.force_update_all_bone_transforms()
	ctl.start(Vector3(5,3,-2))
	for frame in range(180):
		await physics_frame
		ctl.transfer_physical_pose(); sk.force_update_all_bone_transforms()
		if frame in [0,20,60,179]:
			var max_error := 0.0
			for i in range(sk.get_bone_count()):
				var rest: Vector3 = sk.get_bone_rest(i).origin
				var pose: Vector3 = sk.get_bone_pose_position(i)
				if sk.get_bone_name(i) != "B_Pelvis": max_error = maxf(max_error,rest.distance_to(pose)*sk.global_basis.get_scale().x)
			print("FRAME ",frame," MAX_LOCAL_TRANSLATION_ERROR_METERS ",max_error)
			for bone in ctl.bodies:
				var index: int = ctl.physics_skeleton.find_bone(bone.bone_name)
				print(bone.bone_name," parent=",ctl.physics_skeleton.get_bone_name(ctl.physics_skeleton.get_bone_parent(index))," world=",bone.global_position)
	quit()

extends "res://scripts/physical_ragdoll.gd"
# Estructuras reales del Mech Pack, sin renombrar ni alterar el skin.
var foot_bind: Dictionary = {}
func setup(owner_actor: Node3D, visual_holder: Node3D, sk: Skeleton3D, player: AnimationPlayer, tree: AnimationTree = null) -> void:
	super.setup(owner_actor,visual_holder,sk,player,tree)
	for side in ["L","R"]:
		var end := sk.find_bone("FootBack."+side); var control := sk.find_bone("Foot."+side)
		if end >= 0 and control >= 0:
			foot_bind[side] = sk.get_bone_global_rest(end).affine_inverse()*sk.get_bone_global_rest(control)

func _process(delta: float) -> void:
	if not holder.is_visible_in_tree() or paused: return
	var was_recovering := recovering > 0
	super._process(delta)
	if not paused and not active and not was_recovering:
		attach_visual_feet(animator.current_animation != "RobotSweep")

func attach_visual_feet(preserve_rotation: bool = false) -> void:
	if foot_bind.is_empty(): return
	skeleton.force_update_all_bone_transforms()
	for side in foot_bind:
		var end := skeleton.find_bone("FootBack."+side); var control := skeleton.find_bone("Foot."+side)
		var pose: Transform3D = skeleton.get_bone_global_pose(end)*foot_bind[side]
		skeleton.set_bone_pose_position(control,pose.origin)
		if not preserve_rotation: skeleton.set_bone_pose_rotation(control,pose.basis.orthonormalized().get_rotation_quaternion())

func transfer_physical_pose() -> void:
	super.transfer_physical_pose()
	attach_visual_feet()
func pelvis_name() -> String: return "Body"
func torso_name() -> String: return "Chest"
func segment_fallback() -> float: return .55
func hinge_bone(name: String) -> bool: return "LowerArm" in name or knee_bone(name)
func knee_bone(name: String) -> bool: return "LowerLeg" in name or "MidLeg" in name
func hip_bone(name: String) -> bool: return "UpperLeg" in name
func right_elbow_bone(name: String) -> bool: return name == "LowerArm.R"
func physical_definitions() -> Array:
	var result: Array = [["Body","Torso",.45,10.0],["Torso","Chest",.42,6.0],["Chest","Neck",.48,9.0],["Head","",.32,3.0]]
	for side in ["L","R"]:
		if skeleton.find_bone("UpperArm."+side) >= 0:
			result.append_array([["UpperArm."+side,"LowerArm."+side,.30,2.5],["LowerArm."+side,"PalmI."+side,.28,2.0]])
		var mid: String = "MidLeg."+side
		result.append(["UpperLeg."+side,mid if skeleton.find_bone(mid) >= 0 else "LowerLeg."+side,.30,4.0])
		if skeleton.find_bone(mid) >= 0: result.append([mid,"LowerLeg."+side,.16,2.0])
		# Foot.L/R son controles IK independientes; Leela/George sí tienen skin en ellos.
		# FootBack pertenece a la cadena de la pierna en Leela y George.
		var end: String = "FootBack."+side
		result.append(["LowerLeg."+side,end if skeleton.find_bone(end) >= 0 else "",.12,2.0])
		if skeleton.find_bone(end) >= 0: result.append([end,"",.14,1.0])
		if contact_hulls.has(skeleton.find_bone("Foot."+side)):
			result.append(["Foot."+side,"",.20,1.0])
	return result

func dynamic_translation(index: int) -> bool:
	return index == pelvis_index or skeleton.get_bone_name(index) in ["Foot.L","Foot.R"]

func joint_parent(index: int, physical: Dictionary) -> int:
	var name := physics_skeleton.get_bone_name(index)
	if name in ["Foot.L","Foot.R"]: return physics_skeleton.find_bone("LowerLeg."+name.get_slice(".",1))
	return super.joint_parent(index,physical)

func bounded_rotation(index: int, rotation: Quaternion) -> Quaternion:
	if dynamic_translation(index): return rotation.normalized()
	return super.bounded_rotation(index,rotation)

var recovery_untracked: Array[Dictionary] = []
func stop(recover: bool = true) -> void:
	var was_active := active
	super.stop(recover)
	if not was_active: return
	recovery_untracked.clear()
	# Every original clip may omit Body rotation and IK foot channels.
	var tracked_positions: Dictionary = {}; var tracked_rotations: Dictionary = {}
	for key in animator.get_animation_list():
		if String(key) == "RESET": continue
		var clip := animator.get_animation(key)
		for track in range(clip.get_track_count()):
			var path := clip.track_get_path(track)
			if path.get_subname_count() == 0: continue
			var index := skeleton.find_bone(path.get_subname(0))
			if clip.track_get_type(track) == Animation.TYPE_POSITION_3D: tracked_positions[index] = true
			if clip.track_get_type(track) == Animation.TYPE_ROTATION_3D: tracked_rotations[index] = true
	for index in range(skeleton.get_bone_count()):
		recovery_untracked.append({"position":not tracked_positions.has(index),"rotation":not tracked_rotations.has(index)})
	skeleton.reset_bone_poses()
	if animator.current_animation != "": animator.advance(0)
	attach_visual_feet()

func blend_recovery(delta: float) -> void:
	if active: return
	for index in range(recovery_untracked.size()):
		if recovery_untracked[index].rotation: skeleton.set_bone_pose_rotation(index,rest_rotations[index])
		if recovery_untracked[index].position: skeleton.set_bone_pose_position(index,rest_positions[index])
	if recovering <= 0: return
	recovering = maxf(0,recovering-delta)
	var weight := smoothstep(0,.34,recovering)
	for index in range(skeleton.get_bone_count()):
		skeleton.set_bone_pose_rotation(index,skeleton.get_bone_pose_rotation(index).slerp(recovery_rotations[index],weight))
		if skeleton.get_bone_name(index) in ["Foot.L","Foot.R"]:
			skeleton.set_bone_pose_position(index,skeleton.get_bone_pose_position(index).lerp(recovery_positions[index],weight))
	attach_visual_feet()

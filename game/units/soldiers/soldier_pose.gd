extends SkeletonModifier3D
## Bounded corrections after AnimationTree: torso aim, crouch and local head visibility.
var visual: Node3D
var crouch := 0.0
var pitch := 0.0
var recoil := 0.0
var first_person := false

func _process_modification() -> void:
	if visual==null: return
	var skeleton: Skeleton3D = get_skeleton()
	var hips: int = visual.bones.pelvis
	var position := skeleton.get_bone_pose_position(hips)
	position.y -= crouch*0.43
	skeleton.set_bone_pose_position(hips,position)
	for pair in [["spine",0.35],["chest",0.65]]:
		var index: int = visual.bones[pair[0]]
		var rotation := skeleton.get_bone_pose_rotation(index)
		skeleton.set_bone_pose_rotation(index,rotation*Quaternion(Vector3.RIGHT,-pitch*float(pair[1])+recoil))
	for side in ["l","r"]:
		for pair in [["thigh_",0.8],["shin_",-1.35],["foot_",0.45]]:
			var index: int = visual.bones[pair[0]+side]
			skeleton.set_bone_pose_rotation(index,skeleton.get_bone_pose_rotation(index)*Quaternion(Vector3.RIGHT,float(pair[1])*crouch))
	skeleton.set_bone_pose_scale(visual.bones.head,Vector3.ONE*(0.001 if first_person else 1.0))

extends SkeletonModifier3D
## Original clips own gait; this modifier owns dash and clearance corrections.
var game: Node3D
var source: Dictionary
var rig: Skeleton3D
var bones: Dictionary = {}
var pose_cache: Dictionary = {}
var last_frame := -1

func setup(host: Node3D,data: Dictionary) -> void:
	game = host; source = data; rig = data.skeleton
	rig.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_PHYSICS
	for bone in ["Body","Torso","Chest","Head","UpperArm.L","UpperArm.R","LowerArm.L","LowerArm.R"]:
		var index := rig.find_bone(bone)
		if index >= 0: bones[bone] = index

func reset_motion() -> void:
	pose_cache.clear(); last_frame = -1

func _process_modification() -> void:
	if not is_instance_valid(game) or not game.is_inside_tree(): return
	var session: Node = game.online_session()
	if session != null and not session.is_host(): return
	if not game.robots.active or game.robots.current.get("skeleton") != rig or game.fusion.busy() or game.paused or game.player_ragdoll or game.physical_ragdoll.active or game.physical_ragdoll.recovering > 0:
		reset_motion(); return
	var frame := Engine.get_physics_frames()
	if last_frame == frame: return
	last_frame = frame; pose_cache.clear()
	var clearance: Node = game.robot_clearance
	var crouch: float = clearance.blend
	var grounded: bool = game.player.is_on_floor()
	var combat: bool = game.attack_anim > 0 or not game.robots.attack.is_empty() or game.block or game.stun > 0
	var dashing: bool = game.dash_time > 0 or game.robots.sidestep_time > 0
	var grounding: Node = source.get("grounding")
	var foot_targets: Dictionary = {}
	if crouch > .001 and grounding != null:
		for side in grounding.feet:
			var foot: Dictionary = grounding.feet[side]
			foot_targets[side] = grounding.foot_point(foot)
	if dashing and not combat:
		var direction: Vector3 = game.dash_dir if game.dash_time > 0 else game.robots.sidestep_direction
		var local: Vector3 = game.rig_holder.global_basis.orthonormalized().inverse()*direction
		turn("Torso",Vector3(local.z*.28,0,-local.x*.22))
		turn("Chest",Vector3(-local.z*.10,0,local.x*.08))
		for side in ["L","R"]:
			turn("UpperArm."+side,Vector3(-.30,0,.10 if side == "L" else -.10))
	if crouch > .001 and bones.has("Body"):
		var body_pose: Transform3D = rig.global_transform*rig.get_bone_global_pose(bones.Body)
		body_pose.origin.y -= (clearance.full_height-clearance.current_height)*.94
		rig.set_bone_global_pose(bones.Body,rig.global_transform.affine_inverse()*body_pose)
		turn("Torso",Vector3(crouch*.14,0,0)); turn("Chest",Vector3(-crouch*.10,0,0))
		for side in foot_targets:
			var foot: Dictionary = grounding.feet[side]
			var target: Vector3 = foot_targets[side]
			if grounded and foot.valid: target.y = maxf(target.y,foot.ground.y)
			grounding.solve_chain(foot,target,PI)
			if foot.end >= 0:
				var pose: Transform3D = rig.get_bone_global_pose(foot.end)*foot.bind
				rig.set_bone_pose_position(foot.control,pose.origin)
	for index in range(rig.get_bone_count()):
		pose_cache[index] = {"position":rig.get_bone_pose_position(index),"rotation":rig.get_bone_pose_rotation(index)}

func turn(bone: String,angle: Vector3) -> void:
	if bones.has(bone):
		var index: int = bones[bone]
		rig.set_bone_pose_rotation(index,rig.get_bone_pose_rotation(index)*Quaternion.from_euler(angle))

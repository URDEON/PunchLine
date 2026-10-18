extends "res://tools/retarget_ual2.gd"
func extra_clips() -> Array: return ["Yes","Idle_No_Loop","Idle_FoldArms_Loop","Idle_TalkingPhone_Loop","NinjaJump_Start","NinjaJump_Idle_Loop","NinjaJump_Land"]
func output_library() -> String: return "res://assets/animation_sources/ual2/extras_v096.tres"
func run() -> void:
	var source: Node3D = load("res://assets/animation_sources/ual2/UAL2_Standard.glb").instantiate()
	var target: Node3D = load("res://assets/characters/alien/Alien_Naoya_Rig_Combat.glb").instantiate()
	root.add_child(source); root.add_child(target)
	ss = skeleton(source); ts = skeleton(target); sa = animator(source); ta = animator(target)
	target_path = ta.get_node(ta.root_node).get_path_to(ts)
	var pairs := {"B_Pelvis":"pelvis","B_Spine":"spine_01","B_Spine1":"spine_02","B_Spine2":"spine_03","B_Neck":"neck_01","B_Head":"Head"}
	for side in ["L","R"]:
		var s: String = side.to_lower()
		for p in [["Clavicle","clavicle"],["UpperArm","upperarm"],["Forearm","lowerarm"],["Hand","hand"],["Thigh","thigh"],["Calf","calf"],["Foot","foot"],["Toe0","ball"]]: pairs["B_"+side+"_"+p[0]] = p[1]+"_"+s
		for finger in range(5):
			for j in range(3):
				var dst: String = "B_"+side+"_Finger"+str(finger)+(str(j) if j > 0 else "")
				if side == "R" and finger == 0 and j > 0: dst = "B_R_Finger0.00"+str(j)
				pairs[dst] = ["thumb","index","middle","ring","pinky"][finger]+"_0"+str(j+1)+"_"+s
	for i in range(ts.get_bone_count()):
		if pairs.has(ts.get_bone_name(i)):
			var src := ss.find_bone(pairs[ts.get_bone_name(i)])
			assert(src >= 0); mapping[i] = src
	ratio = (ts.global_transform*ts.get_bone_global_rest(ts.find_bone("B_Pelvis")).origin).y/(ss.global_transform*ss.get_bone_global_rest(ss.find_bone("pelvis")).origin).y
	var library := AnimationLibrary.new()
	for clip in extra_clips():
		lock_pelvis_vertical = clip.begins_with("NinjaJump")
		library.add_animation(clip,bake(clip,clip.ends_with("Loop")))
	assert(ResourceSaver.save(library,output_library()) == OK)
	print("RETARGET EXTRAS ",extra_clips().size()," clips, ",mapping.size()," huesos")
	source.free(); target.free(); quit()

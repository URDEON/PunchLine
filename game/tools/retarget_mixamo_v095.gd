extends "res://tools/retarget_ual2.gd"
# Se reutiliza el adaptador de deltas globales probado; los FBX se inspeccionaron.
func run() -> void:
	var target: Node3D = load("res://assets/characters/alien/Alien_Naoya_Rig_Combat.glb").instantiate()
	root.add_child(target)
	ts = skeleton(target); ta = animator(target)
	target_path = ta.get_node(ta.root_node).get_path_to(ts)
	source_pelvis_name = "mixamorig_Hips"
	var pairs := {"B_Pelvis":"Hips","B_Spine":"Spine","B_Spine1":"Spine1","B_Spine2":"Spine2","B_Neck":"Neck","B_Head":"Head"}
	for side in ["L","R"]:
		var full: String = "Left" if side == "L" else "Right"
		for p in [["Clavicle","Shoulder"],["UpperArm","Arm"],["Forearm","ForeArm"],["Hand","Hand"],["Thigh","UpLeg"],["Calf","Leg"],["Foot","Foot"],["Toe0","ToeBase"]]: pairs["B_"+side+"_"+p[0]] = full+p[1]
		for finger in range(5):
			for joint in range(3):
				var dst: String = "B_"+side+"_Finger"+str(finger)+(str(joint) if joint > 0 else "")
				if side == "R" and finger == 0 and joint > 0: dst = "B_R_Finger0.00"+str(joint)
				pairs[dst] = full+"Hand"+["Thumb","Index","Middle","Ring","Pinky"][finger]+str(joint+1)
	var library := AnimationLibrary.new()
	var audit: Array[Dictionary] = []
	var sources := ["Cross_Punch","Elbow_Punching","Crouch_To_Stand","Falling","Kick_To_The_Groin","idle","walking","running","jump","left_strafe_walking","right_strafe_walking","left_strafe","right_strafe","left_turn","right_turn","left_turn_90","right_turn_90"]
	for name in sources:
		var source: Node3D = load("res://assets/animation_sources/mixamo/converted/"+name+".glb").instantiate()
		root.add_child(source)
		ss = skeleton(source); sa = animator(source)
		mapping.clear()
		for i in range(ts.get_bone_count()):
			if not pairs.has(ts.get_bone_name(i)): continue
			var src := ss.find_bone("mixamorig_"+pairs[ts.get_bone_name(i)])
			assert(src >= 0,"Hueso ausente")
			mapping[i] = src
		ratio = (ts.global_transform*ts.get_bone_global_rest(ts.find_bone("B_Pelvis")).origin).y/(ss.global_transform*ss.get_bone_global_rest(ss.find_bone(source_pelvis_name)).origin).y
		lock_pelvis_vertical = name in ["Falling","jump"]
		var loop: bool = name in ["idle","walking","running","left_strafe_walking","right_strafe_walking","left_strafe","right_strafe","Falling"]
		var clip := bake(name,loop)
		library.add_animation(name,clip)
		audit.append({"clip":name,"duration":clip.length,"source_bones":ss.get_bone_count(),"mapped_bones":mapping.size(),"target_bones":ts.get_bone_count(),"loop":loop,"pelvis_vertical_locked":lock_pelvis_vertical,"horizontal_root_motion":false})
		sa.stop();source.free()
	assert(ResourceSaver.save(library,"res://assets/animation_sources/mixamo/retargeted.tres") == OK)
	var combat := AnimationLibrary.new()
	for spec in [["Cross","Cross_Punch",0.32,0.1216,"B_R_Hand"],["Elbow","Elbow_Punching",0.32,0.1216,"B_R_Forearm"],["GroinKick","Kick_To_The_Groin",0.59,0.23,"B_R_Foot"]]:
		var clip: Animation = library.get_animation(spec[1])
		var contact := contact_time(clip,spec[4])
		combat.add_animation(spec[0],warp(clip,spec[2],contact,spec[3],spec[0]))
		audit.append({"combat":spec[0],"source":spec[1],"source_contact":contact,"gameplay_contact":spec[3],"duration":spec[2]})
	assert(ResourceSaver.save(combat,"res://assets/animation_sources/mixamo/combat.tres") == OK)
	FileAccess.open("res://assets/animation_sources/mixamo/retarget_report.json",FileAccess.WRITE).store_string(JSON.stringify(audit,"  "))
	print("RETARGET MIXAMO: 17 clips, 52 huesos, 3 variantes de contacto")
	target.free();quit()

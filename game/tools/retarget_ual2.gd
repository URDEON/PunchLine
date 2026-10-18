extends SceneTree
# Bake reproducible de clips reales: deltas globales, reposo destino intacto.
const ALIGN := Basis(Vector3.UP, PI)
var ss: Skeleton3D
var ts: Skeleton3D
var sa: AnimationPlayer
var ta: AnimationPlayer
var mapping := {}
var target_path: NodePath
var ratio := 1.0
var source_pelvis_name := "pelvis"
var lock_pelvis_vertical := false

func _initialize() -> void: call_deferred("run")
func skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node
	for child in node.get_children():
		var found := skeleton(child)
		if found != null: return found
	return null
func animator(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found := animator(child)
		if found != null: return found
	return null

func bake(name: String, loop: bool) -> Animation:
	var imported_name := name if sa.has_animation(name) else name.trim_suffix("_Loop")
	assert(sa.has_animation(imported_name),"Clip ausente: "+name)
	var original := sa.get_animation(imported_name)
	var out := Animation.new()
	out.resource_name = name
	out.length = original.length
	out.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var tracks := {}
	for i in range(ts.get_bone_count()):
		var track := out.add_track(Animation.TYPE_ROTATION_3D)
		out.track_set_path(track, NodePath(str(target_path)+":"+ts.get_bone_name(i)))
		tracks[i] = track
	var pelvis := ts.find_bone("B_Pelvis")
	var source_pelvis := ss.find_bone(source_pelvis_name)
	var hip_track := out.add_track(Animation.TYPE_POSITION_3D)
	out.track_set_path(hip_track, NodePath(str(target_path)+":B_Pelvis"))
	sa.play(imported_name)
	var count := ceili(out.length*60)
	var source_world := ss.global_basis.orthonormalized()
	var target_world := ts.global_basis.orthonormalized()
	for k in range(count+1):
		var time := out.length*float(k)/count
		sa.seek(minf(time,out.length-0.000001),true)
		ss.force_update_all_bone_transforms()
		var globals: Array[Basis] = []
		for bone in range(ts.get_bone_count()):
			var parent := ts.get_bone_parent(bone)
			var parent_basis := globals[parent] if parent >= 0 else Basis.IDENTITY
			var local := ts.get_bone_rest(bone).basis.orthonormalized()
			if mapping.has(bone):
				var src: int = mapping[bone]
				var rest := source_world*ss.get_bone_global_rest(src).basis.orthonormalized()
				var pose := source_world*ss.get_bone_global_pose(src).basis.orthonormalized()
				var delta := ALIGN*(pose*rest.inverse())*ALIGN.inverse()
				var desired := target_world.inverse()*delta*target_world*ts.get_bone_global_rest(bone).basis.orthonormalized()
				local = parent_basis.inverse()*desired
			out.rotation_track_insert_key(tracks[bone],time,local.get_rotation_quaternion().normalized())
			globals.append(parent_basis*local)
		var source_rest: Vector3 = ss.global_transform*ss.get_bone_global_rest(source_pelvis).origin
		var source_pose: Vector3 = ss.global_transform*ss.get_bone_global_pose(source_pelvis).origin
		var parent := ts.get_bone_parent(pelvis)
		var parent_basis: Basis = globals[parent] if parent >= 0 else Basis.IDENTITY
		var local_bounce := Vector3.ZERO if lock_pelvis_vertical else (ts.global_basis*parent_basis).inverse()*Vector3(0,(source_pose.y-source_rest.y)*ratio,0)
		out.position_track_insert_key(hip_track,time,ts.get_bone_rest(pelvis).origin+local_bounce)
	if loop:
		for tr in range(out.get_track_count()): out.track_set_key_value(tr,out.track_get_key_count(tr)-1,out.track_get_key_value(tr,0))
	return out

func contact_time(anim: Animation, preferred_bone: String) -> float:
	var bone := ts.find_bone(preferred_bone)
	var best := INF
	var time := anim.length*0.4
	ta.add_animation_library("sample",AnimationLibrary.new())
	ta.get_animation_library("sample").add_animation("clip",anim.duplicate(true))
	ta.clear_caches()
	ta.play("sample/clip")
	# El máximo avance del miembro útil fija el instante visual de contacto.
	for k in range(1,ceili(anim.length*60*0.80)):
		var sample := float(k)/60
		ta.seek(sample,true)
		ts.force_update_all_bone_transforms()
		var point: Vector3 = ts.global_transform*ts.get_bone_global_pose(bone).origin
		if point.z < best:
			best = point.z
			time = sample
	ta.stop(true)
	ta.remove_animation_library("sample")
	ta.clear_caches()
	return clampf(time,anim.length*0.15,anim.length*0.75)

func warp(original: Animation, duration: float, visual_contact: float, gameplay_contact: float, name: String) -> Animation:
	var out := Animation.new()
	out.resource_name = name
	out.length = duration
	for track in range(original.get_track_count()):
		var type := original.track_get_type(track)
		if type not in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D]: continue
		var target := out.add_track(type)
		out.track_set_path(target,original.track_get_path(track))
		for k in range(ceili(duration*120)+1):
			var time := minf(float(k)/120,duration)
			var source_time := lerpf(0,visual_contact,time/gameplay_contact) if time <= gameplay_contact else lerpf(visual_contact,original.length,(time-gameplay_contact)/(duration-gameplay_contact))
			match type:
				Animation.TYPE_POSITION_3D: out.position_track_insert_key(target,time,original.position_track_interpolate(track,source_time))
				Animation.TYPE_ROTATION_3D: out.rotation_track_insert_key(target,time,original.rotation_track_interpolate(track,source_time))
				Animation.TYPE_SCALE_3D: out.scale_track_insert_key(target,time,original.scale_track_interpolate(track,source_time))
	return out

func run() -> void:
	var source: Node3D = load("res://assets/animation_sources/ual2/UAL2_Standard.glb").instantiate()
	var target: Node3D = load("res://assets/characters/alien/Alien_Naoya_Rig_Combat.glb").instantiate()
	root.add_child(source)
	root.add_child(target)
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
		if not pairs.has(ts.get_bone_name(i)): continue
		var src := ss.find_bone(pairs[ts.get_bone_name(i)])
		assert(src >= 0,"Hueso ausente")
		mapping[i] = src
	ratio = (ts.global_transform*ts.get_bone_global_rest(ts.find_bone("B_Pelvis")).origin).y/(ss.global_transform*ss.get_bone_global_rest(ss.find_bone("pelvis")).origin).y
	var library := AnimationLibrary.new()
	for name in ["Melee_Hook","Melee_Hook_Rec","Idle_FoldArms_Loop","Yes"]:
		library.add_animation(name,bake(name,name.ends_with("Loop")))
	assert(ResourceSaver.save(library,"res://assets/animation_sources/ual2/retargeted.tres") == OK)
	var combat := AnimationLibrary.new()
	var audit: Array[Dictionary] = []
	var specs := [["RightJab","UnarmedAttackR1",0.32,0.1216,"B_R_Hand"],["LeftJab","UnarmedAttackL1",0.32,0.1216,"B_L_Hand"],["Hook","Melee_Hook",0.32,0.1216,"B_R_Hand"],["Finisher","UnarmedAttackL2",0.38,0.1596,"B_L_Hand"],["Uppercut","UnarmedAttackR3",0.38,0.1596,"B_R_Hand"],["Downslam","UnarmedAttackL3",0.38,0.1596,"B_L_Hand"],["Kick","UnarmedAttackKickR1",0.59,0.23,"B_R_Foot"]]
	for spec in specs:
		var clip: Animation = library.get_animation(spec[1]) if library.has_animation(spec[1]) else ta.get_animation(spec[1])
		var contact := contact_time(clip,spec[4])
		combat.add_animation(spec[0],warp(clip,spec[2],contact,spec[3],spec[0]))
		audit.append({"clip":spec[0],"source":spec[1],"source_contact":contact,"contact":spec[3],"duration":spec[2]})
	assert(ResourceSaver.save(combat,"res://assets/animation_sources/ual2/combat_timing.tres") == OK)
	FileAccess.open("res://assets/animation_sources/ual2/retarget_report.json",FileAccess.WRITE).store_string(JSON.stringify({"source_bones":ss.get_bone_count(),"mapped_bones":mapping.size(),"target_bones":ts.get_bone_count(),"alignment_yaw_degrees":180,"height_ratio":ratio,"root_motion":false,"adapted_clips":["Melee_Hook","Melee_Hook_Rec","Idle_FoldArms_Loop","Yes"],"combat":audit},"  "))
	print("RETARGET UAL2: ",mapping.size()," huesos; 4 clips; 7 ajustes de contacto")
	source.free(); target.free()
	quit()

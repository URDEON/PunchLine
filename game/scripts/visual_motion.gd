extends Node
# Mezcla visual únicamente: ninguna ventana de combate ni velocidad de cuerpo.
var game: Node3D
var skeleton: Skeleton3D
var bridge: Animation
var bridge_rotation_tracks: Array[int] = []
var bridge_position_tracks: Array[int] = []
var bridge_scale_tracks: Array[int] = []
var bridge_weight := 1.0
var guard_weight := 0.0
var speed_weight := 0.0
var recoil_was_active := false

func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node
	for child in node.get_children():
		var found := find_skeleton(child)
		if found != null: return found
	return null

func animation_node(name: String) -> AnimationNodeAnimation:
	var node := AnimationNodeAnimation.new()
	node.animation = StringName(name) if game.rig_anim.has_animation(name) else game.resolve_rig_animation(name)
	return node

func setup(host: Node3D) -> void:
	game = host
	skeleton = find_skeleton(game.rig_scene)
	var path: NodePath = game.rig_anim.get_node(game.rig_anim.root_node).get_path_to(skeleton)
	bridge = Animation.new()
	bridge.length = 1.0
	bridge.loop_mode = Animation.LOOP_LINEAR
	for i in range(skeleton.get_bone_count()):
		var bone_path := NodePath(str(path)+":"+skeleton.get_bone_name(i))
		var rt := bridge.add_track(Animation.TYPE_ROTATION_3D)
		bridge.track_set_path(rt,bone_path)
		bridge.rotation_track_insert_key(rt,0,skeleton.get_bone_pose_rotation(i))
		bridge_rotation_tracks.append(rt)
		var pt := bridge.add_track(Animation.TYPE_POSITION_3D)
		bridge.track_set_path(pt,bone_path)
		bridge.position_track_insert_key(pt,0,skeleton.get_bone_pose_position(i))
		bridge_position_tracks.append(pt)
		var st := bridge.add_track(Animation.TYPE_SCALE_3D)
		bridge.track_set_path(st,bone_path)
		bridge.scale_track_insert_key(st,0,skeleton.get_bone_pose_scale(i))
		bridge_scale_tracks.append(st)
	var library := AnimationLibrary.new()
	library.add_animation("PoseBridge",bridge)
	game.rig_anim.add_animation_library("visual",library)
	var space := AnimationNodeBlendSpace2D.new()
	space.min_space = Vector2(-1,-1)
	space.max_space = Vector2(1,1)
	space.sync = true
	for entry in [[Vector2.ZERO,"UnarmedRunForward"],[Vector2(0,-1),"UnarmedRunForward"],[Vector2(0,1),"UnarmedRunBackward"],[Vector2(-1,0),"UnarmedRunLeft"],[Vector2(1,0),"UnarmedRunRight"],[Vector2(-0.707,-0.707),"UnarmedRunForwardLeft"],[Vector2(0.707,-0.707),"UnarmedRunForwardRight"],[Vector2(-0.707,0.707),"UnarmedRunBackwardLeft"],[Vector2(0.707,0.707),"UnarmedRunBackwardRight"]]:
		var clip: String = {"UnarmedRunForward":"UnarmedRunForward","UnarmedRunLeft":"UnarmedRunLeft","UnarmedRunRight":"UnarmedRunRight"}.get(entry[1],entry[1])
		space.add_blend_point(animation_node(clip),entry[0])
	var walk := AnimationNodeBlendSpace2D.new()
	walk.min_space = Vector2(-1,-1)
	walk.max_space = Vector2(1,1)
	walk.sync = true
	for entry in [[Vector2.ZERO,"UnarmedStrafeForward"],[Vector2(0,-1),"UnarmedStrafeForward"],[Vector2(-1,0),"UnarmedStrafeLeft"],[Vector2(1,0),"UnarmedStrafeRight"],[Vector2(0,1),"UnarmedStrafeBackward"]]:
		walk.add_blend_point(animation_node(entry[1]),entry[0])
	var tree := AnimationNodeBlendTree.new()
	tree.add_node("Direction",space)
	tree.add_node("Cadence",AnimationNodeTimeScale.new())
	tree.connect_node("Cadence",0,"Direction")
	tree.add_node("Walk",walk)
	tree.add_node("WalkCadence",AnimationNodeTimeScale.new())
	tree.connect_node("WalkCadence",0,"Walk")
	tree.add_node("Gait",AnimationNodeBlend2.new())
	tree.connect_node("Gait",0,"WalkCadence")
	tree.connect_node("Gait",1,"Cadence")
	tree.add_node("Idle",animation_node("mixamo/idle"))
	tree.add_node("SpeedBlend",AnimationNodeBlend2.new())
	tree.connect_node("SpeedBlend",0,"Idle")
	tree.connect_node("SpeedBlend",1,"Gait")
	tree.add_node("GuardPose",animation_node("UnarmedBlock"))
	var guard := AnimationNodeBlend2.new()
	guard.filter_enabled = true
	var recoil := AnimationNodeOneShot.new()
	recoil.filter_enabled = true
	recoil.fadein_time = 0.035
	recoil.fadeout_time = 0.07
	var upper_root := skeleton.find_bone("B_Spine")
	for i in range(skeleton.get_bone_count()):
		var ancestor := i
		while ancestor >= 0 and ancestor != upper_root: ancestor = skeleton.get_bone_parent(ancestor)
		if ancestor == upper_root:
			var filter_path := NodePath(str(path)+":"+skeleton.get_bone_name(i))
			guard.set_filter_path(filter_path,true)
			recoil.set_filter_path(filter_path,true)
	tree.add_node("UpperGuard",guard)
	tree.connect_node("UpperGuard",0,"SpeedBlend")
	tree.connect_node("UpperGuard",1,"GuardPose")
	tree.add_node("RecoilPose",animation_node("UnarmedBlockGetHit1"))
	tree.add_node("RecoilCadence",AnimationNodeTimeScale.new())
	tree.connect_node("RecoilCadence",0,"RecoilPose")
	tree.add_node("GuardHit",recoil)
	tree.connect_node("GuardHit",0,"UpperGuard")
	tree.connect_node("GuardHit",1,"RecoilCadence")
	tree.add_node("Snapshot",animation_node("visual/PoseBridge"))
	tree.add_node("Bridge",AnimationNodeBlend2.new())
	tree.connect_node("Bridge",0,"Snapshot")
	tree.connect_node("Bridge",1,"GuardHit")
	tree.add_node("Playback",AnimationNodeTimeScale.new())
	tree.connect_node("Playback",0,"Bridge")
	tree.connect_node("output",0,"Playback")
	game.locomotion_tree = AnimationTree.new()
	game.rig_scene.add_child(game.locomotion_tree)
	game.locomotion_tree.anim_player = game.locomotion_tree.get_path_to(game.rig_anim)
	game.locomotion_tree.tree_root = tree
	game.locomotion_tree.active = false

func tick() -> void:
	var delta: float = game.get_physics_process_delta_time()
	var local_velocity: Vector3 = game.player.velocity.rotated(Vector3.UP,-game.model.rotation.y)
	var velocity := Vector2(local_velocity.x,local_velocity.z)
	# Suavizar la velocidad conserva la entrada y salida del movimiento.
	game.locomotion_vector = game.locomotion_vector.lerp((velocity/(game.SPEED*game.form_speed_mult())).limit_length(1),1-exp(-delta*18))
	if not game.locomotion_tree.active:
		for i in range(skeleton.get_bone_count()):
			bridge.track_set_key_value(bridge_rotation_tracks[i],0,skeleton.get_bone_pose_rotation(i))
			bridge.track_set_key_value(bridge_position_tracks[i],0,skeleton.get_bone_pose_position(i))
			bridge.track_set_key_value(bridge_scale_tracks[i],0,skeleton.get_bone_pose_scale(i))
		game.rig_anim.stop(true)
		game.rig_current_anim = StringName()
		bridge_weight = 0.0
		game.locomotion_tree.active = true
	bridge_weight = minf(1.0,bridge_weight+delta/0.14)
	speed_weight = lerpf(speed_weight,clampf(velocity.length()/1.25,0,1),1-exp(-delta*14))
	guard_weight = lerpf(guard_weight,1.0 if game.block else 0.0,1-exp(-delta*20))
	game.locomotion_tree.set("parameters/Direction/blend_position",game.locomotion_vector.normalized() if game.locomotion_vector.length() > 0.03 else Vector2(0,-1))
	game.locomotion_tree.set("parameters/Walk/blend_position",game.locomotion_vector.normalized() if game.locomotion_vector.length() > 0.03 else Vector2(0,-1))
	game.locomotion_tree.set("parameters/WalkCadence/scale",0.0 if game.impact_freeze > 0 else clampf(velocity.length()/2.2,0.12,1.65))
	game.locomotion_tree.set("parameters/Gait/blend_amount",smoothstep(2.4,4.8,velocity.length()))
	game.locomotion_tree.set("parameters/Cadence/scale",0.0 if game.impact_freeze > 0 else clampf(velocity.length()/5.5,0.12,1.6))
	game.locomotion_tree.set("parameters/SpeedBlend/blend_amount",speed_weight)
	game.locomotion_tree.set("parameters/UpperGuard/blend_amount",guard_weight)
	game.locomotion_tree.set("parameters/Bridge/blend_amount",bridge_weight)
	game.locomotion_tree.set("parameters/Playback/scale",0.0 if game.impact_freeze > 0 else 1.0)
	var hit: bool = game.block_recoil_time > 0
	if hit and not recoil_was_active:
		var clip: Animation = game.rig_anim.get_animation(game.resolve_rig_animation("UnarmedBlockGetHit1"))
		game.locomotion_tree.set("parameters/RecoilCadence/scale",clip.length/game.BLOCKSTUN_DURATION)
		game.locomotion_tree.set("parameters/GuardHit/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	recoil_was_active = hit

extends SceneTree
var game: Node3D
var checks := 0
var passed := 0
var previous: Dictionary = {}
var jump := 0.0
var angle_jump := 0.0
var samples := 0
var finite := true
func _initialize() -> void: run.call_deferred()
func check(ok: bool,title: String) -> void:
	checks += 1
	if ok: passed += 1
	print("PASS " if ok else "FAIL ",title)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func inspect() -> void:
	var modifier: Node = game.human_motion
	if not modifier.active:return
	var sk: Skeleton3D = game.visual_motion.skeleton
	for side in modifier.feet:
		var f: Dictionary = modifier.feet[side]
		var point: Vector3 = game.player.to_local(sk.global_transform*sk.get_bone_global_pose(f.bones[2]).origin)
		var knee: Quaternion = sk.get_bone_pose_rotation(f.bones[1])
		if previous.has(side):
			jump = maxf(jump,point.distance_to(previous[side][0]));angle_jump = maxf(angle_jump,knee.angle_to(previous[side][1]))
		previous[side] = [point,knee];samples += 1;finite = finite and point.is_finite()
func run() -> void:
	game = load("res://main.tscn").instantiate();root.add_child(game);await frames(15)
	for e in game.enemies:game.set_dummy_mode(e,0)
	var body := StaticBody3D.new();game.add_child(body);body.position = Vector3(400,-.1,0)
	var col := CollisionShape3D.new();var shape := BoxShape3D.new();shape.size = Vector3(100,.2,100);col.shape = shape;body.add_child(col)
	game.player.position = Vector3(400,.02,0);game.player.velocity = Vector3.ZERO;game.yaw = 0;game.camera_lock = true;await frames(25)
	game.human_motion.modification_processed.connect(inspect)
	for action in ["walk","forward","right","left","back"]:
		previous.clear();jump = 0;angle_jump = 0;samples = 0
		Input.action_press("forward" if action == "walk" else action)
		if action == "walk":Input.action_press("walk")
		await frames(110)
		Input.action_release("forward" if action == "walk" else action);Input.action_release("walk")
		check(finite and samples > 50,"huesos finitos y modificador activo: "+action)
		check(jump < .25 and angle_jump < .8,"transiciones sin saltos de pie/rodilla: "+action)
		print("HUMAN_MOTION ",action," ",{"foot_jump":jump,"knee_jump":angle_jump,"samples":samples})
		await frames(25)
	check(game.human_motion.contacts > 5,"apoyos detectados desde los clips originales")
	game.set_paused(true);await frames(3);check(not game.human_motion.active,"pausa desactiva correcciones")
	game.set_paused(false);await frames(10);check(game.human_motion.active,"reanudar restaura correcciones")
	game.queue_free();await frames(8);print("RESULTADO ",passed,"/",checks);quit(0 if passed == checks else 1)

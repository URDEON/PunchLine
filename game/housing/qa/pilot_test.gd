extends SceneTree
var game: Node3D
var checks:=0
var failures:=0
func _initialize() -> void:run.call_deferred()
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func run() -> void:
	game=load("res://main.tscn").instantiate();root.add_child(game);await frames(20)
	for e in game.enemies:game.set_dummy_mode(e,0)
	game.robots.forced=1;game.robots.select(1);await frames(35)
	game.charge=100
	check(game.fusion.request(),"real fusion starts at unobstructed parking spawn")
	if not game.fusion.cinematic:quit(1);return
	game.fusion.sequence.advance(11.5);await frames(40)
	check(game.fusion.fused,"production fused controller active")
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/generated_plan.json"))
	var b:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/pilot_plan.json")).buildings[0]
	var building:Node3D=game.arena.punchline.housing.get_node("GeneratedBuildings/"+b.lot+"/"+b.id)
	var outside:Vector3=building.to_global(Vector3(0,.015,b.depth/2+3))
	var inward:Vector3=-building.global_basis.z
	game.player.global_position=outside;game.player.velocity=Vector3.ZERO
	game.set_physics_process(false)
	var col:CollisionShape3D=game.robots.naoya.collision
	col.shape.height=4;col.position.y=2
	for i in range(100):
		await physics_frame;game.player.velocity=inward*4;game.player.move_and_slide()
	check(building.to_local(game.player.global_position).z>b.depth/2,"standing real capsule cannot cross workshop lintel")
	game.player.global_position=outside;game.player.velocity=Vector3.ZERO;game.yaw=atan2(-inward.x,-inward.z);game.model.rotation.y=game.yaw;game.camera_lock=true
	game.set_physics_process(true);Input.action_press("forward")
	for i in range(240):
		await physics_frame
		if i%60==59:
			print("TRACE ",i," pos=",building.to_local(game.player.global_position)," vel=",game.player.velocity," height=",game.robot_clearance.current_height)
			for j in range(game.player.get_slide_collision_count()):
				var hit:KinematicCollision3D=game.player.get_slide_collision(j)
				print("TRACE_HIT ",hit.get_normal()," ",hit.get_collider().get_path())
	Input.action_release("forward");await frames(20)
	var local:Vector3=building.to_local(game.player.global_position)
	for i in range(game.player.get_slide_collision_count()):
		var hit:KinematicCollision3D=game.player.get_slide_collision(i)
		print("PILOT_COLLISION ",hit.get_normal()," ",hit.get_collider().get_path()," at ",building.to_local(hit.get_position()))
	print("PILOT_POSITION ",local," height=",game.robot_clearance.current_height," floor=",game.player.is_on_floor())
	check(local.z<0.5 and local.z>-b.depth/2,"real mecha enters workshop and passes connected interior")
	check(game.robot_clearance.current_height<3.6 and col.shape.radius>1.04,"real crouch preserves capsule width")
	await frames(60)
	check(game.robot_clearance.current_height<3.6,"idle mecha stays crouched under roof")
	var rig:Node3D=game.fusion.sequence.articulation
	var ik_error:=0.0
	for side in ["Der","Izq"]:ik_error=maxf(ik_error,float(rig.ik_error.get(side,0)))
	check(ik_error<.12,"real procedural feet retain IK reach under workshop roof")
	game.fusion.combat.interrupted();await frames(3)
	check(game.fusion.combat.press(1),"production cannon action accepts crouched mecha")
	await frames(55)
	check(not rig.action.get("id","").is_empty(),"skill pose remains active while crouched")
	game.fusion.combat.interrupted();await frames(15)
	check(not game.fusion.site_valid(game.player.global_position),"fusion occupancy check rejects workshop interior")
	Input.action_press("block");await frames(8)
	check(game.block and game.robot_clearance.current_height<3.6,"real block coexists with crouch posture")
	Input.action_release("block");await frames(4);game.dash_cd=0
	check(game.fusion.start_boost(),"real mecha dash/boost starts while crouched")
	await frames(45)
	var in_room:Vector3=building.to_local(game.player.global_position)
	check(game.player.global_position.is_finite() and in_room.y+game.robot_clearance.current_height<=b.height+.1 and game.player.is_on_floor(),"boost stops at roof/walls and settles without penetrating ceiling")

	game.yaw+=PI;game.model.rotation.y=game.yaw
	Input.action_press("forward");await frames(300);Input.action_release("forward");await frames(60)
	local=building.to_local(game.player.global_position)
	check(local.z>b.depth/2+1.2 and game.robot_clearance.current_height>3.98,"real mecha exits and gradually stands up")
	print("RESULT ",checks-failures,"/",checks," actual 0.9.24 fused robot")
	game.queue_free();await frames(8);quit(1 if failures else 0)

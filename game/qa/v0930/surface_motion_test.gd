extends SceneTree
var game:Node3D
var spider:Node3D
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func frames(count:int)->void:
	for i in range(count):await physics_frame
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func place(point:Vector3,up:=Vector3.UP,heading:=Vector3.FORWARD)->void:
	spider.clear_surface_path();game.player.global_position=point;game.player.velocity=Vector3.ZERO
	spider.normal=up;spider.forward=heading;spider.view_forward=heading
	spider.previous_yaw=game.yaw;spider.airborne=false;spider.air_velocity=Vector3.ZERO
	game.player.global_basis=Basis(heading.cross(up),up,-heading).orthonormalized()
	game.player.reset_physics_interpolation();spider.last_safe=game.player.global_transform
func run()->void:
	game=load("res://main.tscn").instantiate();root.add_child(game)
	while game.loading:await process_frame
	await frames(30)
	for enemy in game.enemies:game.set_dummy_mode(enemy,0)
	game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
	check(game.fusion.request(),"real Sentinel fusion starts")
	game.fusion.sequence.advance(11.5);await frames(40)
	spider=game.fusion.spider;check(spider.eject(),"real head ejects")
	await frames(150)
	var factory:Node3D=load("res://housing/scripts/DistrictHousingGenerator.gd").new();game.add_child(factory)
	factory.part(factory,"MotionFloor",Vector3(30,.4,30),Vector3(600,-.2,0),null)
	factory.part(factory,"MotionWall",Vector3(8,4,.3),Vector3(600,2,-3),null)
	factory.part(factory,"MotionCeiling",Vector3(8,.3,5),Vector3(600,4,-.5),null)
	factory.part(factory,"MotionCurb",Vector3(3,.20,2),Vector3(610,.1,0),null)
	game.set_process(false);game.yaw=0;game.pitch=0;game.zoom=0;game.camera_lock=false
	place(Vector3(600,.035,0));await frames(2);spider.camera_update(game.camera,1.0/60)
	var previous:Transform3D=game.player.global_transform
	var previous_camera:Transform3D=game.camera.global_transform
	var max_distance:=0.0;var max_angle:=0.0;var max_camera_angle:=0.0;var max_camera_distance:=0.0
	var clear:=true;var wall_frames:=0;var ceiling:=false;var turn_frames:=0;var camera_matches:=true
	Input.action_press("forward")
	for i in range(300):
		await physics_frame
		spider.camera_update(game.camera,1.0/60)
		var pose:Transform3D=game.player.global_transform
		max_distance=maxf(max_distance,pose.origin.distance_to(previous.origin))
		max_angle=maxf(max_angle,pose.basis.y.angle_to(previous.basis.y))
		max_camera_angle=maxf(max_camera_angle,game.camera.global_basis.get_rotation_quaternion().angle_to(previous_camera.basis.get_rotation_quaternion()))
		max_camera_distance=maxf(max_camera_distance,game.camera.global_position.distance_to(previous_camera.origin))
		clear=clear and spider.pose_fits(pose)
		var rendered:Transform3D=game.player.get_global_transform_interpolated()
		camera_matches=camera_matches and game.camera.global_basis.y.dot(rendered.basis.y)>.999
		if absf(spider.normal.y)<.1:wall_frames+=1
		if spider.normal.y<-.99:ceiling=true
		if not spider.surface_path.is_empty():turn_frames+=1
		previous=pose;previous_camera=game.camera.global_transform
		if ceiling and spider.surface_path.is_empty():break
	Input.action_release("forward")
	print("MOTION max_translation=",max_distance," max_rotation_deg=",rad_to_deg(max_angle)," camera_rotation_deg=",rad_to_deg(max_camera_angle)," camera_translation=",max_camera_distance," transition_frames=",turn_frames," position=",game.player.global_position)
	check(wall_frames>25 and ceiling,"continuous input reaches both wall and ceiling")
	check(turn_frames>=24,"corners traverse the checked arc over multiple physics frames")
	check(max_distance<.105,"no physical position jump over 10.5 cm at 60 Hz")
	check(max_angle<.105,"surface rotation remains below 6 degrees per physics frame")
	check(max_camera_angle<.14 and max_camera_distance<.14,"eye camera moves and turns continuously through both corners")
	check(camera_matches,"eye horizon uses the exact visible body's interpolated up axis")
	check(clear,"full armour volume stays outside floor, wall and ceiling throughout turns")
	place(Vector3(600,.035,0));game.zoom=3;await frames(2)
	spider.camera_update(game.camera,1.0/60);previous_camera=game.camera.global_transform
	max_camera_distance=0;var orbit_clear:=true;ceiling=false
	var eye_shape:=SphereShape3D.new();eye_shape.radius=.19
	Input.action_press("forward")
	for i in range(300):
		await physics_frame;spider.camera_update(game.camera,1.0/60)
		max_camera_distance=maxf(max_camera_distance,game.camera.global_position.distance_to(previous_camera.origin))
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=eye_shape
		query.transform.origin=game.camera.global_position;query.collision_mask=1;query.exclude=[game.player.get_rid()]
		orbit_clear=orbit_clear and game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
		previous_camera=game.camera.global_transform
		if spider.normal.y<-.99 and spider.surface_path.is_empty():ceiling=true;break
	Input.action_release("forward");game.zoom=0
	print("ORBIT max_translation=",max_camera_distance)
	check(ceiling and max_camera_distance<.36,"third-person corner orbit approaches the protected eye without switching anchors")
	check(orbit_clear,"third-person camera volume remains outside wall, floor and ceiling during turns")
	# Traverse an actual raised curb using the same measured and swept path.
	place(Vector3(610,.035,2));await frames(2)
	previous=game.player.global_transform;max_distance=0;clear=true;var reached_curb:=false
	Input.action_press("forward")
	for i in range(85):
		await physics_frame
		max_distance=maxf(max_distance,game.player.global_position.distance_to(previous.origin))
		clear=clear and spider.pose_fits(game.player.global_transform)
		if game.player.global_position.y>.22 and game.player.global_position.z<.8:reached_curb=true
		previous=game.player.global_transform
	Input.action_release("forward")
	print("CURB max_translation=",max_distance," position=",game.player.global_position)
	check(reached_curb and max_distance<.105 and clear,"raised curb is traversed smoothly without a vertical teleport or overlap")
	place(Vector3(600,.035,-2.35));await frames(2)
	check(spider.try_surface(Vector3(600,.48,-2.85),Vector3.BACK),"a gradual turn can accept a jump request")
	await frames(5);spider.request_jump()
	var jumped:=false
	for i in range(55):
		await physics_frame
		jumped=jumped or (spider.airborne and spider.detach_time>.1)
	check(jumped,"jump pressed during a corner executes after the checked turn completes")
	# New geometry can obstruct a previously valid trajectory. It must stop safely.
	place(Vector3(600,.035,-2.35));await frames(2)
	check(spider.try_surface(Vector3(600,.48,-2.85),Vector3.BACK),"wall transition can be planned")
	var blocked_before:int=spider.blocked_transitions
	var obstruction:Node3D=factory.part(factory,"NewObstacle",Vector3(2,.2,1),Vector3(600,.95,-2),null)
	clear=true
	for i in range(40):
		await physics_frame
		clear=clear and spider.pose_fits(game.player.global_transform)
		if spider.surface_path.is_empty():break
	check(spider.surface_path.is_empty() and spider.blocked_transitions>blocked_before and clear,"a newly blocked path cancels before moving into the obstacle")
	obstruction.queue_free();await frames(3)
	# Return/death must discard any in-flight surface animation.
	place(spider.mecha_origin+Vector3(0,.035,2.2));await frames(2)
	check(spider.request_return(),"normal reconnection remains available")
	await frames(80)
	check(not spider.active() and spider.surface_path.is_empty(),"reconnection clears surface transition state")
	print("RESULT ",checks-failures,"/",checks," surface motion checks")
	game.queue_free();await frames(8);quit(1 if failures else 0)

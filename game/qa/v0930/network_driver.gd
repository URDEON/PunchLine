extends "res://qa/v0929/network_driver.gd"
var motion_checked:=false
var watched:=0
var previous_pose:=Transform3D.IDENTITY
var peak_angle:=0.0
var peak_speed:=0.0
var peak_distance:=0.0
var watched_frames:=0
var saw_wall:=false
var saw_ceiling:=false
func await_spider(actor:Node3D)->void:
	await super.await_spider(actor)
	if host and actor.peer_id==1 and not motion_checked:
		motion_checked=true
		await motion_checks(actor)
@rpc("authority","call_remote","reliable")
func make_motion_fixture()->void:
	var factory:Node3D=load("res://housing/scripts/DistrictHousingGenerator.gd").new();arena.add_child(factory)
	factory.part(factory,"NetworkMotionFloor",Vector3(20,.4,20),Vector3(600,-.2,0),null)
	factory.part(factory,"NetworkMotionWall",Vector3(8,4,.3),Vector3(600,2,-3),null)
	factory.part(factory,"NetworkMotionCeiling",Vector3(8,.3,5),Vector3(600,4,-.5),null)
@rpc("authority","call_remote","reliable")
func monitor_motion(enabled:bool)->void:
	if enabled:
		watched=1;previous_pose=arena.session.actors[1].player.global_transform
		peak_angle=0;peak_speed=0;peak_distance=0;watched_frames=0;saw_wall=false;saw_ceiling=false
	else:
		watched=0
		observation.rpc_id(1,"motion",{"angle":peak_angle,"speed":peak_speed,"distance":peak_distance,"frames":watched_frames,"wall":saw_wall,"ceiling":saw_ceiling})
func _process(delta:float)->void:
	if watched==0:return
	var actor:Node3D=arena.session.actors.get(watched)
	if actor==null or not actor.fusion.spider.active():return
	var pose:Transform3D=actor.player.global_transform
	var angle:float=previous_pose.basis.y.angle_to(pose.basis.y)
	peak_angle=maxf(peak_angle,angle);peak_speed=maxf(peak_speed,angle/maxf(.001,delta))
	peak_distance=maxf(peak_distance,pose.origin.distance_to(previous_pose.origin));watched_frames+=1
	saw_wall=saw_wall or absf(pose.basis.y.y)<.1
	saw_ceiling=saw_ceiling or pose.basis.y.y<-.99
	previous_pose=pose
func motion_checks(actor:Node3D)->void:
	var peer:=0
	for id in arena.session.actors:
		if int(id)!=1:peer=int(id)
	make_motion_fixture();make_motion_fixture.rpc_id(peer)
	var spider:Node3D=actor.fusion.spider
	spider.clear_surface_path();actor.player.global_position=Vector3(600,.035,0);actor.player.velocity=Vector3.ZERO
	spider.normal=Vector3.UP;spider.forward=Vector3.FORWARD;spider.view_forward=spider.forward
	spider.previous_yaw=0;spider.airborne=false;actor.player.global_basis=Basis.IDENTITY
	yaw=0;await pause(.65)
	monitor_motion.rpc_id(peer,true);axis=Vector2(0,-1)
	var clear:=true;var ceiling:=false
	for i in range(270):
		await get_tree().physics_frame
		clear=clear and spider.pose_fits(actor.player.global_transform)
		ceiling=ceiling or spider.normal.y<-.99
	axis=Vector2.ZERO;await pause(.4);monitor_motion.rpc_id(peer,false)
	var deadline:=Time.get_ticks_msec()+5000
	while not reports.has("motion") and Time.get_ticks_msec()<deadline:await pause(.03)
	var report:Dictionary=reports.get("motion",{})
	print("NETWORK_MOTION ",report)
	check(clear and ceiling,"host traverses floor, wall and ceiling without armour overlap over ENet")
	check(report.get("wall",false) and report.get("ceiling",false) and int(report.get("frames",0))>100,"receiving peer sees the complete gradual surface traversal")
	check(float(report.get("angle",99))<.35 and float(report.get("speed",99))<9,"replica surface orientation interpolates between 20 Hz snapshots without a 90 degree snap")
	check(float(report.get("distance",99))<.18,"replica position remains continuous through both corners")
	spider.clear_surface_path();actor.player.global_position=spider.mecha_origin+Vector3(0,.035,2.2)
	actor.player.velocity=Vector3.ZERO;actor.player.global_basis=Basis.IDENTITY
	spider.normal=Vector3.UP;spider.forward=Vector3.FORWARD;spider.view_forward=spider.forward
	await pause(.5)

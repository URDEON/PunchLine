extends Node
var arena:Node3D
var host:=false
var started:=0.0
var reports:Dictionary={}
var checks:=0
var failures:=0
var axis:=Vector2.ZERO
var yaw:=0.0
var timer:=0.0
var ended:=false
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func pause(s:float)->void:await get_tree().create_timer(s).timeout
func _ready()->void:
	host=OS.get_cmdline_user_args().has("--housing-host");started=Time.get_ticks_msec()/1000.0
	arena=load("res://network/online.tscn").instantiate();add_child(arena)
	arena.set_physics_process(false) # The QA driver supplies input; keep Session and actor physics running.
	arena.menu_open=false
	await pause(.3)
	if host:
		check(arena.session.host_game("HousingHost",1,17963)==OK,"host opens real ENet session")
		run_host()
	else:
		var error:Error=arena.session.join_game("127.0.0.1",17963,"HousingClient",0)
		if error!=OK:push_error("ENet client join failed");get_tree().quit(1)
func _physics_process(delta:float)->void:
	if ended:return
	if Time.get_ticks_msec()/1000.0-started>100:
		print("FAIL housing network timeout");get_tree().quit(1);return
	if arena==null or not arena.session.active:return
	timer+=delta
	if timer>=1.0/30:
		timer=0;arena.session.local_input(axis,yaw,0)
@rpc("authority","call_remote","reliable")
func inspect(tag:String,tamper:=false)->void:
	var actor:Node3D=arena.session.actors.get(1)
	if actor==null:observation.rpc_id(1,tag,{});return
	if tamper:
		actor.player.position=Vector3(999,999,999)
		await pause(1.0)
	var col:CollisionShape3D=actor.robots.naoya.collision
	observation.rpc_id(1,tag,{"height":actor.robot_clearance.current_height,"capsule":col.shape.height,"position":actor.player.position,"fused":actor.fusion.fused,"snapshots":arena.session.telemetry.snapshots,"visual":actor.fusion.visual()!=null})
@rpc("any_peer","call_remote","reliable")
func observation(tag:String,data:Dictionary)->void:
	if host:reports[tag]=data
@rpc("authority","call_remote","reliable")
func finished()->void:
	print("PASS client received completion after authoritative snapshots");arena.session.leave();get_tree().quit(0)
func ask(id:int,tag:String,tamper:=false)->Dictionary:
	inspect.rpc_id(id,tag,tamper)
	var deadline:=Time.get_ticks_msec()+5000
	while not reports.has(tag) and Time.get_ticks_msec()<deadline:await pause(.05)
	return reports.get(tag,{})
func run_host()->void:
	var deadline:=Time.get_ticks_msec()+50000
	while (arena.session.actors.size()<2 or arena.session.ready_peers.size()<1) and Time.get_ticks_msec()<deadline:await pause(.1)
	check(arena.session.actors.size()==2 and arena.session.ready_peers.size()==1,"host and client finish model loading over ENet")
	if arena.session.actors.size()!=2:finish();return
	var peer:=0
	for id in arena.session.actors:
		if int(id)!=1:peer=int(id)
	var pilot:Node3D=arena.session.actors[1]
	await pause(.5);pilot.charge=100
	check(pilot.fusion.request(),"authoritative robot starts real fusion")
	if not pilot.fusion.cinematic:finish();return
	pilot.fusion.sequence.advance(11.5);await pause(.6)
	var b:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/pilot_plan.json")).buildings[0]
	var building:Node3D=arena.map.housing.get_node("GeneratedBuildings/"+b.lot+"/"+b.id)
	pilot.player.global_position=building.to_global(Vector3(0,.02,1.8));pilot.player.velocity=Vector3.ZERO
	await pause(1.2)
	var report:Dictionary=await ask(peer,"crouch")
	check(pilot.robot_clearance.current_height<3.6,"host enforces crouch under workshop roof")
	check(report.get("fused",false) and report.get("visual",false) and report.get("snapshots",0)>0,"client renders fused actor from real snapshots")
	check(absf(float(report.get("height",99))-pilot.robot_clearance.current_height)<.1,"posture height matches on host and client")
	check(absf(float(report.get("capsule",99))-pilot.robots.naoya.collision.shape.height)<.1,"client collision capsule follows authoritative posture")
	report=await ask(peer,"tamper",true)
	check(report.get("position",Vector3(999,999,999)).distance_to(pilot.player.position)<.25,"client position tampering is replaced by server snapshots")
	var inward:Vector3=-building.global_basis.z
	yaw=atan2(-inward.x,-inward.z)+PI;axis=Vector2(0,-1)
	await pause(4.8);axis=Vector2.ZERO;await pause(1.2)
	report=await ask(peer,"exit")
	check(building.to_local(pilot.player.position).z>b.depth/2 and pilot.robot_clearance.current_height>3.98,"host leaves doorway and restores standing posture")
	check(float(report.get("height",0))>3.98,"client receives standing recovery")
	finish()
func finish()->void:
	ended=true
	for id in arena.session.actors:
		if int(id)!=1:finished.rpc_id(int(id))
	print("RESULT ",checks-failures,"/",checks," host/client real ENet")
	await pause(.3);arena.session.leave();get_tree().quit(1 if failures else 0)

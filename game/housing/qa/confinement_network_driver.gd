extends "res://housing/qa/network_driver.gd"
func _ready() -> void:
	host=OS.get_cmdline_user_args().has("--housing-host");started=Time.get_ticks_msec()/1000.0
	arena=load("res://network/online.tscn").instantiate();add_child(arena)
	arena.set_physics_process(false);arena.menu_open=false
	await pause(.3)
	if host:
		check(arena.session.host_game("ContactHost",1,17965)==OK,"host opens real ENet confinement session");run_host()
	elif arena.session.join_game("127.0.0.1",17965,"ContactClient",1)!=OK:get_tree().quit(1)
@rpc("authority","call_remote","reliable")
func inspect(tag: String,tamper:=false) -> void:
	var actor: Node3D=arena.session.actors.get(1)
	if actor==null:observation.rpc_id(1,tag,{});return
	if tamper:
		actor.robot_clearance.contacts={"Der":{"point":Vector3(999,999,999),"normal":Vector3.UP,"weight":1,"kind":"wall"}}
		actor.robot_clearance.pressure=0
		await pause(1.0)
	var rig: Node3D=actor.fusion.sequence.articulation
	observation.rpc_id(1,tag,{"height":actor.robot_clearance.current_height,"capsule":actor.robots.naoya.collision.shape.height,"position":actor.player.position,"contacts":actor.robot_clearance.contacts.duplicate(true),"pressure":actor.robot_clearance.pressure,"hands":rig.confinement.hand_errors.duplicate(),"fused":actor.fusion.fused})
func run_host() -> void:
	var deadline:=Time.get_ticks_msec()+50000
	while (arena.session.actors.size()<2 or arena.session.ready_peers.size()<1) and Time.get_ticks_msec()<deadline:await pause(.1)
	check(arena.session.actors.size()==2 and arena.session.ready_peers.size()==1,"host/client load the same expanded house geometry")
	if arena.session.actors.size()!=2:finish();return
	var peer:=0
	for id in arena.session.actors:
		if int(id)!=1:peer=int(id)
	var actor: Node3D=arena.session.actors[1];await pause(.5);actor.charge=100
	check(actor.fusion.request(),"authoritative robot starts its actual fusion")
	if not actor.fusion.cinematic:finish();return
	actor.fusion.sequence.advance(11.5);await pause(.7)
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/generated_plan.json"))
	var b: Dictionary={}
	for candidate in plan.buildings:
		if candidate.access=="player_only" and int(candidate.style.palette)==6:b=candidate;break
	var house: Node3D=arena.map.housing.get_node("GeneratedBuildings/"+b.lot+"/"+b.id)
	actor.player.global_position=house.to_global(Vector3(0,.02,b.depth/2+2.5));actor.player.velocity=Vector3.ZERO
	var inward: Vector3=-house.global_basis.z
	yaw=atan2(-inward.x,-inward.z);actor.model.rotation.y=yaw
	await pause(.3);axis=Vector2(0,-1);await pause(4.4);axis=Vector2.ZERO;await pause(.8)
	var report: Dictionary=await ask(peer,"blue")
	check(house.to_local(actor.player.position).z<0 and actor.player.is_on_floor(),"server-controlled mecha crosses the blue entrance and interior partition")
	check(report.get("fused",false) and absf(float(report.get("height",99))-actor.robot_clearance.current_height)<.1,"client receives the actual crouched height")
	check(absf(float(report.get("capsule",99))-actor.robots.naoya.collision.shape.height)<.1,"client keeps its physical capsule consistent with the server")
	check(report.get("contacts",{}).has("Izq") and report.contacts.Izq.kind=="ceiling","actual ceiling contact target replicates to the client")
	check(float(report.get("hands",{}).get("Izq",99))<.22,"client arm IK reaches the replicated roof target")
	var front: float=house.get_node("Doors/Threshold").position.z+.06
	actor.player.global_position=house.to_global(Vector3(b.width/2-.4-1.05-.06,.025,front*.5));actor.player.velocity=Vector3.ZERO
	await pause(1.8);report=await ask(peer,"wall")
	var wall_side: String=""
	for side in actor.robot_clearance.contacts:
		if actor.robot_clearance.contacts[side].kind=="wall":wall_side=side
	check(not wall_side.is_empty() and report.get("contacts",{}).get(wall_side,{}).get("kind","")=="wall","wall contact and pressure replicate to the other player")
	check(float(report.get("hands",{}).get(wall_side,99))<.22,"remote articulated hand touches the actual wall")
	report=await ask(peer,"tamper",true)
	check(report.get("contacts",{}).get(wall_side,{}).get("point",Vector3(999,999,999)).distance_to(actor.robot_clearance.contacts.get(wall_side,{}).get("point",Vector3.ZERO))<.15 and float(report.get("pressure",0))>.5,"server replaces local contact/pressure tampering")
	actor.player.global_position=house.to_global(Vector3(0,.025,b.depth/2+6));actor.player.velocity=Vector3.ZERO
	await pause(1.7);report=await ask(peer,"open")
	check(actor.robot_clearance.current_height>3.98 and float(report.get("height",0))>3.98,"host and client restore full height in open air")
	check(float(report.get("pressure",1))<.03 and report.get("hands",{}).is_empty(),"remote contact poses release after leaving the house")
	finish()

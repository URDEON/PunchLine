extends "res://housing/qa/confinement_network_driver.gd"
var tower: Dictionary
var house: Node3D
@rpc("authority","call_remote","reliable")
func inspect(tag: String,tamper:=false) -> void:
	var actor: Node3D=arena.session.actors.get(1)
	if actor==null:observation.rpc_id(1,tag,{});return
	if tamper:actor.player.position=Vector3(999,999,999);await pause(1.0)
	var rig: Node3D=actor.fusion.sequence.articulation
	observation.rpc_id(1,tag,{"position":actor.player.position,"height":actor.robot_clearance.current_height,"capsule":actor.robots.naoya.collision.shape.height,"hands":rig.confinement.hand_errors.duplicate(),"version":actor.interface.metric.text,"protocol":arena.session.PROTOCOL,"buildings":arena.map.housing.get_node("GeneratedBuildings").find_children("Building_*","Node3D",true,false).size()})
func drive(actor: Node3D,point: Vector3) -> bool:
	var target: Vector3=house.to_global(point)
	for i in range(220):
		var offset: Vector3=target-actor.player.global_position;offset.y=0
		if offset.length()<.35:
			axis=Vector2.ZERO;await pause(.3)
			return absf(actor.player.global_position.y-target.y)<.3
		yaw=atan2(-offset.x,-offset.z);axis=Vector2(0,-1);await pause(.05)
	axis=Vector2.ZERO
	print("NETWORK_BLOCKED ",house.to_local(actor.player.global_position)," target=",point)
	return false
func run_host() -> void:
	var deadline:=Time.get_ticks_msec()+50000
	while (arena.session.actors.size()<2 or arena.session.ready_peers.size()<1) and Time.get_ticks_msec()<deadline:await pause(.1)
	check(arena.session.actors.size()==2 and arena.session.ready_peers.size()==1,"both peers load the complete 0.9.25 district")
	if arena.session.actors.size()!=2:finish();return
	var peer:=0
	for id in arena.session.actors:
		if int(id)!=1:peer=int(id)
	var actor: Node3D=arena.session.actors[1];await pause(.5);actor.charge=100
	check(actor.fusion.request(),"network mecha performs normal production fusion")
	if not actor.fusion.cinematic:finish();return
	actor.fusion.sequence.advance(11.5);await pause(.7)
	tower=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/multistorey_plan.json")).buildings[0]
	house=arena.map.housing.get_node("GeneratedBuildings/"+tower.lot+"/"+tower.id)
	actor.player.global_position=house.to_global(Vector3(0,.025,10));actor.player.velocity=Vector3.ZERO
	await pause(.3)
	var complete: bool=await drive(actor,Vector3(0,.025,2.5))
	var route: Array=house.get_meta("stair_route")
	for point in route.slice(0,4):
		if complete:complete=await drive(actor,point)
	check(complete and absf(house.to_local(actor.player.position).y-3.6)<.15,"authoritative mecha walks through the door and up both flights to floor two")
	if not complete:finish();return
	await pause(.6);var report: Dictionary=await ask(peer,"upstairs")
	check(report.get("buildings",0)==77,"client loads 71 preserved houses and six additional towers")
	check(absf(house.to_local(report.get("position",Vector3.ZERO)).y-3.6)<.15,"client displays the real elevated actor position")
	check(absf(float(report.get("height",99))-actor.robot_clearance.current_height)<.1 and absf(float(report.get("capsule",99))-actor.robots.naoya.collision.shape.height)<.1,"upper-floor posture and capsule replicate correctly")
	check(str(report.get("version","")).contains(str(ProjectSettings.get_setting("application/config/version"))),"online HUD shows the current release version")
	check(str(report.get("protocol","")).contains(str(ProjectSettings.get_setting("application/config/version"))),"network compatibility includes the same project version")
	check(float(report.get("hands",{}).get("Izq",99))<.22,"remote hand reaches the actual upper-floor ceiling")
	report=await ask(peer,"tamper",true)
	check(report.get("position",Vector3.ZERO).distance_to(actor.player.position)<.3,"server restores client position tampering on an upper floor")
	var back: Array=route.slice(0,4);back.reverse()
	for point in back:
		if complete:complete=await drive(actor,point)
	if complete:complete=await drive(actor,Vector3(0,.025,10))
	check(complete and house.to_local(actor.player.position).z>8,"network mecha walks downstairs and exits")
	await pause(1.2);report=await ask(peer,"outside")
	check(float(report.get("height",0))>3.98,"client receives full standing recovery outside the tower")
	finish()

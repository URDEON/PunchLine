extends "res://housing/qa/network_driver.gd"
func digest()->String:
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256)
	for cell in arena.map.ambience.placement.chunks:hash.update(arena.map.ambience.placement.chunks[cell].to_byte_array())
	return hash.finish().hex_encode()
func _ready()->void:
	host=OS.get_cmdline_user_args().has("--housing-host");started=Time.get_ticks_msec()/1000.0
	timeout_seconds=200
	arena=load("res://network/online.tscn").instantiate();add_child(arena);arena.set_physics_process(false);arena.menu_open=false
	await pause(.3)
	if host:
		check(arena.session.host_game("GreenHost",1,17966)==OK,"host opens actual ENet greenery session");run_host()
	elif arena.session.join_game("127.0.0.1",17966,"GreenClient",1)!=OK:get_tree().quit(1)
@rpc("authority","call_remote","reliable")
func inspect(tag:String,_tamper:=false)->void:
	if tag=="local_off":
		arena.preferences.values.grass_quality=0;arena.preferences.values.fog_amount=0;arena.preferences.apply()
	var actor:Node3D=arena.session.actors.get(1)
	var a:Node3D=arena.map.ambience
	observation.rpc_id(1,tag,{"hash":digest(),"grass":a.placement.count,"fog":a.environment.volumetric_fog_enabled,"quality":arena.preferences.values.grass_quality,"hp":actor.hp if actor else 0,"position":actor.player.global_position if actor else Vector3.ZERO,"snapshots":arena.session.telemetry.snapshots})
func run_host()->void:
	var deadline:=Time.get_ticks_msec()+100000
	while (arena.session.actors.size()<2 or arena.session.ready_peers.size()<1) and Time.get_ticks_msec()<deadline:await pause(.1)
	check(arena.session.actors.size()==2 and arena.session.ready_peers.size()==1,"both real clients finish loading the complete map")
	if arena.session.actors.size()!=2:finish();return
	var peer:=0
	for id in arena.session.actors:
		if int(id)!=1:peer=int(id)
	var report:Dictionary=await ask(peer,"initial")
	check(report.get("hash","")==digest() and int(report.get("grass",0))>50000,"host and client generate exactly the same common-district grass")
	check(report.get("fog",false) and arena.map.ambience.environment.volumetric_fog_enabled,"both online environments use native volumetric fog")
	var actor:Node3D=arena.session.actors[1];var start:Vector3=actor.player.global_position
	axis=Vector2(0,-1);await pause(1.2);axis=Vector2.ZERO;await pause(.3)
	report=await ask(peer,"movement")
	check(actor.player.global_position.distance_to(start)>1.5,"decoration preserves authoritative player movement")
	check(report.get("position",Vector3(999,999,999)).distance_to(actor.player.global_position)<.35 and int(report.get("snapshots",0))>0,"movement still reaches the client through real snapshots")
	report=await ask(peer,"local_off")
	check(not report.get("fog",true) and int(report.get("quality",-1))==0,"client can disable fog and grass locally")
	check(arena.map.ambience.environment.volumetric_fog_enabled and int(arena.preferences.values.grass_quality)>0,"client graphics settings do not alter host graphics")
	check(float(report.get("hp",0))==actor.hp and report.get("hash","")==digest(),"local quality changes preserve health and seeded world data")
	finish()

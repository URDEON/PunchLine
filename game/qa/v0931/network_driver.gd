extends "res://qa/v0930/network_driver.gd"
var cargo_testing:=false
var cargo_axis:=Vector3.ZERO
var cargo_timer:=0.0
@rpc("authority","call_remote","reliable")
func cargo_command(action:String)->void:arena.session.local_cargo_command(action)
@rpc("authority","call_remote","reliable")
func cargo_controls(enabled:bool,axis_value:=Vector3.ZERO)->void:
	arena.map.cargo.set_process(not enabled);cargo_testing=enabled;cargo_axis=axis_value
@rpc("authority","call_remote","reliable")
func inspect_extra(tag:String)->void:
	observation.rpc_id(1,tag,{"cargo":arena.map.cargo.state(),"settled":arena.map.destruction.settled_structures.duplicate(true)})
func extra(peer:int,tag:String)->Dictionary:
	inspect_extra.rpc_id(peer,tag)
	var deadline:=Time.get_ticks_msec()+5000
	while not reports.has(tag) and Time.get_ticks_msec()<deadline:await pause(.03)
	return reports.get(tag,{})
func _physics_process(delta:float)->void:
	super._physics_process(delta)
	if not host and cargo_testing:
		cargo_timer+=delta
		if cargo_timer>=1.0/30:cargo_timer=0;arena.session.local_cargo_input(cargo_axis)
func world_damage_checks(peer:int)->void:
	await super.world_damage_checks(peer)
	var cargo:Node3D=arena.map.cargo
	var pilot:Node3D=arena.session.actors[peer]
	pilot.player.global_position=cargo.console+Vector3(0,.1,2);pilot.player.velocity=Vector3.ZERO
	await pause(.6);cargo_command.rpc_id(peer,"toggle");await pause(.3)
	check(cargo.operator==peer,"remote owner operates the crane through host-validated console proximity")
	check(not cargo.command(1,"grab"),"host player cannot seize another player's crane")
	cargo_command.rpc_id(peer,"grab");await pause(.3)
	check(cargo.load_index>=0,"remote grab attaches the authoritative hollow container")
	var index:int=cargo.load_index
	if index>=0:
		var start:Vector3=cargo.containers[index].position
		cargo_controls.rpc_id(peer,true,Vector3(.7,1,0));await pause(1.25)
		cargo_controls.rpc_id(peer,true,Vector3.ZERO);await pause(.6)
		var report:Dictionary=await extra(peer,"lifted")
		check(cargo.containers[index].position.y>start.y+1 and cargo.containers[index].position.x>start.x+1,"remote controls raise and translate cargo on the host")
		var error:float=report.get("cargo",{}).get("containers",[])[index].distance_to(cargo.containers[index].position) if report.has("cargo") else 999
		check(error<.08 and int(report.get("cargo",{}).get("load",-1))==index,"receiving peer renders the same lifted container and collision pose")
		cargo_controls.rpc_id(peer,true,Vector3(0,-1,0));await pause(1.8)
		cargo_controls.rpc_id(peer,true,Vector3.ZERO);await pause(.3);cargo_command.rpc_id(peer,"grab");await pause(.4)
		check(cargo.load_index<0 and cargo.containers[index].position.y<.08,"remote operator lowers and releases the moved container")
	cargo_command.rpc_id(peer,"toggle");cargo_controls.rpc_id(peer,false);await pause(.3)
	check(cargo.operator==0,"remote exit releases crane ownership")
	await pause(3.0)
	var d:Node3D=arena.map.destruction
	var settled_report:Dictionary=await extra(peer,"settled")
	check(not d.settled_structures.is_empty() and settled_report.get("settled",{})==d.settled_structures,"host and client keep identical solid settled roof geometry after collapse")
	reset_client_world.rpc_id(peer);arena.session.district_state.rpc_id(peer,d.state());await pause(.35)
	settled_report=await extra(peer,"settled_late")
	check(settled_report.get("settled",{})==d.settled_structures,"late-join reconstruction restores the same settled roof collisions")

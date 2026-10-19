extends "res://housing/qa/network_driver.gd"
func _ready()->void:
	Engine.set_meta("punchline_world",preload("res://scripts/world_config.gd").normalized({"seed":"ENet jardín 929" if OS.get_cmdline_user_args().has("--housing-host") else "different local seed","density":2,"night":true,"destructible":true}))
	host=OS.get_cmdline_user_args().has("--housing-host");started=Time.get_ticks_msec()/1000.0;timeout_seconds=240.0
	arena=load("res://network/online.tscn").instantiate();add_child(arena);arena.set_physics_process(false);arena.menu_open=false
	while arena.loading:await get_tree().process_frame
	await pause(.3)
	if host:
		var stale_key:String=arena.map.destruction.parts.keys()[0]
		arena.map.destruction.apply_packet({"revision":1,"damaged":{stale_key:0.0}},false)
		check(arena.session.host_game("SpiderHost",1,17969)==OK,"host opens real ENet spider session")
		check(arena.map.destruction.revision==0 and not arena.map.destruction.parts[stale_key].broken,"starting a new server clears previous world destruction");run_host()
	else:
		if arena.session.join_game("127.0.0.1",17969,"SpiderClient",1)!=OK:get_tree().quit(1)
@rpc("authority","call_remote","reliable")
func inspect(tag:String,tamper:=false)->void:
	var actor:Node3D=arena.session.actors.get(1)
	if actor==null:observation.rpc_id(1,tag,{});return
	if tamper:actor.player.position=Vector3(999,999,999);actor.hp=999;await pause(1.0)
	var s:Node3D=actor.fusion.spider
	observation.rpc_id(1,tag,{"overload":actor.self_destruct.state(),"camera_lock":actor.camera_lock,"steps":s.rig.step_count if is_instance_valid(s.rig) else 0,"mode":s.mode,"hp":actor.hp,"max_hp":actor.max_hp,"capsule":actor.robots.naoya.collision.shape.height,"position":actor.player.position,"up":actor.player.up_direction,"cloak":s.cloak_time,"scan":s.scan_time,"mecha":s.mecha_origin,"head_hidden":not actor.fusion.sequence.articulation.pivots.Cabeza.visible if is_instance_valid(actor.fusion.sequence) else false,"fused":actor.fusion.fused,"vision":s.vision_mode})
@rpc("authority","call_remote","reliable")
func owner_action(action:String)->void:
	if action=="hold_g":held_flags=32;return
	if action=="release_g":held_flags=0;return
	arena.session.local_action(action)
func await_spider(actor:Node3D)->void:
	var deadline:=Time.get_ticks_msec()+10000
	while actor.fusion.spider.mode!="spider" and Time.get_ticks_msec()<deadline:await pause(.05)
	# Allow the next snapshot to reach the observing peer after the state transition.
	await pause(.25)
@rpc("authority","call_remote","reliable")
func owner_camera_probe()->void:
	arena.zoom=0
	var event:=InputEventMouseMotion.new();event.relative=Vector2(0,-320)
	arena._unhandled_input(event)
	var actor:Node3D=arena.session.actors[arena.session.local_id()]
	var spider:Node3D=actor.fusion.spider;spider.camera_update(arena.camera,1.0/60)
	var eye_masked:bool=(spider.rig.mesh.layers & arena.camera.cull_mask)==0
	var full_pitch:float=arena.pitch
	var toggle:=InputEventKey.new();toggle.keycode=KEY_V;toggle.pressed=true;arena._unhandled_input(toggle)
	arena.pitch=0;spider.camera_update(arena.camera,1.0/60)
	var third:bool=not arena.camera_view.active and spider.rig.mesh.layers==1
	var distance:float=arena.zoom
	var wheel:=InputEventMouseButton.new();wheel.pressed=true;wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;arena._unhandled_input(wheel)
	spider.camera_update(arena.camera,1.0/60)
	for i in range(3):arena.session.local_action("vision");await pause(.25)
	var vision:bool=spider.vision_mode==3 and is_instance_valid(spider.vision) and spider.vision.mode==3 and spider.vision.copies.size()>0
	var start:Vector3=actor.player.global_position
	var jump:=InputEventKey.new();jump.keycode=arena.preferences.bindings.jump;jump.pressed=true;arena._unhandled_input(jump)
	await pause(.20)
	observation.rpc_id(1,"owner_camera",{"pitch":full_pitch,"mode":spider.mode,"hp":actor.hp,"eye_masked":eye_masked,"third":third,"zoom_adjusted":arena.zoom>distance,"airborne":spider.airborne,"rise":actor.player.global_position.y-start.y,"visions":vision})
func run_host()->void:
	var deadline:=Time.get_ticks_msec()+50000
	while (arena.session.actors.size()<2 or arena.session.ready_peers.size()<1) and Time.get_ticks_msec()<deadline:await pause(.1)
	check(arena.session.actors.size()==2 and arena.session.ready_peers.size()==1,"host and client finish actual model loading")
	if arena.session.actors.size()!=2:finish();return
	var peer:=0
	for id in arena.session.actors:
		if int(id)!=1:peer=int(id)
	await world_damage_checks(peer)
	var actor:Node3D=arena.session.actors[1];await pause(.5);actor.charge=100
	check(actor.fusion.request(),"host performs actual robot fusion")
	if not actor.fusion.cinematic:finish();return
	actor.fusion.sequence.advance(11.5);await pause(.6)
	arena.session.local_action("interact");await await_spider(actor)
	var report:Dictionary=await ask(peer,"eject")
	check(actor.fusion.spider.mode=="spider" and report.get("mode","")=="spider","E ejection is authoritative and replicated")
	check(report.get("hp",0)==50 and report.get("max_hp",0)==50,"client receives separate 50 HP spider pool")
	check(absf(float(report.get("capsule",9))-actor.robots.naoya.collision.shape.height)<.01,"client collider keeps spider size instead of mecha clearance height")
	check(report.get("head_hidden",false),"client hides parked mecha head")
	arena.session.local_action("vision");await pause(.25);report=await ask(peer,"vision")
	check(actor.fusion.spider.vision_mode==1 and report.get("vision",0)==1,"vision input and camera mode replicate authoritatively")
	var lock_before:bool=actor.camera_lock
	arena.session.local_action("lock");await pause(.4);report=await ask(peer,"unlock")
	check(actor.camera_lock!=lock_before and report.get("camera_lock",lock_before)==actor.camera_lock,"spider camera lock toggles on authority and receiving peer")
	arena.session.local_action("ability2");await pause(.5);report=await ask(peer,"cloak")
	check(float(report.get("cloak",0))>0 and actor.fusion.spider.invisible(),"camouflage state replicates from host")
	arena.session.local_action("ability1");await pause(.5);report=await ask(peer,"scan")
	check(float(report.get("scan",0))>0 and float(report.get("cloak",99))==0,"scanner state and cloak cancellation replicate")
	report=await ask(peer,"tamper",true)
	check(report.get("position",Vector3(999,999,999)).distance_to(actor.player.position)<.25 and float(report.get("hp",999))==50,"client position and HP tampering overwritten by authoritative snapshots")
	actor.player.global_position=actor.fusion.spider.mecha_origin+Vector3(0,.025,2.2);actor.player.velocity=Vector3.ZERO
	arena.session.local_action("interact");await pause(1.5);report=await ask(peer,"return")
	check(not actor.fusion.spider.active() and report.get("mode","")=="attached" and report.get("fused",false),"nearby reconnection restores mecha on both peers")
	check(float(report.get("max_hp",0))==300 and float(report.get("capsule",0))>3.9,"mecha health pool and full collider restored on client")
	actor.fusion.spider.return_cd=0;await pause(.2)
	arena.session.local_action("interact");await pause(2.5);actor.fusion.spider.take_damage(50)
	check(actor.hp==0 and actor.death_timer>0,"spider destruction enters original authoritative player death flow")
	await pause(4.6)
	check(arena.session.actors.has(1) and arena.session.actors[1].hp>0 and not arena.session.actors[1].fusion.fused,"normal respawn completes after spider death")
	# The remote owner sends ordinary inputs; the host still decides ejection and return.
	actor=arena.session.actors[peer];actor.charge=100
	check(actor.fusion.request(),"remote player's actual robot can also fuse")
	if actor.fusion.cinematic:
		actor.fusion.sequence.advance(11.5);await pause(.7)
		owner_action.rpc_id(peer,"interact");await pause(2.5)
		check(actor.fusion.spider.mode=="spider" and actor.hp==50,"remote client E input creates its own authoritative spider")
		owner_camera_probe.rpc_id(peer)
		var camera_deadline:=Time.get_ticks_msec()+5000
		while not reports.has("owner_camera") and Time.get_ticks_msec()<camera_deadline:await pause(.05)
		check(float(reports.get("owner_camera",{}).get("pitch",0))>.25 and reports.get("owner_camera",{}).get("mode","")=="spider","remote spider camera supports the full first-person pitch range")
		var camera:Dictionary=reports.get("owner_camera",{})
		check(camera.get("visions",false) and actor.fusion.spider.vision_mode==3,"remote owner cycles all three vision modes through server input")
		check(camera.get("eye_masked",false),"remote owner's eye camera excludes only its own spider mesh")
		check(camera.get("third",false) and camera.get("zoom_adjusted",false),"remote owner switches to third person and adjusts camera distance")
		check(camera.get("airborne",false) and float(camera.get("rise",0))>.1 and actor.fusion.spider.airborne,"remote jump input is simulated on host and replicated to owner")
		await pause(.9)
		check(not actor.fusion.spider.airborne and actor.fusion.spider.normal.y>.9,"authoritative remote spider lands and reattaches")
		actor.player.global_position=actor.fusion.spider.mecha_origin+Vector3(0,.025,2.2);actor.player.velocity=Vector3.ZERO
		owner_action.rpc_id(peer,"interact");await pause(1.5)
		check(not actor.fusion.spider.active() and actor.fusion.fused,"remote client E input reconnects through host validation")
	await critical_checks(peer)
	finish()

@rpc("authority","call_remote","reliable")
func inspect_world(tag:String,key:String,tamper:=false)->void:
	var d:Node3D=arena.map.destruction
	var before:int=d.revision
	if tamper:d.damage_area(d.parts[key].box.get_center(),8,1000,Vector3.UP)
	observation.rpc_id(1,tag,{"hash":arena.map.layout_hash,"settings":arena.map.world_settings,"broken":d.parts[key].broken,"disabled":d.parts[key].collision.disabled,"revision":d.revision,"before":before,"rubble":rubble_layout(d),"fractures":d.fractures.keys(),"damaged":d.damaged.duplicate()})
func world_damage_checks(peer:int)->void:
	var d:Node3D=arena.map.destruction;var key:String=d.parts.keys()[0]
	inspect_world.rpc_id(peer,"world_before",key)
	while not reports.has("world_before"):await pause(.05)
	check(reports.world_before.hash==arena.map.layout_hash and reports.world_before.settings==arena.map.world_settings,"host seed, density, night and destructibility replace different client settings")
	d.damage_area(d.parts[key].box.get_center(),.08,60,Vector3.RIGHT);await pause(.3)
	inspect_world.rpc_id(peer,"world_damage",key)
	while not reports.has("world_damage"):await pause(.05)
	check(reports.world_damage.broken and reports.world_damage.disabled and reports.world_damage.revision==d.revision,"real ENet damage removes the same wall and collider on both peers")
	check(reports.world_damage.fractures==d.fractures.keys() and reports.world_damage.damaged==d.damaged,"fracture cells and localized damage match over real ENet")
	inspect_world.rpc_id(peer,"world_tamper",key,true)
	while not reports.has("world_tamper"):await pause(.05)
	check(reports.world_tamper.revision==reports.world_tamper.before,"client cannot apply authoritative building damage")
	arena.session.configure_world.rpc_id(peer,arena.map.world_settings);await pause(.2)
	inspect_world.rpc_id(peer,"new_same_world",key)
	while not reports.has("new_same_world"):await pause(.05)
	check(not reports.new_same_world.broken and reports.new_same_world.revision==0,"new session config clears stale client damage even with the same seed")
	var saved:Dictionary=d.state()
	# Reset just the client, then replay the same late-join state path used by roster readiness.
	reset_client_world.rpc_id(peer);arena.session.district_state.rpc_id(peer,saved);await pause(.25)
	inspect_world.rpc_id(peer,"world_late_state",key)
	while not reports.has("world_late_state"):await pause(.05)
	check(reports.world_late_state.broken and reports.world_late_state.disabled and reports.world_late_state.revision==d.revision,"late-join full state restores previously destroyed geometry and collision")
	var roof:Dictionary={}
	for p in d.parts.values():
		if p.category!="Roof" or p.broken:continue
		var distant:=true
		for actor in arena.session.actors.values():
			if actor.player.global_position.distance_to(p.box.get_center())<40:distant=false
		if distant:roof=p;break
	d.damage_area(roof.box.get_center(),.08,100,Vector3.UP);await pause(.25)
	inspect_world.rpc_id(peer,"physical_rubble",key)
	while not reports.has("physical_rubble"):await pause(.05)
	check(not d.physical_rubble.is_empty() and reports.physical_rubble.rubble==rubble_layout(d),"persistent walkable rubble uses identical collision geometry on host and client")
	var rubble_state:Dictionary=d.state()
	reset_client_world.rpc_id(peer);arena.session.district_state.rpc_id(peer,rubble_state);await pause(.25)
	inspect_world.rpc_id(peer,"late_rubble",key)
	while not reports.has("late_rubble"):await pause(.05)
	check(reports.late_rubble.rubble==rubble_layout(d),"late-join reconstruction restores persistent physical rubble")
func rubble_layout(d:Node3D)->Dictionary:
	var result:Dictionary={}
	for id in d.physical_rubble:
		result[id]=[]
		for body in d.physical_rubble[id].get_children():
			if body is StaticBody3D:result[id].append({"pose":body.global_transform,"points":body.get_child(0).shape.points})
	return result
@rpc("authority","call_remote","reliable")
func reset_client_world()->void:arena.map.destruction.reset_world()

var held_flags:=0
func _physics_process(delta:float)->void:
	if ended:return
	if Time.get_ticks_msec()/1000.0-started>timeout_seconds:print("FAIL network timeout");get_tree().quit(1);return
	if arena==null or arena.loading or arena.session==null or not arena.session.active:return
	timer+=delta
	if timer>=1.0/30:
		timer=0;arena.session.local_input(axis,yaw,held_flags)
func critical_checks(peer:int)->void:
	var actor:Node3D=arena.session.actors.get(peer)
	if actor==null or not actor.fusion.fused:check(false,"remote mecha available for autodestruction");return
	actor.hp=60;actor.player.velocity=Vector3.ZERO
	owner_action.rpc_id(peer,"hold_g");await pause(1.3);owner_action.rpc_id(peer,"release_g");await pause(.4)
	check(not actor.self_destruct.armed and actor.self_destruct.charge==0,"remote release before three seconds cancels arming")
	owner_action.rpc_id(peer,"hold_g");await pause(3.25);owner_action.rpc_id(peer,"release_g")
	check(actor.self_destruct.armed and actor.self_destruct.remaining>2.4,"remote G hold is timed and armed by the host")
	inspect_overload.rpc_id(peer,"overload_armed",peer)
	var deadline:=Time.get_ticks_msec()+2000
	while not reports.has("overload_armed") and Time.get_ticks_msec()<deadline:await pause(.03)
	check(reports.get("overload_armed",{}).get("armed",false) and reports.get("overload_armed",{}).get("alarm",false) and float(reports.get("overload_armed",{}).get("alarm_distance",999))<2,"remote owner receives shutdown countdown and an alarm positioned on its own robot")
	await pause(3.0)
	check(actor.hp==0 and actor.fusion.death_broken and actor.self_destruct.detonations==1,"remote overload detonates once through authoritative damage and death")
	await pause(4.5)
	check(arena.session.actors[peer].hp>0 and not arena.session.actors[peer].fusion.fused,"remote overload completes normal network respawn")
@rpc("authority","call_remote","reliable")
func inspect_overload(tag:String,id:int)->void:
	var actor:Node3D=arena.session.actors.get(id)
	observation.rpc_id(1,tag,{"armed":actor.self_destruct.armed,"alarm":actor.self_destruct.alarm.playing,"alarm_distance":actor.self_destruct.alarm.global_position.distance_to(actor.player.global_position),"remaining":actor.self_destruct.remaining} if actor!=null else {})

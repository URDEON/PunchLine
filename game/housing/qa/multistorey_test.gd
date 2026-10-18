extends SceneTree
var game: Node3D
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func frames(n: int) -> void:
	for i in range(n):await physics_frame
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func drive(house: Node3D,point: Vector3) -> bool:
	var target: Vector3=house.to_global(point)
	for i in range(500):
		var offset: Vector3=target-game.player.global_position;offset.y=0
		if offset.length()<.24:
			Input.action_release("forward");await frames(20)
			return absf(game.player.global_position.y-target.y)<.25
		var direction: Vector3=offset.normalized()
		game.yaw=atan2(-direction.x,-direction.z);game.camera_lock=true
		Input.action_press("forward");await physics_frame
	Input.action_release("forward");await frames(10)
	print("BLOCKED target=",point," actual=",house.to_local(game.player.global_position)," height=",game.robot_clearance.current_height)
	for i in range(game.player.get_slide_collision_count()):
		var hit: KinematicCollision3D=game.player.get_slide_collision(i)
		print("BLOCKER ",hit.get_collider().get_path()," normal=",hit.get_normal())
	return false
func walk(house: Node3D,b: Dictionary,label: String) -> void:
	game.player.global_position=house.to_global(Vector3(0,.025,10));game.player.velocity=Vector3.ZERO
	game.player.reset_physics_interpolation();await frames(15)
	check(await drive(house,Vector3(0,.025,2.5)),label+" enters through actual ground-floor door")
	var route: Array=house.get_meta("stair_route")
	var complete:=true
	for i in range(route.size()):
		if not await drive(house,route[i]):complete=false;break
		if i%4==3:
			check(game.player.is_on_floor() and absf(house.to_local(game.player.global_position).y-(i/4+1)*3.6)<.12,label+" reaches occupied floor "+str(i/4+2)+" by walking")
	check(complete,label+" reaches the top floor using the continuous U stairs")
	if complete:
		var back: Array=route.duplicate();back.reverse()
		for point in back:
			if not await drive(house,point):complete=false;break
		if complete:complete=await drive(house,Vector3(0,.025,10))
	check(complete and house.to_local(game.player.global_position).z>8,label+" walks back down and exits without teleporting")
func run() -> void:
	Engine.set_meta("punchline_world",preload("res://scripts/world_config.gd").DEFAULTS.duplicate())
	game=load("res://main.tscn").instantiate();root.add_child(game);await frames(30)
	for enemy in game.enemies:game.set_dummy_mode(enemy,0)
	var version: String=str(ProjectSettings.get_setting("application/config/version"))
	check(version=="0.9.25" and game.interface.metric.text.contains(version),"running HUD uses current project version")
	var extra: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/multistorey_plan.json"))
	var three: Dictionary={};var four: Dictionary={};var valid:=true;var floors_ok:=true;var holes_ok:=true
	var world: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
	for b in extra.buildings:
		var house: Node3D=game.arena.punchline.housing.get_node("GeneratedBuildings/"+b.lot+"/"+b.id)
		var window_count:=0
		for window in house.get_node("Windows").get_children():
			if window.has_meta("aperture"):window_count+=1
		valid=valid and house.get_meta("storeys")==b.storeys and window_count==11*b.storeys
		if b.storeys==3 and three.is_empty():three=b
		if b.storeys==4 and four.is_empty():four=b
		for level in range(int(b.storeys)):
			var ray:=PhysicsRayQueryParameters3D.create(house.to_global(Vector3(0,level*3.6+.4,2.5)),house.to_global(Vector3(0,level*3.6-.2,2.5)),1)
			var hit: Dictionary=world.intersect_ray(ray)
			floors_ok=floors_ok and not hit.is_empty() and absf(house.to_local(hit.position).y-level*3.6)<.01
			if level<int(b.storeys)-1:
				ray=PhysicsRayQueryParameters3D.create(house.to_global(Vector3(-2.1,level*3.6+1.4,-.9)),house.to_global(Vector3(-2.1,level*3.6+3.5,-.9)),1)
				holes_ok=holes_ok and world.intersect_ray(ray).is_empty()
	check(extra.buildings.size()==6 and valid,"six additional buildings have three/four real floors and transparent windows")
	check(floors_ok,"every storey has a physical floor at its correct height")
	check(holes_ok,"stairwells have actual openings through upper slabs")
	var factory: Node3D=game.arena.punchline.housing
	var house: Node3D=factory.get_node("GeneratedBuildings/"+three.lot+"/"+three.id)
	await walk(house,three,"The Proyected")
	# Return to the original parking spawn to perform a normal production fusion.
	game.respawn_player();await frames(20);game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
	check(game.fusion.request(),"mecha fusion still starts in the parking spawn")
	if not game.fusion.cinematic:game.queue_free();await frames(8);quit(1);return
	game.fusion.sequence.advance(11.5);await frames(45)
	house=factory.get_node("GeneratedBuildings/"+four.lot+"/"+four.id)
	await walk(house,four,"Mega mecha")
	check(game.robots.naoya.collision.shape.radius>1.04,"stairs retain the original mecha collision width")
	var config=preload("res://scripts/world_config.gd")
	var settings: Dictionary=config.DEFAULTS.duplicate();settings.seed="Torres 25";settings.density=0
	var a: Dictionary=config.make_plan(settings);var count:=0
	for b in a.buildings:
		if int(b.get("storeys",1))>1:count+=1
	check(a==config.make_plan(settings) and count==6,"all six tower structures survive density and reproduce from the selected seed")
	print("RESULT ",checks-failures,"/",checks," actual multi-storey building checks")
	game.queue_free();await frames(8);quit(1 if failures else 0)

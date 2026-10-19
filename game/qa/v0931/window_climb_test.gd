extends SceneTree
var game:Node3D
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func frames(count:int)->void:
	for i in range(count):await physics_frame
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func run()->void:
	game=load("res://main.tscn").instantiate();root.add_child(game)
	while game.loading:await process_frame
	await frames(30)
	for enemy in game.enemies:game.set_dummy_mode(enemy,0)
	game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
	check(game.fusion.request(),"real Sentinel fusion starts")
	game.fusion.sequence.advance(11.5);await frames(40)
	var spider:Node3D=game.fusion.spider;check(spider.eject(),"real fitted head ejects")
	await frames(150)
	var g:Node3D=load("res://housing/scripts/DistrictHousingGenerator.gd").new();game.add_child(g)
	g.part(g,"WindowClimbFloor",Vector3(20,.4,20),Vector3(600,-.2,0),null)
	var walls:Node3D=g.category(g,"Walls");var windows:Node3D=g.category(g,"Windows")
	var mat:Material=g.material("fixture_wall",Color("b7c6b1"));var trim:Material=g.material("fixture_trim",Color("efe6cd"));var dark:Material=g.material("fixture_dark",Color("394e4b"))
	g.wall_with_openings(walls,windows,"ClimbWindow",Vector3(600,0,-3),0,6,5,[{"x":0.0,"width":1.6,"bottom":1.1,"height":1.4,"kind":"window"}],mat,trim,dark,{"shutters":true})
	g.flush_details();await frames(2)
	spider.clear_surface_path();game.player.global_position=Vector3(600,.035,-1.0);game.player.velocity=Vector3.ZERO
	game.player.global_basis=Basis.IDENTITY;spider.normal=Vector3.UP;spider.forward=Vector3.FORWARD;spider.view_forward=spider.forward
	spider.previous_yaw=0;game.yaw=0;spider.airborne=false;spider.last_safe=game.player.global_transform
	var clear:=true;var reached:=false;var flipped_under_sill:=false;var previous:Vector3=game.player.global_position;var max_step:=0.0
	Input.action_press("forward")
	for i in range(340):
		await physics_frame
		clear=clear and spider.pose_fits(game.player.global_transform)
		max_step=maxf(max_step,game.player.global_position.distance_to(previous));previous=game.player.global_position
		if game.player.global_position.y>.9 and spider.normal.y<-.5:flipped_under_sill=true
		if i%40==0:print("WINDOW_TRACE ",i," position=",game.player.global_position," up=",spider.normal," blocked=",spider.get_meta("blocked_turn",{}))
		if game.player.global_position.y>3.2 and absf(spider.normal.y)<.1:reached=true;break
	Input.action_release("forward")
	check(reached,"continuous movement climbs over a real generated window, sill, frame and glass")
	check(clear,"complete armour stays clear of all physical window and wall surfaces")
	check(not flipped_under_sill,"window sill is crossed as a facade lip without attaching upside down underneath it")
	check(max_step<.12,"window crossing preserves smooth translation without a teleport")
	print("WINDOW_METRICS max_step=",max_step," reached=",reached," position=",game.player.global_position)
	print("RESULT ",checks-failures,"/",checks," real generated window climb checks")
	game.queue_free();await frames(8);quit(1 if failures else 0)

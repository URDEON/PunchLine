extends SceneTree
var checks:=0
var failures:=0
var game:Node3D
func _initialize()->void:run.call_deferred()
func frames(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func run()->void:
	var config=preload("res://scripts/world_config.gd")
	var settings:Dictionary=config.DEFAULTS.duplicate();settings.seed="Bosque 42"
	var a:Dictionary=config.make_plan(settings);var b:Dictionary=config.make_plan(settings)
	check(a==b,"same text seed reproduces the complete runtime plan")
	settings.seed="Bosque 43"
	check(config.make_plan(settings).buildings!=a.buildings,"different seeds change architecture and building dimensions")
	settings.density=0;var sparse:Dictionary=config.make_plan(settings)
	check(sparse.buildings.size()<a.buildings.size(),"density changes the selected house count")
	var required:=0;var valid:=true
	var original:Dictionary=config.make_plan(config.DEFAULTS)
	for house in a.buildings:
		if not String(house.access).begins_with("mecha"):continue
		required+=1
		for base in original.buildings:
			if base.lot==house.lot and base.id==house.id:valid=valid and house.width==base.width and house.depth==base.depth and house.center==base.center
	check(required==6 and valid,"six measured mecha houses retain size and position across seeds")
	Engine.set_meta("punchline_world",config.DEFAULTS.duplicate())
	game=load("res://main.tscn").instantiate();root.add_child(game);while game.loading:await process_frame
	await frames(25)
	for enemy in game.enemies:game.set_dummy_mode(enemy,0)
	game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
	check(game.fusion.request(),"real mecha fusion starts")
	if not game.fusion.cinematic:quit(1);return
	game.fusion.sequence.advance(11.5);await frames(40)
	var spider:Node3D=game.fusion.spider
	check(spider.interact(),"E action ejects the real mecha head")
	await frames(150)
	check(spider.mode=="spider" and game.hp==50 and game.max_hp==50,"head unfolds into controllable spider with 50 HP")
	check(spider.rig.skeleton.get_bone_count()==13 and spider.rig.hips.size()==6,"supplied mesh uses six procedural two-bone legs")
	check(not game.fusion.sequence.articulation.pivots.Cabeza.visible and spider.dormant>.99,"original head removed and mecha kneels dormant")
	check(game.fusion.sequence.global_position.distance_to(spider.mecha_origin)<.01,"parked mecha remains in the world while head moves")
	check(is_equal_approx(game.robots.naoya.collision.shape.radius,spider.rig.body_radius) and game.player.motion_mode==CharacterBody3D.MOTION_MODE_FLOATING,"spider uses its own physical collider and surface movement")
	spider.ability(2);check(spider.invisible() and spider.cloak_time>0,"camouflage activates with duration and cooldown")
	spider.take_damage(6);check(game.hp==44 and not spider.invisible(),"damage reduces spider health and breaks camouflage")
	spider.ability(1);check(spider.scan_time>0 and spider.scan_cd>0,"scanner pulse starts with cooldown")
	var before:int=spider.scan_revision;spider.ability(1)
	check(spider.scan_revision==before,"scanner cannot bypass its cooldown")
	game.player.global_position=spider.mecha_origin+Vector3(30,.1,0)
	check(not spider.request_return() and spider.mode=="spider","remote reattachment rejected")
	# Real collision fixture, away from the protected district polygons.
	var factory:Node3D=load("res://housing/scripts/DistrictHousingGenerator.gd").new();game.add_child(factory)
	factory.part(factory,"SurfaceFloor",Vector3(20,.4,20),Vector3(600,-.2,0),null)
	factory.part(factory,"ClimbWall",Vector3(8,4,.3),Vector3(600,2,-3),null)
	factory.part(factory,"WalkCeiling",Vector3(8,.3,5),Vector3(600,4,-.5),null)
	game.player.global_position=Vector3(600,.025,0);game.player.velocity=Vector3.ZERO
	spider.normal=Vector3.UP;spider.forward=Vector3.FORWARD;spider.view_forward=spider.forward;spider.previous_yaw=0;game.yaw=0
	Input.action_press("forward")
	var saw_wall:=false;var saw_ceiling:=false;var volumes_clear:=true
	for i in range(210):
		await physics_frame
		volumes_clear=volumes_clear and spider.pose_fits(game.player.global_transform)
		if absf(spider.normal.y)<.1 and game.player.global_position.y>.5:saw_wall=true
		if spider.normal.y<-.9:saw_ceiling=true
		if i%25==24:print("SURFACE ",i," position=",game.player.global_position," up=",spider.normal)
	Input.action_release("forward")
	check(volumes_clear,"complete armour volume stays clear throughout the floor/wall/ceiling route")
	check(saw_wall,"continuous movement climbs from floor onto real wall")
	check(saw_ceiling,"continuous movement transitions from wall onto underside of ceiling")
	check(game.player.global_position.y>3.0 and game.player.global_position.y<4.0,"spider stays below ceiling without crossing its collider")
	game.player.global_position=Vector3(600,4.175,-.5);spider.normal=Vector3.UP;spider.forward=Vector3.RIGHT;spider.view_forward=spider.forward;spider.previous_yaw=game.yaw
	Input.action_press("forward");await frames(20);Input.action_release("forward")
	check(game.player.global_position.y>4.1 and spider.normal.y>.9,"spider can also walk on the roof surface")
	var selected:Dictionary={};var nearest:=INF
	for house in original.buildings:
		var distance:float=Vector2(house.center[0]-spider.mecha_origin.x,house.center[1]-spider.mecha_origin.z).length_squared()
		if house.archetype=="small_residential" and distance<nearest:selected=house;nearest=distance
	var building:Node3D=game.arena.punchline.housing.get_node("GeneratedBuildings/"+selected.lot+"/"+selected.id)
	game.player.global_position=building.to_global(Vector3(selected.width/2+.45,-.12,0));game.player.velocity=Vector3.ZERO
	spider.normal=Vector3.UP;spider.forward=-building.global_basis.x;spider.view_forward=spider.forward;spider.fall_speed=0;spider.previous_yaw=game.yaw
	var reached_roof:=false;Input.action_press("forward")
	for i in range(260):
		await physics_frame
		if i%60==0:print("HOUSE_TRACE ",i," at=",building.to_local(game.player.global_position)," normal=",spider.normal)
		if spider.normal.y>.4 and building.to_local(game.player.global_position).y>selected.height+.25:reached_roof=true;break
	Input.action_release("forward")
	print("HOUSE_CLIMB ",building.to_local(game.player.global_position)," normal=",spider.normal)
	check(reached_roof,"continuous movement climbs a generated house wall onto its actual pitched roof")
	game.player.global_position=spider.mecha_origin+Vector3(0,.025,2.2);game.player.velocity=Vector3.ZERO
	game.player.global_basis=Basis.IDENTITY;spider.normal=Vector3.UP;spider.forward=Vector3.FORWARD
	check(spider.request_return(),"nearby head can reconnect along clear path")
	print("RETURN_DIAGNOSTIC position=",game.player.global_position," mecha=",spider.mecha_origin," head=",game.fusion.sequence.articulation.pivots.Cabeza.global_position," height=",spider.mecha_height," notice=",game.ult_msg)
	await frames(90)
	check(not spider.active() and game.fusion.fused and game.max_hp==300,"reattachment restores active mecha and original health pool")
	check(game.player.up_direction==Vector3.UP and game.player.motion_mode==CharacterBody3D.MOTION_MODE_GROUNDED and game.robots.naoya.collision.shape.radius>1.0,"reattachment restores original collider and gravity")
	check(game.fusion.sequence.articulation.pivots.Cabeza.visible,"head visible again after reconnection")
	spider.return_cd=0
	check(spider.eject(),"head can eject again after reconnection cooldown")
	await frames(140);spider.take_damage(50)
	check(game.hp==0 and game.fusion.death_broken,"losing 50 HP enters the original player death state")
	await frames(300)
	check(game.hp>0 and not game.fusion.fused and not spider.active(),"normal player respawn completes after spider destruction")
	print("RESULT ",checks-failures,"/",checks," world and real head-spider checks")
	game.queue_free();await frames(8);quit(1 if failures else 0)

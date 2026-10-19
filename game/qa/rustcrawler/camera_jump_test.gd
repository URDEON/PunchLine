extends SceneTree
var game:Node3D
var spider:Node3D
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func frames(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func key(code:Key)->void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true;game._unhandled_input(event)
func jump()->void:
	var event:=InputEventKey.new();event.keycode=game.preferences.bindings.jump;event.pressed=true;game._unhandled_input(event)
func place(point:Vector3,up:=Vector3.UP,heading:=Vector3.FORWARD)->void:
	game.player.global_position=point;game.player.velocity=Vector3.ZERO
	spider.normal=up;spider.forward=heading;spider.previous_yaw=game.yaw
	spider.airborne=false;spider.air_velocity=Vector3.ZERO;spider.fall_speed=0
	game.player.global_basis=Basis(heading.cross(up).normalized(),up,-heading)
	game.player.reset_physics_interpolation()
func run()->void:
	game=load("res://main.tscn").instantiate();root.add_child(game);await frames(30)
	for enemy in game.enemies:game.set_dummy_mode(enemy,0)
	game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
	check(game.fusion.request(),"actual Sentinel fusion starts")
	if not game.fusion.cinematic:quit(1);return
	game.fusion.sequence.advance(11.5);await frames(40)
	spider=game.fusion.spider;check(spider.eject(),"head ejects using actual game collider")
	await frames(150)
	var factory:Node3D=load("res://housing/scripts/DistrictHousingGenerator.gd").new();game.add_child(factory)
	factory.part(factory,"JumpFloor",Vector3(30,.4,30),Vector3(600,-.2,0),null)
	factory.part(factory,"JumpWall",Vector3(8,4,.3),Vector3(600,2,-3),null)
	factory.part(factory,"JumpCeiling",Vector3(8,.3,5),Vector3(600,4,-.5),null)
	factory.part(factory,"LowRoof",Vector3(3,.2,3),Vector3(610,.95,5),null)
	place(Vector3(600,.025,5));game.yaw=0;spider.previous_yaw=0;game.pitch=0;game.zoom=0;await frames(3)
	spider.camera_update(game.camera,1.0/60)
	check(game.camera_view.active and game.camera_view.cockpit.visible,"eye view enables cockpit and lens")
	check((spider.rig.mesh.layers & game.camera.cull_mask)==0,"owner eye camera cannot render its own animated skin")
	check(spider.rig.mesh.visible and (spider.rig.mesh.layers & ((1<<20)-1))!=0,"spider stays available to other cameras and portraits")
	Input.action_press("forward");var stable:=true
	for i in range(20):
		await physics_frame;spider.camera_update(game.camera,1.0/60)
		var eye:Vector3=game.player.get_global_transform_interpolated().origin+spider.normal*.48+spider.forward*.20
		stable=stable and game.camera.global_position.distance_to(eye)<.01 and (spider.rig.mesh.layers & game.camera.cull_mask)==0
	Input.action_release("forward")
	check(stable,"walking eye follows interpolated body without positional lag or self overlap")
	key(KEY_V);spider.camera_update(game.camera,1.0/60)
	check(game.zoom>.55 and not game.camera_view.active and spider.rig.mesh.layers==1,"V restores full model for third person")
	var target:Vector3=game.player.get_global_transform_interpolated().origin+spider.normal*.38
	var old_distance:float=game.camera.global_position.distance_to(target)
	var wheel:=InputEventMouseButton.new();wheel.pressed=true;wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;game._unhandled_input(wheel)
	spider.camera_update(game.camera,1.0/60)
	check(game.camera.global_position.distance_to(target)>old_distance+.35,"mouse wheel adjusts actual orbit distance")
	place(Vector3(600,.025,-1.5),Vector3.UP,Vector3.BACK);game.zoom=3;game.pitch=0;spider.camera_update(game.camera,1.0/60)
	target=game.player.get_global_transform_interpolated().origin+spider.normal*.38
	var obstruction:Dictionary=spider.ray(target,game.camera.global_position)
	check(obstruction.is_empty() and game.camera.global_position.distance_to(target)<2 and game.camera.global_position.z>-2.65,"third-person camera sweep shortens orbit before an actual blocking wall")
	place(Vector3(600,.025,-2.3),Vector3.UP,Vector3.BACK);spider.camera_update(game.camera,1.0/60)
	check(game.camera_view.active and (spider.rig.mesh.layers & game.camera.cull_mask)==0,"cramped orbit falls back to protected eye view")
	spider.forward=Vector3.FORWARD;game.zoom=0;spider.camera_update(game.camera,1.0/60)
	check(game.camera_view.active and game.camera_view.lens.visible,"return to eye view restores postprocessing")
	place(Vector3(600,.025,5));await frames(3);var start:Vector3=game.player.global_position
	jump();await frames(4)
	check(spider.airborne and game.player.global_position.y>start.y+.15,"bound jump key produces a real floor jump")
	check(not spider.rig.initialized,"airborne legs release planted world contacts")
	var velocity:float=game.player.velocity.y;jump();await frames(2)
	check(game.player.velocity.y<velocity,"pressing jump again cannot double-jump")
	var peak:float=game.player.global_position.y
	for i in range(65):await physics_frame;peak=maxf(peak,game.player.global_position.y)
	check(peak>start.y+.5 and peak<start.y+1.0,"jump has bounded ballistic height")
	check(not spider.airborne and absf(game.player.global_position.y-.025)<.06 and spider.normal.y>.9,"floor landing restores surface adhesion")
	place(Vector3(610,.025,5));await frames(2);jump();peak=0
	for i in range(60):await physics_frame;peak=maxf(peak,game.player.global_position.y)
	print("LOW_ROOF peak=",peak," position=",game.player.global_position," up=",spider.normal," airborne=",spider.airborne)
	var attached_below:bool=spider.normal.y<-.9 and absf(game.player.global_position.y-.825)<.04
	var landed_below:bool=spider.normal.y>.9 and game.player.global_position.y<.1
	var col:CollisionShape3D=game.robots.naoya.collision
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=col.shape;query.transform=col.global_transform
	query.exclude=[game.player.get_rid()];query.collision_mask=1
	check(not spider.airborne and (attached_below or landed_below) and game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(),"low roof blocks jump or accepts underside adhesion without capsule penetration")
	place(Vector3(600,.025,0));Input.action_press("forward")
	for i in range(80):
		await physics_frame
		if absf(spider.normal.y)<.1 and game.player.global_position.y>.8:break
	Input.action_release("forward");await frames(2)
	check(absf(spider.normal.y)<.1,"real movement reaches wall before jumping")
	start=game.player.global_position;jump();await frames(10)
	check(spider.airborne and game.player.global_position.z>start.z+.5,"wall jump detaches away from masonry")
	await frames(100)
	check(not spider.airborne and spider.normal.y>.9,"wall jump falls and reattaches to ground")
	place(Vector3(600,.025,0));Input.action_press("forward")
	for i in range(110):
		await physics_frame
		if spider.normal.y<-.9:break
	Input.action_release("forward");await frames(2)
	check(spider.normal.y<-.9,"real movement reaches ceiling before jumping")
	game.zoom=3;game.pitch=.1;spider.camera_update(game.camera,1.0/60)
	check(game.camera.global_basis.y.dot(Vector3.DOWN)>.9,"orbit camera follows ceiling orientation")
	start=game.player.global_position;jump();await frames(10)
	check(spider.airborne and game.player.global_position.y<start.y-.5,"ceiling jump releases adhesion downward")
	await frames(100)
	check(not spider.airborne and spider.normal.y>.9 and game.player.global_position.y<.1,"opposite ceiling-to-floor landing restores upright basis")
	place(spider.mecha_origin+Vector3(0,.025,2.2));await frames(2)
	check(spider.request_return(),"reconnection remains available after jumping and camera changes")
	await frames(80)
	check(not spider.active() and game.fusion.fused and not game.camera_view.active,"reconnection cleans spider camera and restores third-person mecha")
	print("RESULT ",checks-failures,"/",checks," camera and jump checks")
	game.queue_free();await frames(8);quit(1 if failures else 0)

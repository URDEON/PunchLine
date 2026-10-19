extends SceneTree
var game:Node3D
const OUTPUT="res://housing/docs/evidence/update_v0930/"
func _initialize()->void:run.call_deferred()
func frames(count:int)->void:
	for i in range(count):await physics_frame
func capture(label:String)->void:
	game.set_physics_process(false)
	RenderingServer.set_render_loop_enabled(true)
	for i in range(5):await process_frame;await RenderingServer.frame_post_draw
	var result:Error=root.get_texture().get_image().save_png(OUTPUT+label+".png")
	if result!=OK:push_error("Capture failed");quit(1)
	print("CAPTURE ",label)
	RenderingServer.set_render_loop_enabled(false);game.set_physics_process(true)
func run()->void:
	if DisplayServer.get_name()=="headless":push_error("Forward+ Vulkan required");quit(1);return
	RenderingServer.set_render_loop_enabled(false)
	game=load("res://main.tscn").instantiate();root.add_child(game)
	while game.loading:await process_frame
	await frames(30)
	for enemy in game.enemies:game.set_dummy_mode(enemy,0)
	game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
	game.fusion.request();game.fusion.sequence.advance(11.5);await frames(40)
	var spider:Node3D=game.fusion.spider;spider.eject();await frames(150)
	game.set_process(false);game.camera_view.restore();game.preferences.set_preset(1);game.preferences.set_value("fog_enabled",false)
	var factory:Node3D=load("res://housing/scripts/DistrictHousingGenerator.gd").new();game.add_child(factory)
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("8b9393");mat.roughness=.85
	factory.part(factory,"RenderFloor",Vector3(20,.4,20),Vector3(600,-.2,0),mat)
	factory.part(factory,"RenderWall",Vector3(8,4,.3),Vector3(600,2,-3),mat)
	factory.part(factory,"RenderCeiling",Vector3(8,.3,5),Vector3(600,4,-.5),mat)
	spider.clear_surface_path();game.player.global_position=Vector3(600,.035,0)
	game.player.velocity=Vector3.ZERO;game.player.global_basis=Basis.IDENTITY
	spider.normal=Vector3.UP;spider.forward=Vector3.FORWARD;spider.view_forward=spider.forward
	game.yaw=0;spider.previous_yaw=0;spider.airborne=false
	await frames(2)
	var labels:Dictionary={}
	Input.action_press("forward")
	for i in range(300):
		await physics_frame
		var label:=""
		if spider.normal.y>.99 and game.player.global_position.z<-1.8:label="01_floor_approach"
		elif spider.normal.y>.4 and spider.normal.y<.8:label="02_floor_wall_arc"
		elif absf(spider.normal.y)<.01 and game.player.global_position.y>1.5:label="03_wall_stride"
		elif spider.normal.y<-.4 and spider.normal.y>-.8:label="04_wall_ceiling_arc"
		elif spider.normal.y<-.99 and spider.surface_path.is_empty():label="05_ceiling_stride"
		if label!="" and not labels.has(label):
			labels[label]=true
			var up:Vector3=spider.normal;var forward:Vector3=spider.forward
			game.camera.global_position=game.player.global_position+up*1.6+forward.cross(up)*1.5-forward*1.0
			game.camera.look_at(game.player.global_position+up*.32,up)
			await capture(label)
		if labels.size()==5:break
	Input.action_release("forward")
	print("RESULT ",labels.size(),"/5 native Forward+ surface poses captured")
	game.queue_free();await frames(8);quit(0 if labels.size()==5 else 1)

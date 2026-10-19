extends SceneTree
var game:Node3D
var ambience:Node3D
var folder:="res://housing/docs/evidence/greenery_v0927/"
func _initialize()->void:run.call_deferred()
func frames(n:int)->void:
	for i in range(n):await physics_frame
func capture(label:String)->Image:
	print("CAPTURE_BEGIN ",label," at=",Time.get_ticks_msec())
	RenderingServer.set_render_loop_enabled(true)
	for i in range(5):await process_frame;await RenderingServer.frame_post_draw
	var result:Image=root.get_texture().get_image()
	if result.save_png(folder+label+".png")!=OK:quit(1)
	print("CAPTURE ",label)
	RenderingServer.set_render_loop_enabled(false)
	return result
func difference(a:Image,b:Image)->float:
	var result:=0.0
	for y in range(a.get_height()/3,a.get_height()*3/4,8):
		for x in range(a.get_width()/4,a.get_width()*3/4,8):
			var c:Color=a.get_pixel(x,y);var d:Color=b.get_pixel(x,y)
			result+=absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b)
	return result
func run()->void:
	if DisplayServer.get_name()=="headless" or RenderingServer.get_current_rendering_method()!="forward_plus":push_error("Actual Forward+ renderer required");quit(1);return
	print("RENDER_DEVICE ",RenderingServer.get_video_adapter_name())
	RenderingServer.set_render_loop_enabled(false)
	Engine.set_meta("punchline_world",preload("res://scripts/world_config.gd").DEFAULTS.duplicate())
	print("GAME_LOAD_BEGIN ",Time.get_ticks_msec())
	game=load("res://main.tscn").instantiate();print("GAME_INSTANTIATED ",Time.get_ticks_msec())
	root.add_child(game);print("GAME_READY ",Time.get_ticks_msec());await frames(25)
	for enemy in game.enemies:game.set_dummy_mode(enemy,0)
	ambience=game.arena.punchline.ambience
	game.preferences.values.grass_quality=2;game.preferences.values.fog_amount=.45;game.preferences.apply()
	game.set_process(false);game.set_physics_process(false)
	var plan:Dictionary=preload("res://scripts/world_config.gd").make_plan(preload("res://scripts/world_config.gd").DEFAULTS)
	var b:Dictionary={}
	for item in plan.buildings:
		if item.lot=="lot_05" and item.archetype=="small_residential":b=item;break
	if b.is_empty():quit(1);return
	var building:Node3D=game.arena.punchline.housing.get_node("GeneratedBuildings/"+b.lot+"/"+b.id)
	game.camera.global_position=building.to_global(Vector3(11,2.2,17));game.camera.look_at(building.to_global(Vector3(0,1,0)))
	var enabled:Image=await capture("grass_and_volumetric_fog")
	game.preferences.values.grass_quality=0;game.preferences.apply()
	var no_grass:Image=await capture("grass_disabled")
	var grass_diff:float=difference(enabled,no_grass);print("GRASS_PIXEL_DIFFERENCE ",grass_diff)
	if grass_diff<1:push_error("Grass did not change actual rendered pixels");quit(1);return
	game.preferences.values.grass_quality=2;game.preferences.values.fog_amount=0;game.preferences.apply()
	var no_fog:Image=await capture("fog_disabled")
	var fog_diff:float=difference(enabled,no_fog);print("FOG_PIXEL_DIFFERENCE ",fog_diff)
	if fog_diff<1:push_error("Volumetric fog did not change rendered pixels");quit(1);return
	game.preferences.values.fog_amount=.55;game.preferences.apply()
	game.arena.urban.expansion.set_sky(true);ambience.configure_environment(ambience.environment,true)
	await capture("night_fog")
	game.arena.urban.expansion.set_sky(false);ambience.configure_environment(ambience.environment,false)
	# Validate the real fused and detached-head materials/cameras on the new backend.
	game.set_process(true);game.set_physics_process(true)
	game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
	if not game.fusion.request():push_error("Actual fusion failed on Forward+");quit(1);return
	game.fusion.sequence.advance(11.5);await frames(40);game.zoom=0
	game.set_physics_process(false);game.set_process(false)
	game.camera_view.update(game,game.camera,0,game.yaw,game.pitch,1.0/60)
	await capture("mecha_body_camera")
	game.set_physics_process(true)
	if not game.fusion.spider.eject():push_error("Actual head ejection failed");quit(1);return
	await frames(150);game.set_physics_process(false)
	game.fusion.spider.camera_update(game.camera,1.0/60)
	await capture("spider_body_camera")
	game.zoom=3;game.pitch=-.2;game.fusion.spider.camera_update(game.camera,1.0/60)
	await capture("spider_third_person")
	if not ambience.environment.volumetric_fog_enabled:push_error("Native fog unexpectedly disabled");quit(1);return
	print("RENDER_GREENERY_DONE actual Vulkan Forward+, native fog, grass pixels, night, mecha and spider cameras")
	game.queue_free();await frames(8);quit(0)

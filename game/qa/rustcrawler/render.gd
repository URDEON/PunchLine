extends SceneTree
var game:Node3D
func _initialize()->void:run.call_deferred()
func frames(n:int)->void:
	for i in range(n):await physics_frame
func capture(label:String)->void:
	for i in range(6):await process_frame;await RenderingServer.frame_post_draw
	var path:="res://housing/docs/evidence/rustcrawler/"+label+".png"
	var status:=root.get_texture().get_image().save_png(path)
	print("CAPTURE ",path," status=",status)
	if status!=OK:quit(1)
func run()->void:
	if DisplayServer.get_name()=="headless":push_error("Use a real renderer, desktop or Xvfb");quit(1);return
	DirAccess.make_dir_recursive_absolute("res://housing/docs/evidence/rustcrawler")
	var menu:Control=load("res://launcher.tscn").instantiate();root.add_child(menu);current_scene=menu;await frames(20)
	for button in menu.buttons:
		if button.text=="DEMO":button.pressed.emit();break
	await frames(5);menu.world_setup.seed_edit.text="923";menu.world_setup.density.selected=2;menu.world_setup.night.button_pressed=false
	await capture("world_setup")
	for button in menu.world_setup.get_children():
		if button is Button and button.text=="CREAR MUNDO Y JUGAR":button.pressed.emit();break
	await frames(70);game=current_scene
	for enemy in game.enemies:game.set_dummy_mode(enemy,0)
	game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
	if not game.fusion.request():push_error("Fusion failed");quit(1);return
	game.fusion.sequence.advance(11.5);await frames(40)
	var event:=InputEventKey.new();event.keycode=KEY_E;event.pressed=true;game._unhandled_input(event)
	await frames(125)
	var spider:Node3D=game.fusion.spider
	if spider.mode!="spider":push_error("E did not activate the spider");quit(1);return
	game.set_process(false);game.camera_view.restore()
	game.camera.global_position=spider.mecha_origin+Vector3(6,3.2,7)
	game.camera.look_at(spider.mecha_origin+Vector3(0,1.3,0));await capture("dormant_mecha")
	game.camera.global_position=game.player.global_position+Vector3(1.7,1.3,2)
	game.camera.look_at(game.player.global_position+Vector3.UP*.45);await capture("spider_exterior")
	game.set_process(true);await frames(15)
	game.set_process(false);game.set_physics_process(false)
	await capture("spider_body_camera")
	var before:=root.get_texture().get_image()
	game.preferences.values.chromatic=0;game.preferences.values.bloom=0;game.preferences.values.lens_dirt=0
	game.camera_view.lens.configure(game.preferences.values)
	await capture("spider_body_no_effects")
	var after:=root.get_texture().get_image();var difference:=0.0
	for y in range(100,after.get_height()-100,12):
		for x in range(100,after.get_width()-100,12):
			var a:=before.get_pixel(x,y);var b:=after.get_pixel(x,y);difference+=absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
	print("POSTPROCESS_PIXEL_DIFFERENCE ",difference)
	if difference<1:push_error("Lens effects did not change actual rendered pixels");quit(1);return
	game.preferences.values.chromatic=.3;game.preferences.values.bloom=.35;game.preferences.values.lens_dirt=.25
	game.camera_view.lens.configure(game.preferences.values)
	game.set_process(false);game.camera_view.restore();spider.ability(2)
	# The simulation is paused for identical camera frames; apply the visual state explicitly.
	spider.update_visual(0)
	if not spider.rig.faded:push_error("Camouflage material was not activated");quit(1);return
	game.camera.global_position=game.player.global_position+Vector3(1.7,1.3,2);game.camera.look_at(game.player.global_position+Vector3.UP*.45)
	await capture("spider_camouflage")
	print("RENDER_SPIDER_DONE actual menu, dormant mecha, supplied mesh, body camera and postprocess pixels")
	game.queue_free();await frames(8);quit(0)

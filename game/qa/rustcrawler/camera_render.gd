extends SceneTree
var game:Node3D
func _initialize()->void:run.call_deferred()
func frames(n:int)->void:
	for i in range(n):await physics_frame
func capture(label:String)->void:
	RenderingServer.set_render_loop_enabled(true)
	for i in range(4):await process_frame;await RenderingServer.frame_post_draw
	var path:="res://housing/docs/evidence/spider_v0926/"+label+".png"
	if root.get_texture().get_image().save_png(path)!=OK:quit(1)
	print("CAPTURE ",label)
	RenderingServer.set_render_loop_enabled(false)
func run()->void:
	if DisplayServer.get_name()=="headless":push_error("A real renderer is required");quit(1);return
	# Advance real physics without redrawing every intermediate software-rendered frame.
	RenderingServer.set_render_loop_enabled(false)
	game=load("res://main.tscn").instantiate();root.add_child(game);await frames(30)
	for enemy in game.enemies:game.set_dummy_mode(enemy,0)
	game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
	if not game.fusion.request():quit(1);return
	game.fusion.sequence.advance(11.5);await frames(40)
	var spider:Node3D=game.fusion.spider
	if not spider.eject():quit(1);return
	await frames(150);game.zoom=0;game.pitch=-.28
	Input.action_press("forward");await frames(12);Input.action_release("forward")
	game.set_physics_process(false);spider.camera_update(game.camera,1.0/60)
	await capture("first_person_walking")
	if (spider.rig.mesh.layers & game.camera.cull_mask)!=0:push_error("Owner mesh leaked into first person");quit(1);return
	game.zoom=3.0;game.pitch=-.22;spider.camera_update(game.camera,1.0/60)
	await capture("third_person_near")
	if spider.rig.mesh.layers!=1:push_error("Mesh was not restored for orbit camera");quit(1);return
	game.zoom=5.5;spider.camera_update(game.camera,1.0/60)
	await capture("third_person_far")
	game.zoom=2.5;game.pitch=-.18;game.set_physics_process(true)
	spider.request_jump();await frames(12);game.set_physics_process(false)
	spider.camera_update(game.camera,1.0/60)
	if not spider.airborne:push_error("Real jump failed in render test");quit(1);return
	await capture("third_person_jump")
	print("RENDER_RESULT eye view masked; third-person model restored; adjustable distance; actual jump")
	game.queue_free();await frames(8);quit(0)

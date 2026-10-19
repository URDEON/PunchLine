extends SceneTree
const OUTPUT="res://housing/docs/evidence/update_v0931/"
var game:Node3D
func _initialize()->void:run.call_deferred()
func frames(count:int)->void:
	for i in range(count):await physics_frame
func capture(label:String)->void:
	RenderingServer.set_render_loop_enabled(true)
	for i in range(5):await process_frame;await RenderingServer.frame_post_draw
	var result:Error=root.get_texture().get_image().save_png(OUTPUT+label+".png")
	if result!=OK:push_error("Capture failed");quit(1)
	print("CAPTURE ",label)
	RenderingServer.set_render_loop_enabled(false)
func run()->void:
	if DisplayServer.get_name()=="headless":push_error("Forward+ Vulkan required");quit(1);return
	RenderingServer.set_render_loop_enabled(false)
	game=load("res://main.tscn").instantiate();root.add_child(game)
	while game.loading:await process_frame
	await frames(25);game.set_process(false);game.set_physics_process(false)
	game.camera_view.restore();game.preferences.set_preset(1);game.preferences.set_value("fog_enabled",false)
	var map:Node3D=game.arena.punchline
	game.camera.global_position=Vector3(-112,30,-59);game.camera.look_at(Vector3(-74.6,4,-94))
	await capture("cargo_yard_and_gantry")
	var container:Node3D
	for body in map.cargo.containers:
		if body.get_meta("open",false) and body.find_children("CargoCrate*","CollisionShape3D",true,false).size()>0:container=body;break
	game.camera.global_position=container.global_position+Vector3(.45,1.55,float(container.get_meta("length"))/2+1.7)
	game.camera.look_at(container.global_position+Vector3(0,1.10,-float(container.get_meta("length"))/2+.7))
	await capture("open_container_interior")
	var building:Node3D
	for lot in map.housing.get_node("GeneratedBuildings").get_children():
		for house in lot.get_children():
			if int(house.get_meta("storeys",1))>1:building=house;break
		if building!=null:break
	game.camera.global_position=building.to_global(Vector3(.7,1.75,6.0));game.camera.look_at(building.to_global(Vector3(-4.8,1.05,3.4)))
	await capture("building_reception")
	game.camera.global_position=building.to_global(Vector3(1.1,1.6,5.3));game.camera.look_at(building.to_global(Vector3(5.6,1.1,3.8)))
	await capture("building_waiting_security")
	game.camera.global_position=building.to_global(Vector3(5.1,1.65,-2.0));game.camera.look_at(building.to_global(Vector3(5.9,1.15,-3.5)))
	await capture("public_bathroom")
	game.camera.global_position=Vector3(-15,42,-10);game.camera.look_at(Vector3(65,7,-115))
	await capture("denser_neighbourhood")
	game.camera.global_position=Vector3(-74.6,3,-24.4);game.camera.look_at(Vector3(-64.6,16,-14.4))
	await capture("day_sky_and_clouds")
	map.ambience.configure_environment(map.ambience.environment,true)
	await capture("procedural_night_sky")
	game.queue_free();await frames(8)
	var launcher:Control=load("res://launcher.tscn").instantiate();root.add_child(launcher);await frames(5)
	launcher.portrait.auto_cycle=false;launcher.portrait.show_subject(0)
	await capture("menu_model")
	launcher.portrait.show_subject(3)
	await capture("menu_art_without_stale_model")
	print("RESULT 10/10 native Forward+ world and menu captures")
	launcher.queue_free();await frames(8);quit()

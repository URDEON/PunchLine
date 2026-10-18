extends SceneTree
var game: Node3D
func _initialize() -> void:run.call_deferred()
func frames(count: int) -> void:
	for i in range(count):await physics_frame
func freeze() -> void:
	game.set_process(false);game.set_physics_process(false);game.camera_view.restore()
func capture(label: String) -> void:
	game.camera.reset_physics_interpolation()
	for i in range(6):await process_frame;await RenderingServer.frame_post_draw
	var path: String="res://housing/docs/evidence/multistorey/"+label+".png"
	var error: Error=root.get_texture().get_image().save_png(path)
	print("CAPTURE ",path," status=",error)
	if error!=OK:quit(1)
func run() -> void:
	if DisplayServer.get_name()=="headless":push_error("Use OpenGL desktop or Xvfb");quit(1);return
	DirAccess.make_dir_recursive_absolute("res://housing/docs/evidence/multistorey")
	Engine.set_meta("punchline_world",preload("res://scripts/world_config.gd").DEFAULTS.duplicate())
	var menu: Control=load("res://launcher.tscn").instantiate();root.add_child(menu);current_scene=menu;await frames(20)
	await capture_menu(menu)
	root.remove_child(menu);menu.queue_free()
	game=load("res://main.tscn").instantiate();root.add_child(game);current_scene=game;await frames(30)
	for enemy in game.enemies:game.set_dummy_mode(enemy,0)
	game.preferences.values.fps=false
	game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
	if not game.fusion.request():push_error("Fusion failed");quit(1);return
	game.fusion.sequence.advance(11.5);await frames(40)
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/multistorey_plan.json"))
	for index in [0,1]:
		var b: Dictionary=plan.buildings[index]
		var house: Node3D=game.arena.punchline.housing.get_node("GeneratedBuildings/"+b.lot+"/"+b.id)
		freeze();game.camera.global_position=house.to_global(Vector3(24,15 if index==0 else 17,27))
		game.camera.look_at(house.to_global(Vector3(0,5.3 if index==0 else 7.0,0)));game.camera.fov=62
		await capture("three_storeys" if index==0 else "four_storeys")
	var b: Dictionary=plan.buildings[1]
	var house: Node3D=game.arena.punchline.housing.get_node("GeneratedBuildings/"+b.lot+"/"+b.id)
	game.player.global_position=house.to_global(Vector3(-2.1,4.75,-.9));game.player.velocity=Vector3.ZERO
	var inward: Vector3=-house.global_basis.z
	game.yaw=atan2(-inward.x,-inward.z);game.model.rotation.y=game.yaw;game.camera_lock=true
	game.player.reset_physics_interpolation();game.set_physics_process(true);game.set_process(true)
	Input.action_press("forward");await frames(25);Input.action_release("forward")
	freeze();game.camera.global_position=house.to_global(Vector3(.3,5.8,2.9))
	game.camera.look_at(game.player.global_position+Vector3.UP*1.4);game.camera.fov=84;game.camera.near=.035
	await capture("mecha_stairs")
	game.player.global_position=house.to_global(Vector3(0,10.825,2.5));game.player.velocity=Vector3.ZERO
	var outward: Vector3=house.global_basis.z
	game.yaw=atan2(-outward.x,-outward.z);game.model.rotation.y=game.yaw
	game.player.reset_physics_interpolation();game.set_process(true);game.set_physics_process(true);await frames(80)
	freeze();game.camera_view.update(game,game.camera,.4,game.yaw,-.12,.1)
	await capture("fourth_floor_view")
	print("RENDER_MULTISTOREY_DONE version=",ProjectSettings.get_setting("application/config/version")," actual 3/4 storeys, stairs and fourth-floor view")
	game.queue_free();await frames(8);quit(0)
func capture_menu(menu: Control) -> void:
	for i in range(6):await process_frame;await RenderingServer.frame_post_draw
	var error: Error=root.get_texture().get_image().save_png("res://housing/docs/evidence/multistorey/version_menu.png")
	print("CAPTURE menu version=",menu.status.text," status=",error)
	if error!=OK:quit(1)

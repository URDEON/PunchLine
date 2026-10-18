extends SceneTree
var game: Node3D
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in range(count):await physics_frame
func capture(label: String,eye: Vector3,target: Vector3) -> void:
	game.set_process(false);game.set_physics_process(false);game.camera_view.restore()
	game.camera.global_position=eye;game.camera.look_at(target);game.camera.near=.035;game.camera.fov=80
	game.camera.reset_physics_interpolation()
	for i in range(8):await process_frame;await RenderingServer.frame_post_draw
	var path: String="res://housing/docs/evidence/confinement/"+label+".png"
	var status: Error=root.get_texture().get_image().save_png(path)
	print("CAPTURE ",path," status=",status)
	if status!=OK:quit(1)
	game.set_physics_process(true);game.set_process(true)
func place(house: Node3D,point: Vector3) -> void:
	game.player.global_position=house.to_global(point);game.player.velocity=Vector3.ZERO
	var inward: Vector3=-house.global_basis.z
	game.yaw=atan2(-inward.x,-inward.z);game.model.rotation.y=game.yaw;game.camera_lock=true
	game.player.reset_physics_interpolation()
func run() -> void:
	if DisplayServer.get_name()=="headless":push_error("Use OpenGL on desktop or Xvfb");quit(1);return
	DirAccess.make_dir_recursive_absolute("res://housing/docs/evidence/confinement")
	Engine.set_meta("punchline_world",preload("res://scripts/world_config.gd").DEFAULTS.duplicate())
	game=load("res://main.tscn").instantiate();root.add_child(game);await frames(25)
	for enemy in game.enemies:game.set_dummy_mode(enemy,0)
	game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
	if not game.fusion.request():push_error("Fusion failed");quit(1);return
	game.fusion.sequence.advance(11.5);await frames(45)
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/generated_plan.json"))
	var selected: Dictionary={}
	for b in plan.buildings:
		if b.access=="player_only" and int(b.style.palette) in [0,6] and not selected.has(int(b.style.palette)):selected[int(b.style.palette)]=b
	for palette in [0,6]:
		var b: Dictionary=selected[palette]
		var house: Node3D=game.arena.punchline.housing.get_node("GeneratedBuildings/"+b.lot+"/"+b.id)
		var front: float=house.get_node("Doors/Threshold").position.z+.06
		place(house,Vector3(0,.025,front));await frames(90)
		print("ENTRY palette=",palette," height=",game.robot_clearance.current_height," contacts=",game.robot_clearance.contacts)
		await capture("yellow_entry" if palette==0 else "blue_entry",house.to_global(Vector3(1.8,2.0,b.depth/2+4.6)),game.player.global_position+Vector3.UP*1.6)
	var b: Dictionary=selected[6]
	var house: Node3D=game.arena.punchline.housing.get_node("GeneratedBuildings/"+b.lot+"/"+b.id)
	place(house,Vector3(0,.025,-1.35));await frames(100)
	print("ROOF hands=",game.fusion.sequence.articulation.confinement.hand_errors)
	await capture("blue_ceiling_contact",house.to_global(Vector3(-1.8,2.1,.85)),game.player.global_position+Vector3.UP*1.7)
	var front: float=house.get_node("Doors/Threshold").position.z+.06
	place(house,Vector3(b.width/2-.4-1.05-.06,.025,front*.5));await frames(100)
	print("WALL hands=",game.fusion.sequence.articulation.confinement.hand_errors)
	await capture("blue_wall_contact",house.to_global(Vector3(.0,2.1,front-.45)),game.player.global_position+Vector3.UP*1.8)
	print("RENDER_CONFINEMENT_DONE actual mecha and generated houses, no substituted models or poses")
	game.queue_free();await frames(8);quit(0)

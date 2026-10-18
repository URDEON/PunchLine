extends SceneTree
## Capture the actual launcher and gameplay scene, retaining its lighting and HUD.
func _initialize()->void:run.call_deferred()
func frames(count:int)->void:
	for i in range(count):await physics_frame
func capture(label:String)->bool:
	for i in range(5):
		await process_frame
		await RenderingServer.frame_post_draw
	var status:=root.get_texture().get_image().save_png("res://housing/docs/evidence/after_"+label+".png")
	print("CAPTURE ",label," status=",status)
	return status==OK
func run()->void:
	if DisplayServer.get_name()=="headless":
		push_error("Use a desktop or Xvfb to capture actual gameplay.");quit(1);return
	var menu:Control=load("res://launcher.tscn").instantiate();root.add_child(menu);current_scene=menu
	await frames(30)
	if not await capture("menu"):quit(1);return
	for button in menu.buttons:
		if button.text=="DEMO":button.pressed.emit();break
	await frames(3)
	if menu.current_page=="world":
		for button in menu.world_setup.get_children():
			if button is Button and button.text=="CREAR MUNDO Y JUGAR":button.pressed.emit();break
	await frames(90)
	var game:Node3D=current_scene
	if game==null or game.get("player")==null:push_error("Launcher did not enter gameplay");quit(1);return
	for enemy in game.enemies:game.set_dummy_mode(enemy,0)
	var plan:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/generated_plan.json"))
	var selected:Dictionary={};var nearest:=INF
	for b in plan.buildings:
		var distance:float=Vector2(b.center[0],b.center[1]).length_squared()
		if b.archetype=="small_residential" and bool(b.style.get("porch",false)) and distance<nearest:selected=b;nearest=distance
	var building:Node3D=game.arena.punchline.housing.get_node("GeneratedBuildings/"+selected.lot+"/"+selected.id)
	game.player.global_position=building.to_global(Vector3(0,.02,selected.depth/2+2.5))
	game.player.velocity=Vector3.ZERO;game.player.reset_physics_interpolation()
	await frames(10)
	# Freeze only the capture; no production camera or player controller is changed.
	game.set_process(false);game.set_physics_process(false)
	game.camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	game.camera.global_position=building.to_global(Vector3(10,5.2,15))
	game.camera.look_at(building.to_global(Vector3(0,1.7,1)))
	game.camera.reset_physics_interpolation()
	if not await capture("gameplay"):quit(1);return
	print("RENDER_GAMEPLAY_DONE actual launcher, original player, HUD and District500")
	game.queue_free();await frames(8);quit(0)

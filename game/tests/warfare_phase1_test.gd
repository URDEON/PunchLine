extends SceneTree
## Exercises the production menu, controller, physical interiors and lifecycle.
const Command = preload("res://units/soldiers/soldier_command.gd")
var settings: Node
var game: Node3D
var player: CharacterBody3D
var checks := 0
var failures := 0
var report: Array[Dictionary] = []

func _initialize() -> void:
	run.call_deferred()

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1
	report.append({"check":label,"passed":ok})
	print("PASS " if ok else "FAIL ",label)

func command() -> RefCounted:
	var value := Command.new()
	value.yaw = player.view.yaw
	player.command_override = value
	return value

func park() -> void:
	player.respawn(Vector3(-97.7,0.35,-64.6))
	player.view.yaw = 0
	command()
	await frames(25)

func drive(house: Node3D,point: Vector3) -> bool:
	var target := house.to_global(point)
	var input := command()
	for i in range(550):
		var offset := target-player.global_position
		offset.y = 0
		if offset.length()<0.18:
			input.move = Vector2.ZERO
			await frames(12)
			return absf(player.global_position.y-target.y)<0.28
		input.yaw = atan2(-offset.x,-offset.z)
		player.view.yaw = input.yaw
		input.move = Vector2(0,-1)
		await physics_frame
	print("BLOCKED ",house.name," target ",point," actual ",house.to_local(player.global_position))
	input.move = Vector2.ZERO
	return false

func walk_tower(house: Node3D) -> bool:
	player.respawn(house.to_global(Vector3(0,0.05,10)))
	command()
	await frames(25)
	if not await drive(house,Vector3(0,0.025,2.5)): return false
	var route: Array = house.get_meta("stair_route")
	for point in route:
		if not await drive(house,point): return false
	var reverse := route.duplicate()
	reverse.reverse()
	for point in reverse:
		if not await drive(house,point): return false
	return await drive(house,Vector3(0,0.025,10))

func run() -> void:
	settings = root.get_node("WarfareSettings")
	var options_backup: Dictionary = settings.values.duplicate()
	var main_path: String = ProjectSettings.get_setting("application/run/main_scene")
	check(main_path=="res://ui/warfare_menu.tscn","Warfare is the default entry point")
	var menu: Control = load(main_path).instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(5)
	check(root.title.contains("Warfare:District500") and root.get_node("BuildInfo").version==str(ProjectSettings.get_setting("application/config/version")),"window and BuildInfo identify the current Warfare version")
	menu.show_options()
	await frames(2)
	menu.show_units()
	await frames(2)
	menu.start_practice()
	await frames(40)
	game = current_scene
	player = game.player
	check(player!=null and player.is_on_floor(),"real menu enters practice with grounded soldier")
	var legacy := false
	for node in game.find_children("*","Node",true,false):
		if node.get_script()!=null and node.get_script().resource_path in ["res://scripts/main.gd","res://scripts/robot_character.gd","res://scripts/fusion_controller.gd","res://scripts/fusion_g.gd","res://scripts/interface.gd"]:
			legacy = true
	check(not legacy,"legacy fighters, HUD and fusion are absent from active scene")
	check(FileAccess.file_exists("res://assets/fusion/optimized/Junkyard_Sentinel.glb"),"Sentinel asset remains available")
	var building_count := 0
	for lot in game.district.housing.get_node("GeneratedBuildings").get_children(): building_count += lot.get_child_count()
	check(building_count==77,"all 77 existing buildings are preserved")
	check(player.visual.skeleton.get_bone_count()>=17,"one full-body skeleton exposes torso, limbs, neck and head")
	var rig: Skeleton3D = player.visual.skeleton
	var head_height := rig.get_bone_global_rest(player.visual.bones.head).origin.y
	var foot_height := rig.get_bone_global_rest(player.visual.bones.foot_l).origin.y
	check(head_height>1.45 and foot_height<0.25 and head_height-foot_height>1.25,"rig rest transforms keep anatomical parts separated")
	await park()
	# Human input path, including normalization and speed modes.
	player.command_override = null
	Input.action_press("wf_forward")
	await frames(30)
	var run_speed := Vector2(player.velocity.x,player.velocity.z).length()
	Input.action_press("wf_right")
	await frames(30)
	check(absf(Vector2(player.velocity.x,player.velocity.z).length()-run_speed)<0.1,"diagonal human movement is normalized")
	Input.action_release("wf_right")
	Input.action_press("wf_walk")
	await frames(30)
	var walk_speed := Vector2(player.velocity.x,player.velocity.z).length()
	Input.action_release("wf_walk")
	Input.action_press("wf_sprint")
	await frames(30)
	var sprint_speed := Vector2(player.velocity.x,player.velocity.z).length()
	Input.action_release("wf_sprint")
	Input.action_release("wf_forward")
	print("MOVEMENT_SPEEDS walk=",walk_speed," run=",run_speed," sprint=",sprint_speed)
	check(walk_speed>1 and walk_speed<run_speed and sprint_speed>run_speed,"walk, run and sprint have distinct configured speeds")
	await park()
	var jump := command()
	jump.jump = true
	await frames(1)
	jump.jump = false
	var start_y := player.global_position.y
	var top_y := start_y
	for i in range(100):
		await physics_frame
		top_y = maxf(top_y,player.global_position.y)
	check(top_y-start_y>0.5 and player.is_on_floor(),"jump leaves the ground and lands under gravity")
	var crouch := command()
	crouch.crouch = true
	await frames(15)
	check(player.movement.crouched and player.collider.shape.height<1.2,"crouch changes capsule height")
	var ceiling := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3,0.1,3)
	collider.shape = shape
	ceiling.add_child(collider)
	game.add_child(ceiling)
	ceiling.global_position = player.global_position+Vector3.UP*1.45
	await frames(3)
	crouch.crouch = false
	await frames(15)
	check(player.movement.crouched,"standing is blocked by a real low ceiling")
	ceiling.queue_free()
	await frames(15)
	check(not player.movement.crouched,"standing recovers after ceiling clears")
	var skeleton_id: int = player.visual.skeleton.get_instance_id()
	var nodes_before := get_node_count()
	for i in range(80):
		player.view.set_first_person(i%2==0)
		await frames(1)
	player.view.set_first_person(true)
	await frames(2)
	check(player.visual.skeleton.get_instance_id()==skeleton_id and get_node_count()==nodes_before,"80 view changes reuse the same body without node accumulation")
	check(not player.visual.head.visible and player.visual.attachments.chest.visible,"FPS hides only local head and preserves torso")
	player.view.pitch = -1.40
	var applied_scale := [1.0]
	var observe := func() -> void: applied_scale[0] = rig.get_bone_pose_scale(player.visual.bones.head).x
	player.visual.modifier.modification_processed.connect(observe)
	await frames(3)
	player.visual.modifier.modification_processed.disconnect(observe)
	check(player.visual.modifier.first_person and applied_scale[0]<0.01,"FPS masks the evaluated skinned head while the full-body rig remains active")
	player.view.set_first_person(false)
	await frames(2)
	check(player.visual.head.visible,"TPS restores head visibility")
	var mouse := InputEventMouseMotion.new()
	mouse.relative = Vector2(100,20)
	var old_yaw: float = player.view.yaw
	player.view._unhandled_input(mouse)
	check(absf(player.view.yaw-old_yaw)>0.1,"mouse rotates independent camera aim")
	settings.values.bodycam = false
	settings.values.bob = false
	settings.values.shake = 0.0
	settings.values.lens = false
	player.view.set_first_person(true)
	await frames(10)
	check(not player.view.lens.visible and absf(player.view.rotation.z)<0.0001,"accessibility disables bodycam sway and lens pass")
	# Walk actual production stairs with the NEW soldier, up and down.
	var tower_three: Node3D = game.district.housing.get_node("GeneratedBuildings/lot_03/Building_Tower_3")
	player.respawn(tower_three.to_global(Vector3(4.5,0.05,3)))
	command()
	player.view.yaw = tower_three.global_rotation.y
	player.view.pitch = 0
	player.view.set_first_person(false)
	settings.values.distance = 5.0
	await frames(25)
	check(player.view.arm.get_hit_length()>0.1 and player.view.arm.get_hit_length()<4.8,"TPS spring arm retracts against a real interior wall")
	player.respawn(tower_three.to_global(Vector3(4.5,0.05,6.15)))
	player.view.yaw = tower_three.global_rotation.y+PI
	command()
	player.view.pitch = -1.4
	player.view.set_first_person(true)
	await frames(15)
	var lens_ray := PhysicsRayQueryParameters3D.create(player.view.global_position,player.view.camera.global_position,1)
	check(player.get_world_3d().direct_space_state.intersect_ray(lens_ray).is_empty() and absf(player.view.arm.position.z)<0.5,"FPS look-down lean stops before an actual wall")
	settings.values.distance = options_backup.distance
	check(await walk_tower(tower_three),"soldier enters, climbs three storeys, descends and exits")
	var tower_four: Node3D = game.district.housing.get_node("GeneratedBuildings/lot_04/Building_Tower_4")
	check(await walk_tower(tower_four),"soldier enters, climbs four storeys, descends and exits")
	await park()
	game.hud.toggle_pause()
	var paused_position := player.global_position
	await frames(12)
	check(paused and player.global_position.is_equal_approx(paused_position),"pause freezes physical simulation")
	game.hud.toggle_pause()
	await frames(3)
	check(not paused and (DisplayServer.get_name()=="headless" or Input.mouse_mode==Input.MOUSE_MODE_CAPTURED),"resume restores simulation (cursor capture checked only with display)")
	player.health.apply_damage(25)
	check(player.health.current==75,"health damage is independent of movement")
	player.health.apply_damage(100)
	check(not player.health.alive and player.view.spectating,"incapacitation switches to observation")
	await frames(170)
	check(player.health.alive and not player.view.spectating and player.global_position.distance_to(game.district.spawn)<1,"practice timer respawns with restored health")
	var steady_nodes := get_node_count()
	var steady_resources := int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	var soak: Array[Dictionary] = []
	var soak_frames := int(OS.get_environment("WARFARE_SOAK_FRAMES"))
	if soak_frames<=0: soak_frames = 7200
	command()
	for i in range(soak_frames):
		await physics_frame
		if i%60==0:
			player.view.set_first_person(i%120==0)
			soak.append(game.recorder.snapshot())
	check(get_node_count()==steady_nodes,"idle/view-switch soak has no node growth")
	check(int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))<=steady_resources+2,"idle/view-switch soak has no persistent resource growth")
	# Repeated scene lifecycle must release the old world and settings connections.
	var memory_before: int = OS.get_static_memory_usage()
	for i in range(3):
		game.return_to_menu()
		await frames(8)
		menu = current_scene
		menu.start_practice()
		await frames(35)
		game = current_scene
		player = game.player
	check(get_node_count()==steady_nodes,"three menu/practice cycles release previous worlds")
	settings.values = options_backup
	var evidence := OS.get_environment("WARFARE_EVIDENCE_DIR")
	if not evidence.is_empty():
		DirAccess.make_dir_recursive_absolute(evidence)
		var file := FileAccess.open(evidence.path_join("phase1-results.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"version":root.get_node("BuildInfo").version,"checks":checks,
			"failures":failures,"results":report,"soak_simulated_seconds":float(soak_frames)/60,
			"headless":DisplayServer.get_name()=="headless","soak":soak,
			"lifecycle_static_memory_delta_bytes":OS.get_static_memory_usage()-memory_before},"\t"))
	print("RESULT ",checks-failures,"/",checks," Warfare phase 1 checks")
	game.queue_free()
	await frames(8)
	quit(1 if failures>0 else 0)

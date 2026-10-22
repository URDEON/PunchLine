extends SceneTree
const Command = preload("res://units/soldiers/soldier_command.gd")
var checks := 0
var failures := 0
var results: Array[Dictionary] = []
var game: Node3D
var player: CharacterBody3D
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1
	results.append({"check":label,"passed":ok})
	print("PASS " if ok else "FAIL ",label)
func input() -> RefCounted:
	var command := Command.new()
	command.yaw = player.view.yaw
	player.command_override = command
	return command
func aim_at(point: Vector3) -> void:
	var direction: Vector3 = point-player.view.global_position
	player.view.yaw = atan2(-direction.x,-direction.z)
	player.view.pitch = atan2(direction.y,Vector2(direction.x,direction.z).length())
	player.command_override.yaw = player.view.yaw
func run() -> void:
	Engine.set_meta("warfare_unit","soldier")
	var menu: Control = load("res://ui/warfare_menu.tscn").instantiate()
	root.add_child(menu); current_scene = menu
	await frames(12)
	check(menu.warfare_mode and menu.buttons[0].get_script().resource_path=="res://scripts/ink_button.gd","menu reuses original launcher and Ink controls")
	check(menu.portrait.subjects.size()==2 and menu.portrait.subjects[1][2]=="mecha","portrait gallery exposes soldier and original Sentinel")
	menu.page("extras"); menu.preview_animation("reload"); await frames(5)
	check(menu.portrait.model.animations.player.current_animation.contains("reload"),"restored Extras plays uploaded clips on the same soldier preview")
	menu.show_home(); await frames(3)
	menu.start_practice(); await frames(45)
	game = current_scene; player = game.player
	check(player.unit_id=="soldier" and player.is_on_floor(),"soldier deploys from the actual restored menu")
	check(player.visual.skeleton.get_bone_count()==65 and player.visual.animations.tree.active,"uploaded skinned rig runs an active AnimationTree")
	var library: AnimationLibrary = load("res://assets/animation_sources/shooter/shooter_library.res")
	check(library.get_animation_list().size()==24 and library.has_animation("slim_reload") and library.has_animation("step_back"),"24 clips include Basic, Slim and the additional backward step")
	var centered := true
	for key in library.get_animation_list():
		var clip: Animation = library.get_animation(key)
		for track in range(clip.get_track_count()):
			if clip.track_get_type(track)==Animation.TYPE_POSITION_3D and String(clip.track_get_path(track)).ends_with(":mixamorig_Hips"):
				for frame in range(clip.track_get_key_count(track)):
					var value: Vector3 = clip.track_get_key_value(track,frame)
					centered = centered and absf(value.x)<0.0001 and absf(value.z)<0.0001
	check(centered,"animation root motion cannot drag the physical controller")
	var settings: Node = root.get_node("WarfareSettings")
	settings.values.animation_style = 1; settings.changed.emit(); await frames(2)
	check(player.visual.animations.machine.get_node("idle").animation=="shooter/slim_idle","Slim style selects the actual alternate pack clips")
	settings.values.animation_style = 0; settings.changed.emit(); await frames(2)
	var command := input()
	command.move = Vector2(0,-1); await frames(20)
	check(player.visual.animations.current=="run","movement selects an actual rifle locomotion clip")
	command.move = Vector2.ZERO; await frames(20)
	check(player.visual.animations.current=="idle","stopping blends back to rifle aiming idle")
	command.move = Vector2(0,1); command.walk = true; await frames(8)
	check(player.visual.animations.current=="step_back","short backward movement uses the separately supplied stepping clip")
	command.move = Vector2.ZERO; command.walk = false; await frames(10)
	player.respawn(Vector3(-85,0.3,-45)); command = input(); await frames(20)
	player.view.set_first_person(true); await frames(5)
	var target: Node3D = game.targets[1]
	aim_at(target.global_position+Vector3.UP)
	command.aim = true; await frames(15)
	check(player.equipment.aiming and player.view.camera.fov<float(root.get_node("WarfareSettings").values.fov)-5,"aim input narrows the real camera FOV")
	check(player.visual.weapons.size()==2 and player.visual.weapons[0].source!=null and player.visual.weapons[1].source!=null,"both original uploaded weapon models are instantiated")
	check(player.visual.muzzle_position().distance_to(player.global_position)<2.5,"weapon and muzzle remain attached to the animated soldier")
	check((-player.visual.weapons[0].global_basis.z).dot(-player.global_basis.z)>0.9,"idle weapon grip is calibrated to the soldier's actual aiming direction")
	var first_shots: int = player.equipment.shots
	command.fire = true; await frames(120); command.fire = false; await frames(1)
	var ar_shots: int = player.equipment.shots-first_shots
	check(ar_shots>=12 and ar_shots<=16,"M4A1 fires at a bounded medium game cadence")
	check(target.hits>0 and target.health<100,"actual hitscan shots damage a physical training target")
	check(player.visual.animations.last_action=="fire","fire triggers the supplied upper-body action")
	var ar_used: int = 30-player.equipment.magazines[0]
	command.reload = true; await frames(1); command.reload = false
	check(player.equipment.reload_remaining>0 and player.visual.animations.last_action=="reload","reload starts the supplied animation and ammunition timer")
	await frames(150)
	check(player.equipment.magazines[0]==30 and player.equipment.reserves.AR==150-ar_used,"reload transfers ammunition without creating extra rounds")
	command.weapon_slot = 1; await frames(1); command.weapon_slot = -1; await frames(15)
	check(player.equipment.data.ammo_type=="SMG" and player.visual.weapon_index==1,"weapon selection changes ammo family and visible model together")
	first_shots = player.equipment.shots; command.fire = true; await frames(120); command.fire = false; await frames(1)
	var smg_shots: int = player.equipment.shots-first_shots
	check(smg_shots>ar_shots and smg_shots>=18,"MP5A5 cadence is faster than M4A1")
	check(player.equipment.reserves.AR==150-ar_used and player.equipment.reserves.SMG==180,"AR and SMG reserves are independent")
	var m4: Resource = load("res://combat/m4a1.tres")
	var mp5: Resource = load("res://combat/mp5a5.tres")
	check(m4.range_limit>mp5.range_limit and mp5.damage_at(65)<mp5.damage_at(5)*0.5,"SMG loses effectiveness earlier than the long-range AR")
	# Physical obstruction test, independent of whether the camera can see a target.
	var wall := StaticBody3D.new(); var collision := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(5,4,0.2); collision.shape = box; wall.add_child(collision); game.add_child(wall)
	wall.global_position = Vector3(-85,2,-50); await frames(3)
	var hits_before: int = target.hits
	command.fire = true; await frames(25); command.fire = false; await frames(1)
	check(target.hits==hits_before,"a wall blocks damage to a target behind it")
	wall.queue_free(); await frames(3)
	command.reload = true; await frames(1); command.reload = false
	var timer: float = player.equipment.reload_remaining
	game.hud.toggle_pause(); await frames(30)
	check(is_equal_approx(player.equipment.reload_remaining,timer),"pause freezes reload and combat simulation")
	game.hud.toggle_pause(); await frames(130)
	command.fire = true; await frames(1); var shot_count: int = player.equipment.shots
	game.hud.toggle_pause(); await frames(3); game.hud.toggle_pause(); await frames(20)
	check(player.equipment.shots==shot_count,"resuming with held fire requires releasing the trigger")
	command.fire = false; await frames(2)
	player.health.apply_damage(10); await frames(1)
	check(player.visual.animations.last_action=="hit" and player.impact_time>0,"damage triggers the supplied reaction and a bounded temporary state")
	await frames(30); check(player.impact_time<=0,"temporary impact effects expire")
	player.respawn(game.objective.global_position+Vector3.UP*0.3); command = input(); await frames(330)
	check(game.objective.captured and game.objective.score>=100,"the displayed capture objective has real progress and score")
	var nodes := get_node_count(); var resources := int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	for i in range(900):
		command.fire = i%180<100
		command.reload = i%180==100
		await physics_frame
	command.fire = false; command.reload = false; await frames(180)
	check(get_node_count()==nodes,"sustained fire, reload and tracer cleanup do not accumulate nodes")
	check(int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))<=resources+3,"combat pool resources remain bounded")
	game.return_to_menu(); await frames(12); menu = current_scene
	menu.select_unit("sentinel"); menu.start_practice(); await frames(45)
	game = current_scene; player = game.player
	check(player.unit_id=="sentinel" and player.health.maximum==300,"Sentinel deploys directly from unit selection with its own health")
	check(not player.view.allow_first_person and player.view.standing_eye_height>3.0,"Sentinel uses its own heavy-unit camera configuration")
	check(player.visual.articulation!=null and player.visual.articulation.cannon_transform.gun_parts.size()>0,"Sentinel reuses original articulation and Rustwing cannon pieces")
	var fusion_active := false
	for node in game.find_children("*","Node",true,false):
		if node.get_script()!=null and node.get_script().resource_path in ["res://scripts/fusion_controller.gd","res://scripts/fusion_g.gd","res://scripts/robot_character.gd"]: fusion_active = true
	check(not fusion_active,"direct Sentinel control does not instantiate fusion or the four robots")
	check(game.hud.identity!=null and game.hud.identity.holographic,"Sentinel recovers the original Sci-Holo identity HUD")
	command = input(); command.move = Vector2(0,-1); var position := player.global_position
	await frames(60); command.move = Vector2.ZERO
	check(player.global_position.distance_to(position)>1 and player.visual.articulation.state!="", "Sentinel movement drives original mechanical locomotion")
	command.aim = true; await frames(45)
	check(player.visual.deployment>0.9,"aim deploys the actual arm cannon")
	command.fire = true; await frames(20); command.fire = false
	check(player.equipment.shots>0 and player.equipment.magazines[0]<8,"deployed Sentinel cannon fires with bounded energy ammunition")
	player.health.apply_damage(1000); await frames(170)
	check(player.health.alive and player.health.current==300,"Sentinel respawns without a fusion sequence")
	game.hud.open_units(); await frames(12)
	check(current_scene.current_page=="units","unit selector returns to the restored unit-selection menu")
	var folder := OS.get_environment("WARFARE_EVIDENCE_DIR")
	if not folder.is_empty():
		DirAccess.make_dir_recursive_absolute(folder)
		var file := FileAccess.open(folder.path_join("shooter-results.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"version":root.get_node("BuildInfo").version,"checks":checks,"failures":failures,"results":results,"ar_shots_2s":ar_shots,"smg_shots_2s":smg_shots},"\t"))
	print("RESULT ",checks-failures,"/",checks," Warfare shooter checks")
	current_scene.queue_free(); await frames(8); quit(1 if failures else 0)

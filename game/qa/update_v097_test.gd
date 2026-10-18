extends SceneTree
const SNAP := preload("res://scripts/mesh_pose_snapshot.gd")
var game: Node3D
var checks := 0
var failures := 0
var metrics: Array[Dictionary] = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks += 1; print("PASS " if ok else "FAIL ",text)
	if not ok: failures += 1
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func reset() -> void:
	for action in game.preferences.bindings: Input.action_release(action)
	game.set_paused(false); game.reset_lab(); game.preferences.values.hold_attack = false
	game.presentation.cancel_emote()
	for i in range(game.enemies.size()): game.enemies[i].kind = 0; game.enemies[i].body.position = Vector3(35+i*3,.1,32)
	await frames(8)
func mesh_metrics(ctl: Node, rest: PackedVector3Array, mesh: MeshInstance3D) -> Dictionary:
	ctl.skeleton.force_update_all_bone_transforms()
	var points: PackedVector3Array = SNAP.vertices(mesh,ctl.skeleton,0)
	var bounds := AABB(points[0],Vector3.ZERO); var finite := true
	for point in points: bounds = bounds.expand(point); finite = finite and point.is_finite()
	var arrays := mesh.mesh.surface_get_arrays(0)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var ratio := 0.0; var strained := 0; var tested := 0
	for j in range(0,indices.size(),3):
		for k in range(3):
			var a := indices[j+k]; var b := indices[j+(k+1)%3]
			var original := rest[a].distance_to(rest[b])
			if original*ctl.skeleton.global_basis.get_scale().x < .004: continue
			var stretch := points[a].distance_to(points[b])/original
			ratio = maxf(ratio,stretch); tested += 1
			if stretch > 2: strained += 1
	return {"finite":finite,"diameter_m":bounds.size.length()*ctl.skeleton.global_basis.get_scale().x,"edge_ratio":ratio,"strained_fraction":float(strained)/maxi(1,tested)}
func test_skin(ctl: Node, anim: AnimationPlayer, clip: String) -> void:
	var meshes: Array[MeshInstance3D] = []; SNAP.collect(ctl.skeleton,meshes)
	var mesh: MeshInstance3D = meshes[0]
	ctl.skeleton.reset_bone_poses(); ctl.skeleton.force_update_all_bone_transforms()
	var rest: PackedVector3Array = SNAP.vertices(mesh,ctl.skeleton,0)
	anim.active = true; anim.play(clip,0); anim.seek(.15,true)
	ctl.start(Vector3(3,2,-1))
	check(ctl.joints.size() == 12 and ctl.simulator.is_simulating_physics(),"12 anclas explícitas y simulación real: "+clip)
	var finite := true; var maximum_speed := 0.0; var max_edge := 0.0; var max_diameter := 0.0; var strained := 0.0; var max_joint_gap := 0.0
	for i in range(210):
		await physics_frame; ctl.follow_actor()
		for body in ctl.bodies:
			finite = finite and body.global_position.is_finite() and body.linear_velocity.is_finite()
			maximum_speed = maxf(maximum_speed,body.linear_velocity.length())
		if i % 30 == 0:
			var result := mesh_metrics(ctl,rest,mesh)
			finite = finite and result.finite
			max_edge = maxf(max_edge,result.edge_ratio); max_diameter = maxf(max_diameter,result.diameter_m); strained = maxf(strained,result.strained_fraction)
	metrics.append({"clip":clip,"edge_ratio":max_edge,"diameter_m":max_diameter,"strain":strained,"max_velocity":maximum_speed})
	print("SKIN_METRICS ",metrics[-1])
	check(finite and maximum_speed < 20,"malla y física finitas, sin explosión: "+clip)
	check(max_diameter < 3 and strained < .02,"vértices y triángulos sin estiramiento general: "+clip)
	var bounded := true
	for i in range(ctl.skeleton.get_bone_count()):
		if i == ctl.pelvis_index: continue
		bounded = bounded and ctl.skeleton.get_bone_pose_position(i).is_equal_approx(ctl.rest_positions[i]) and ctl.skeleton.get_bone_pose_scale(i).is_equal_approx(Vector3.ONE)
	check(bounded,"longitudes y escalas originales: "+clip)
	ctl.stop(true); await frames(30)
	check(not ctl.active and ctl.joints.is_empty() and not ctl.holder.is_set_as_top_level(),"recuperación y limpieza física: "+clip)
func run() -> void:
	game = load("res://main.tscn").instantiate(); root.add_child(game); await reset()
	game.set_physics_process(false); game.locomotion_tree.active = false
	for clip in ["mixamo/idle","combat/Uppercut","extras/NinjaJump_Start","combat/Finisher"]:
		await test_skin(game.physical_ragdoll,game.rig_anim,clip)
	for i in range(game.enemies.size()):
		var enemy: Dictionary = game.enemies[i]; enemy.body.position = Vector3(-17,5.1,26)
		await test_skin(enemy.physics,enemy.rig_anim,"UnarmedIdleAlert1")
		check(enemy.body.position.y > 4.95,"enemigo recupera sobre azotea: "+str(i))
	game.set_physics_process(true); await reset()
	game.moves.press(1)
	check(game.moves.gate_nodes.size() == 2,"exactamente dos fotogramas delanteros")
	game.player.position += Vector3(2,1,3); game.moves.direction = Vector3.LEFT; game.moves.projection.update_gate()
	for i in range(2):
		var gate: Node3D = game.moves.gate_nodes[i]
		check(gate.global_position.distance_to(game.player.global_position+Vector3.LEFT*game.moves.projection.LEAD_DISTANCES[i]+Vector3.UP*1.15) < .001,"fotograma sigue posición y rumbo: "+str(i))
		var flat := true
		for point in gate.silhouette.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]: flat = flat and absf(point.z-.008) < .0001
		check(flat and gate.ink.albedo_color.a <= .19,"silueta plana y tenue: "+str(i))
	game.presentation.afterimage()
	check(game.presentation.ghosts.size() == 1 and game.presentation.ghosts[0].node.get("echo_glass") != null,"rastro usa vidrio y silueta, sin clon 3D")
	game.cancel_skill(); await frames(40)
	check(game.moves.gate_nodes.is_empty() and game.presentation.ghosts.is_empty(),"cancelar limpia fotogramas y rastro")
	await reset(); game.interface.toggle_emotes(); await frames(15)
	var wheel: Control = game.interface.emote_wheel
	check(not game.paused and wheel.visible and wheel.preview_anim != null,"rueda mantiene juego activo y crea rig de preview")
	check(wheel.glass.material is ShaderMaterial and wheel.preview.transparent_bg,"vidrio por shader y preview sin fondo opaco")
	var preview_sk: Skeleton3D = game.visual_motion.find_skeleton(wheel.preview_model)
	var previous_pose := preview_sk.get_bone_pose_rotation(preview_sk.find_bone("B_R_UpperArm"))
	var paused_clock: float = game.clock
	await frames(18)
	check(previous_pose.angle_to(preview_sk.get_bone_pose_rotation(preview_sk.find_bone("B_R_UpperArm"))) > .03 and game.clock > paused_clock,"preview mueve huesos mientras el juego continúa")
	for i in range(game.presentation.EMOTES.size()):
		wheel.selected = i; await frames(4)
		check(wheel.preview_anim.current_animation == game.presentation.EMOTES[i].clip,"vista previa reproduce clip real: "+str(i+1))
	game.interface.choose_emote(1); await frames(10)
	check(game.presentation.emote_time > 0 and game.rig_current_anim == &"emotes/Idle_Rail_Call","desafío nuevo funciona sobre el rig principal")
	await frames(180)
	check(game.presentation.emote_time == 0,"gesto finito devuelve locomoción automáticamente")
	await reset(); var urban: Node3D = game.arena.urban
	check(urban.window_instances > 100 and urban.stations.size() == 7,"distrito con ventanas instanciadas y siete estaciones")
	game.player.position = Vector3(26,.1,-10); urban.tick(.1)
	check(urban.nearest >= 0 and urban.interact(),"puerta interactiva accesible con E")
	await frames(100); check(urban.gate.position.y > 5,"puerta se abre físicamente")
	urban.set_lighting(true); check(game.get_node("ArenaSun").light_energy < .6,"modo nocturno cambia iluminación real")
	urban.set_lighting(false)
	game.player.position = Vector3(7,.3,22); game.player.velocity = Vector3.ZERO; await frames(30); urban.tick(.1)
	check(urban.nearest >= 0 and urban.interact(),"plataforma de impulso responde en el suelo")
	await frames(35); check(game.player.position.y > 4,"impulso produce salto físico real")
	await reset(); urban.reset_glass()
	game.player.position = Vector3(28,.1,4); game.model.rotation.y = 0; await frames(8)
	check(urban.hit_props(game.player.global_position,Vector3.FORWARD) == 1,"golpe frontal rompe un vidrio del mapa")
	check(urban.breakables[0].broken and urban.breakables[0].body.collision_layer == 0,"rotura elimina la colisión")
	check(urban.hit_props(game.player.global_position,Vector3.FORWARD) == 0,"vidrio roto no recibe otro golpe")
	urban.reset_glass(); game.player.position = Vector3(28,.1,0); await frames(8)
	check(urban.hit_props(game.player.global_position,Vector3.BACK) == 1,"golpe posterior también rompe vidrio")
	urban.reset_glass(); check(not urban.breakables[0].broken and urban.breakables[0].body.collision_layer == 1,"consola rearma visual y colisión")
	await reset(); urban.reset_glass(); game.player.position = Vector3(28,.1,4); game.model.rotation.y = 0; await frames(8)
	game.punch(); await frames(14)
	check(urban.breakables[0].broken,"M1 real rompe el vidrio en la ventana de contacto")
	await reset(); game.player.position = Vector3(32,.1,8); await frames(8)
	var key := InputEventKey.new(); key.keycode = KEY_E; key.physical_keycode = KEY_E; key.pressed = true
	Input.parse_input_event(key); await frames(2); key.pressed = false; Input.parse_input_event(key)
	check(not urban.breakables[0].broken,"tecla E real rearma vidrio desde consola cercana")
	await reset(); game.player.position = Vector3(-9,.1,10); await frames(8); urban.tick(.1)
	check(urban.interact() and game.enemies[0].kind == 1,"estación configura guardia del NPC real")
	for size in [Vector2i(1280,720),Vector2i(640,360),Vector2i(360,640)]:
		root.size = size; game.interface.resize(); game.set_paused(false); game.presentation.cancel_emote(); game.interface.toggle_emotes(); await frames(15)
		check(wheel.radius <= minf(size.x,size.y)*.38 and wheel.preview_texture.size.x < wheel.radius,"rueda adaptable: "+str(size))
		game.interface.close_emotes()
	var directory := OS.get_environment("NAOYA_QA_OUTPUT")
	var metrics_path := directory.path_join("skin_metrics.json") if directory != "" else "user://skin_metrics_v097.json"
	FileAccess.open(metrics_path,FileAccess.WRITE).store_string(JSON.stringify(metrics,"  "))
	game.feedback.stop_all(); OS.delay_msec(150); game.queue_free(); await process_frame; await process_frame
	print("RESULTADO %d/%d" % [checks-failures,checks]); quit(1 if failures else 0)

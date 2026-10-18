extends "res://qa/update_v098_test.gd"
func run() -> void:
	game = load("res://main.tscn").instantiate(); root.add_child(game); await reset()
	var district: Node3D = game.arena.urban.expansion
	check(district.road_tiles.size() >= 40 and district.road_materials.size() == 3,"calzadas comparten tres materiales según tramo")
	for tile in district.road_tiles:
		check(tile.mesh is PlaneMesh and tile.mesh.size == Vector2(12,12) and absf(floor_at(tile.global_position)-tile.global_position.y) < .01,"módulo de calle coincide con superficie caminable: "+str(tile.global_position))
	for material in district.road_materials.values():
		check(material.get_shader_parameter("asphalt_texture") != null and material.get_shader_parameter("pavement_texture") != null,"asfalto y acera usan texturas reales distintas")
	for batch in district.wall_batches:
		var material: StandardMaterial3D = batch.multimesh.mesh.surface_get_material(0)
		check(material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL and material.metallic == 0,"fachada comparte iluminación con la arena")
	for point in district.roof_points: check(absf(floor_at(point)-point.y) < .03,"azotea visible coincide con colisión")
	for point in [Vector3(-68,0,12),Vector3(68,0,-32),Vector3(2,0,68)]:
		check(absf(floor_at(point)-3.148) < .04,"rampa lateral fuera del bulevar: "+str(point))
	game.player.position = Vector3(-68,1.2,1); game.player.velocity = Vector3.ZERO; game.yaw = PI; game.model.rotation.y = PI
	await frames(30); Input.action_press("forward"); Input.action_press("walk"); await frames(720)
	Input.action_release("forward"); Input.action_release("walk"); await frames(8)
	check(game.player.position.y > 6 and game.player.is_on_floor(),"sube andando a la azotea por el acceso lateral")
	await reset()
	for chassis in [-1,0,1,2,3]:
		if chassis >= 0:
			game.robots.forced = chassis
			if game.robots.active: game.respawn_player()
			else: game.robots.select(1)
			game.robots.forced = -1; game.set_paused(false); await frames(40)
		var visual: Node3D = game.rig_holder
		var snapshot: Node3D = preload("res://scripts/projection_frame.gd").new()
		game.add_child(snapshot); snapshot.position = game.player.position+Vector3.UP; snapshot.setup()
		var before: AABB = snapshot.pose_bounds(visual)
		snapshot.fit_pose(visual); var after: AABB = snapshot.pose_bounds(visual)
		var baked: Node3D = snapshot.bake_pose(visual)
		check(snapshot.find_skeleton(baked) == null,"fotografía congelada sin rig duplicado: "+str(chassis))
		check(snapshot.photo_size.y >= after.size.y and snapshot.photo_size.x >= after.size.x,"fotograma abarca cuerpo completo: "+str(chassis))
		var valid := baked.get_child_count() > 0
		for mesh in baked.get_children():
			var arrays: Array = mesh.mesh.surface_get_arrays(0)
			valid = valid and mesh.skin == null and arrays[Mesh.ARRAY_BONES] == null and arrays[Mesh.ARRAY_WEIGHTS] == null
			for point in arrays[Mesh.ARRAY_VERTEX]: valid = valid and point.is_finite()
		check(valid,"malla estática sin pesos ni vértices inválidos: "+str(chassis))
		baked.free(); snapshot.queue_free(); await frames(2)
		game.moves.freeze_player(5); var frame: Node3D = game.moves.player_frame; await frames(4)
		check(frame.state == frame.State.FROZEN and not visual.visible,"estado único y actor 3D oculto: "+str(chassis))
		game.moves.break_player_frame("hit")
		check(visual.visible and game.moves.player_freeze == 0 and not frame.dissolve("hit"),"restauración idempotente: "+str(chassis))
		await frames(2)
		check(not is_instance_valid(frame),"fotograma liberado sin referencia activa: "+str(chassis))
	game.robots.select(0); await frames(35)
	game.feedback.stop_all(); OS.delay_msec(150); game.queue_free(); await process_frame; await process_frame
	print("RESULTADO %d/%d" % [checks-failures,checks]); quit(1 if failures else 0)

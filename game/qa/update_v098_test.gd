extends "res://qa/update_v097_test.gd"

func impact_case(kind: String, velocity: Vector3, expected_bone: String) -> void:
	await reset(); game.set_physics_process(false); game.locomotion_tree.active = false
	game.player.position = Vector3(0,3,12)
	var ctl: Node = game.physical_ragdoll
	ctl.skeleton.reset_bone_poses(); ctl.skeleton.force_update_all_bone_transforms()
	var meshes: Array[MeshInstance3D] = []; SNAP.collect(ctl.skeleton,meshes)
	var rest: PackedVector3Array = SNAP.vertices(meshes[0],ctl.skeleton,0)
	check(ctl.start(velocity,{"kind":kind,"direction":Vector3.FORWARD,"side":1.0}),"activa impacto físico: "+kind)
	check(ctl.last_impact.bone == expected_bone and ctl.last_impact.impulse.length() > 1,"impulso localizado: "+kind)
	var spin: Vector3 = ctl.last_impact.initial_spin
	check(spin.length() > .1 and spin.length() <= 6.01,"giro inicial real acotado: "+kind)
	var maximum_speed := 0.0; var maximum_spin := 0.0; var finite := true; var diameter := 0.0; var strain := 0.0
	for i in range(240):
		await physics_frame; ctl.follow_actor()
		for body in ctl.bodies:
			maximum_speed = maxf(maximum_speed,body.linear_velocity.length()); maximum_spin = maxf(maximum_spin,body.angular_velocity.length())
			finite = finite and body.global_position.is_finite() and body.linear_velocity.is_finite() and body.angular_velocity.is_finite()
		if i % 30 == 0:
			var result := mesh_metrics(ctl,rest,meshes[0]); diameter = maxf(diameter,result.diameter_m); strain = maxf(strain,result.strained_fraction)
	check(finite and maximum_speed < 24 and maximum_spin < 30,"física estable y articulaciones activas: "+kind)
	check(diameter < 3.1 and strain < .02,"malla unida durante impacto: "+kind)
	check(ctl.skeleton.get_bone_count() == 53 and ctl.joints.size() == 12,"conserva huesos y restricciones: "+kind)
	print("IMPACT_METRICS ",kind," spin=",spin," speed=",maximum_speed," angular=",maximum_spin," diameter=",diameter," strain=",strain)
	ctl.stop(true); await frames(30)
	check(not ctl.active and ctl.joints.is_empty() and game.player.position.y >= .04,"recuperación sobre suelo: "+kind)
	game.set_physics_process(true)

func floor_at(point: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(point+Vector3.UP*10,point-Vector3.UP*20,1)
	var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
	return float(hit.position.y) if not hit.is_empty() else -999

func run() -> void:
	game = load("res://main.tscn").instantiate(); root.add_child(game); await reset()
	await impact_case("horizontal",Vector3(0,2.2,-12),"B_Pelvis")
	await impact_case("uppercut",Vector3(0,11.5,-3.2),"B_Spine2")
	await impact_case("downslam",Vector3(0,-18,0),"B_Pelvis")
	await reset()
	var expansion: Node3D = game.arena.urban.expansion
	check(expansion.buildings.size() == 8 and expansion.road_tiles.size() >= 40,"ocho edificios y bulevares modulares")
	check(expansion.scene_cache.size() < expansion.instance_count/4,"instancias reutilizan recursos compartidos")
	var facade_count := 0
	for batch in expansion.wall_batches: facade_count += batch.multimesh.instance_count
	check(facade_count == 256 and expansion.wall_batches.size() <= 4,"256 fachadas conservadas en lotes de render compartidos")
	for point in [Vector3(-75,0,0),Vector3(75,0,0),Vector3(0,0,75),Vector3(0,0,-62)]: check(absf(floor_at(point)) < .2,"suelo ampliado con colisión: "+str(point))
	check(floor_at(Vector3(22,0,15)) < -5.9,"ampliación conserva el foso real")
	for point in expansion.roof_points: check(absf(floor_at(point)-6.196) < .03,"azotea y colisión alineadas: "+str(point))
	game.arena.visit_zone("boulevard"); await frames(10)
	var start: Vector3 = game.player.position
	Input.action_press("forward"); Input.action_press("walk"); await frames(180); Input.action_release("forward"); Input.action_release("walk")
	check(game.player.position.distance_to(start) > 6 and game.player.position.y < .3,"camina por la calle sin obstáculos invisibles")
	game.arena.visit_zone("district_roof"); await frames(30)
	check(game.player.is_on_floor() and game.player.position.y > 6,"visita de azotea aterriza sobre geometría real")
	check(expansion.sky_material.panorama.resource_path.ends_with("skybox-morning.png"),"cielo real de mañana")
	game.arena.urban.set_lighting(true)
	check(expansion.sky_material.panorama.resource_path.ends_with("skybox-night.png"),"cielo real de noche")
	game.arena.urban.set_lighting(false)
	await reset(); game.feedback.audio_events.clear()
	game.moves.press(1); await frames(1)
	var event: Dictionary = game.feedback.audio_events[0]
	check(event.id == "rush" and event.stream.ends_with("rush.wav") and event.pitch == 1,"habilidad 1 reproduce la referencia sin cambiar tono")
	var following := false
	for voice in game.feedback.pool:
		if voice.has_meta("follow_source") and voice.get_meta("follow_source") == game.player: following = true
	check(following,"fuente de proyección acompaña al jugador")
	game.cancel_skill(); await reset(); game.feedback.audio_events.clear()
	game.start_skill3()
	check(not game.feedback.audio_events.any(func(e: Dictionary) -> bool: return e.id == "rush"),"habilidad 3 conserva su audio sin duplicar la referencia de 1")
	await reset(); var enemy: Dictionary = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,0,-1.7); await frames(6)
	game.feedback.audio_events.clear(); game.punch(); await frames(18)
	check(game.feedback.audio_events.any(func(e: Dictionary) -> bool: return e.id == "m1_1" and e.pitch == 1),"M1 real usa contacto de referencia")
	await reset(); game.feedback.audio_events.clear(); game.moves.freeze_player(5)
	check(game.feedback.audio_events.any(func(e: Dictionary) -> bool: return e.id == "glass_enter"),"cristalización tiene sonido de entrada")
	await reset(); await frames(30); game.feedback.audio_events.clear(); game.block = true; game.model.rotation.y = 0; enemy = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,0,-1.7); enemy.combo = 1
	game.hit_player_from_enemy(enemy,Vector3.BACK)
	check(game.hp == 100 and game.feedback.audio_events.any(func(e: Dictionary) -> bool: return e.id == "block"),"bloqueo evita daño y reproduce su sonido")
	check(AudioServer.get_bus_send(AudioServer.get_bus_index("Combat")) == "SFX","mezcla de combate respeta volumen general de efectos")
	game.interface.open_menu("map")
	check(game.interface.menu_tabs.map.icon != null and game.interface.menu_tabs.character.icon != null,"menú incorpora iconos Kenney")
	game.feedback.stop_all(); OS.delay_msec(150); game.queue_free(); await process_frame; await process_frame
	print("RESULTADO %d/%d" % [checks-failures,checks]); quit(1 if failures else 0)

extends SceneTree
const SNAP = preload("res://scripts/mesh_pose_snapshot.gd")
var game: Node3D
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, label: String) -> void:
	checks += 1; print("PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func prepare(chassis: int) -> void:
	game.robots.forced = chassis
	if game.robots.active: game.respawn_player()
	else: game.robots.select(1)
	game.robots.forced = -1; game.set_paused(false)
	for enemy in game.enemies: game.reset_enemy(enemy); game.set_dummy_mode(enemy,0); enemy.body.position = Vector3(30,.3,30)
	game.player.position = Vector3(0,1,5); game.player.velocity = Vector3.ZERO; game.model.rotation.y = 0; game.yaw = 0
	await frames(40)
func run() -> void:
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate(); root.add_child(game); await frames(40)
	check(game.arena.punchline != null and not game.arena.laboratory,"mapa PunchLine es el escenario predeterminado")
	check(game.arena.punchline.collision_count > 200,"colisiones reales de terreno, edificios y mobiliario")
	check(game.arena.punchline.player_spawns.size() == 2,"dos puntos de aparición junto a la plaza")
	var seen := {}
	game.arena.punchline.rng.seed = 124
	for i in range(16):
		game.respawn_player(); seen[game.arena.punchline.spawn_index] = true; await frames(15)
		check(game.player.is_on_floor() and game.player.position.y > .10 and game.player.position.y < .5,"aparición fuera de paredes y sobre suelo "+str(i))
	check(seen.size() == 2,"reapariciones aleatorias utilizan ambos puntos")
	for enemy in game.enemies:
		check(enemy.spawn.length() < 25 and enemy.body.position.y > .1,"enemigo situado dentro de la plaza")
	for chassis in range(4):
		await prepare(chassis)
		var sk: Skeleton3D = game.robots.current.skeleton
		check(game.rig_holder.global_basis.z.normalized().dot(game.facing_forward()) > .99,"frente visual coincide con avance: "+str(chassis))
		check(game.physical_ragdoll.pelvis_name() == "Body","raíz común de piernas y torso: "+str(chassis))
		Input.action_press("forward"); await frames(28)
		var before: Quaternion = sk.get_bone_pose_rotation(sk.find_bone("UpperLeg.L"))
		await frames(15)
		check(game.robots.current.locomotion.tree.active and before.angle_to(sk.get_bone_pose_rotation(sk.find_bone("UpperLeg.L"))) > .02,"locomoción mueve piernas con clips originales: "+str(chassis))
		Input.action_release("forward"); await frames(20)
		var physics: Node = game.physical_ragdoll
		check(physics.start(Vector3(1,2,-4)),"activa ragdoll propio: "+str(chassis))
		check(physics.joints.size() == physics.bodies.size()-1,"todos los cuerpos forman una sola cadena: "+str(chassis))
		var bounded := true; var max_speed := 0.0; var feet := true
		for i in range(90):
			await physics_frame; physics.follow_actor()
			for body in physics.bodies: bounded = bounded and body.global_position.is_finite(); max_speed = maxf(max_speed,body.linear_velocity.length())
			var body_root: Transform3D = sk.get_bone_global_pose(sk.find_bone("Body"))
			for side in ["L","R"]:
				var thigh := sk.find_bone("UpperLeg."+side)
				var expected: Vector3 = body_root*physics.rest_positions[thigh]
				bounded = bounded and expected.distance_to(sk.get_bone_global_pose(thigh).origin) < .001
		for side in physics.foot_bind:
					var end: int = sk.find_bone("FootBack."+side); var control: int = sk.find_bone("Foot."+side)
					var expected_foot: Transform3D = sk.get_bone_global_pose(end)*physics.foot_bind[side]
					feet = feet and expected_foot.origin.distance_to(sk.get_bone_global_pose(control).origin) < .001
		check(feet,"pies independientes unidos al final de la pierna: "+str(chassis))
		check(bounded and max_speed < 25,"piernas unidas al Body durante la física: "+str(chassis))
		physics.stop(true); await frames(45)
		check(not physics.active and physics.recovering == 0 and game.player.is_on_floor(),"recuperación completa y controles: "+str(chassis))
		var meshes: Array[MeshInstance3D] = []; SNAP.collect(game.rig_scene,meshes)
		var points := SNAP.vertices(meshes[0],sk,0); var box := AABB(points[0],Vector3.ZERO)
		for point in points: box = box.expand(point)
		check(box.size.y*sk.global_basis.get_scale().y > 1.2 and box.size.y*sk.global_basis.get_scale().y < 2.6,"torso recuperado sin aplastarse: "+str(chassis))
		await prepare(chassis); game.moves.press(1); await frames(6)
		var first_clip: StringName = game.rig_anim.current_animation
		await frames(14)
		var first_pose: Array[Quaternion] = []
		for bone in range(sk.get_bone_count()): first_pose.append(sk.get_bone_pose_rotation(bone))
		await prepare(chassis); game.moves.press(2); await frames(6)
		var second_clip: StringName = game.rig_anim.current_animation
		await frames(14)
		var difference := 0.0
		for bone in range(sk.get_bone_count()): difference = maxf(difference,first_pose[bone].angle_to(sk.get_bone_pose_rotation(bone)))
		check(first_clip != second_clip and difference > .20,"habilidades 1 y 2 tienen poses y clips distintos: "+str(chassis))
		await prepare(chassis)
		game.interface.toggle_emotes(); var clock: float = game.clock
		await frames(20)
		check(game.interface.emote_wheel.visible and not game.paused and game.clock > clock+.1,"rueda de emotes no pausa combate: "+str(chassis))
		game.player_wakeup_protection = 0
		game.enemies[0].body.position = game.player.position+Vector3.FORWARD*1.7
		game.set_dummy_mode(game.enemies[0],2); game.enemies[0].cd = 0
		for i in range(90):
			await physics_frame
			if game.hp < 100: break
		await frames(2)
		check(game.hp < 100 and not game.interface.emote_wheel.visible,"IA enemiga golpea mientras eliges un emote: "+str(chassis))
		await prepare(chassis); game.interface.toggle_character(); await frames(3)
		check(game.interface.character_popup.visible and game.interface.character_popup.modulate.a > 0 and game.interface.character_popup.modulate.a < 1,"selector tiene apertura gradual: "+str(chassis))
		await frames(15); game.interface.close_character(); await frames(3)
		check(game.interface.selector_closing and game.paused,"cierre conserva pausa hasta acabar animación: "+str(chassis))
		await frames(12); check(not game.paused and not game.interface.character_popup.visible,"cierre devuelve control: "+str(chassis))
	game.feedback.stop_all(); game.queue_free(); await process_frame; await process_frame
	print("RESULTADO %d/%d" % [checks-failures,checks]); quit(1 if failures else 0)

extends SceneTree
var game: Node3D
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1; print("PASS " if ok else "FAIL ",message)
	if not ok: failures += 1
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func reset() -> void:
	for key in game.preferences.bindings: Input.action_release(key)
	game.set_paused(false); game.reset_lab(); game.preferences.values.hold_attack = false
	for i in range(game.enemies.size()): game.enemies[i].kind = 0; game.enemies[i].body.position = Vector3(35+i*3,.1,32)
	await frames(10)
func run() -> void:
	game = load("res://main.tscn").instantiate(); root.add_child(game); await reset()
	var sk: Skeleton3D = game.visual_motion.skeleton
	var original_count := sk.get_bone_count()
	game.set_physics_process(false)
	for clip in ["mixamo/idle","combat/Uppercut","extras/NinjaJump_Start","combat/Finisher"]:
		game.rig_anim.active = true; game.locomotion_tree.active = false
		game.rig_anim.play(clip); game.rig_anim.seek(.15,true); sk.force_update_all_bone_transforms()
		var ctl: Node = game.physical_ragdoll
		ctl.start(Vector3(6,3,-2))
		var stable := true; var finite := true; var largest_drift := 0.0
		for step in range(100):
			await physics_frame; ctl.follow_actor(); sk.force_update_all_bone_transforms()
			for i in range(sk.get_bone_count()):
				if i != ctl.pelvis_index:
					largest_drift = maxf(largest_drift,sk.get_bone_pose_position(i).distance_to(sk.get_bone_rest(i).origin)*sk.global_basis.get_scale().x)
				stable = stable and sk.get_bone_pose_scale(i).is_equal_approx(Vector3.ONE)
			for body in ctl.bodies: finite = finite and body.global_position.is_finite() and body.linear_velocity.length() < 40
		check(sk.get_bone_count() == original_count and largest_drift < .0001 and stable,"rig unido, 53 huesos y longitudes intactas desde "+clip)
		check(finite,"física finita y sin impulso creciente desde "+clip)
		ctl.stop(true); await frames(30)
		check(not ctl.active and not ctl.holder.is_set_as_top_level(),"recuperación del controlador desde "+clip)
	for enemy in game.enemies:
		var ctl: Node = enemy.physics
		enemy.body.position = Vector3(-17,5.1,26)
		ctl.start(Vector3(1,1,0)); await frames(100); ctl.transfer_physical_pose()
		var intact := true
		for i in range(ctl.skeleton.get_bone_count()):
			if i != ctl.pelvis_index: intact = intact and ctl.skeleton.get_bone_pose_position(i).is_equal_approx(ctl.skeleton.get_bone_rest(i).origin)
		check(intact and ctl.skeleton.get_bone_count() == original_count,"enemigo Y2K conserva huesos y longitudes")
		ctl.stop(true); await frames(25)
		check(enemy.body.position.y > 4.95 and enemy.body.position.y < 5.3,"enemigo recupera sobre azotea real")
	game.set_physics_process(true); await reset()
	game.start_form("FORM2",true); game.presentation.reset(); game.presentation.show_form("FORM2")
	await frames(100)
	var creature: Node3D = game.presentation.form_models[1]
	check((-creature.basis.z).dot(Vector3.UP) > .98,"cabeza -Z vertical en reposo")
	Input.action_press("forward"); await frames(70)
	check((-creature.basis.z).dot(Vector3.FORWARD) > .98 and creature.basis.x.dot(Vector3.DOWN) > .98,"cabeza delante y torso boca abajo al moverse")
	Input.action_release("forward"); await frames(80)
	check((-creature.basis.z).dot(Vector3.UP) > .98,"reposo vertical se recupera con transición")
	await reset(); Input.action_press("walk"); Input.action_press("forward"); await frames(40)
	check(absf(game.player.velocity.z) > 2.2 and absf(game.player.velocity.z) < 2.6,"Ctrl caminar a 2.4 m/s")
	Input.action_release("walk"); await frames(35)
	check(absf(game.player.velocity.z) > 7,"soltar Ctrl devuelve carrera")
	await reset()
	for id in game.arena.zones:
		if id == "fall": continue
		game.arena.visit_zone(id); await frames(60)
		check(game.player.position.y > -7 and game.player.is_on_floor(),"zona real transitable: "+id)
	game.arena.visit_zone("lift"); await frames(50)
	var initial_y: float = game.player.position.y
	await frames(360)
	check(game.player.position.y > initial_y+2,"ascensor transporta físicamente al jugador")
	await reset(); game.arena.visit_zone("fall"); await frames(248)
	check(game.descending_time >= 4 and game.rig_current_anim == &"mixamo/Falling","Falling después de caída real de cuatro segundos")
	await frames(162)
	check(game.player.is_on_floor() and game.descending_time == 0,"caída prolongada aterriza y reinicia contador")
	await reset()
	for i in range(game.presentation.EMOTES.size()):
		game.presentation.cancel_emote(); check(game.presentation.start_emote(i),"emote disponible: "+str(i+1))
		await frames(15)
		check(game.rig_current_anim == StringName(game.presentation.EMOTES[i].clip),"clip real asignado al emote: "+str(i+1))
	game.presentation.cancel_emote(); game.interface.toggle_emotes()
	check(not game.paused and game.interface.emote_wheel.visible and not game.interface.menu.visible,"selector B mantiene combate activo y muestra rueda")
	game.interface.choose_emote(0); await frames(5)
	check(not game.paused and game.presentation.emote_time > 0,"selección devuelve control y reproduce baile")
	Input.action_press("forward"); await frames(2)
	check(game.presentation.emote_time == 0,"caminar cancela emote y música")
	await reset(); game.presentation.toggle_kogane(); await frames(85)
	check(game.presentation.kogane_state == "FOLLOW" and game.presentation.companion.visible,"Kogane termina órbita de invocación")
	game.presentation.comment_life = 0; game.presentation.comment("counter_miss")
	check(game.presentation.comment_text.contains("Cinco") or game.presentation.comment_text.contains("counter"),"comentario ligado al fallo real del counter")
	game.presentation.toggle_kogane(); await frames(45)
	check(game.presentation.kogane_state == "HIDDEN" and not game.presentation.companion.visible,"Kogane tiene desaparición completa")
	await reset(); game.moves.press(1)
	check(game.moves.gate_nodes.size() == 2,"habilidad 1 tiene dos vidrios delanteros")
	game.player.position += Vector3(3,2,1); game.moves.direction = Vector3.LEFT; game.moves.projection.update_gate()
	check(game.moves.gate_nodes[0].global_position.distance_to(game.player.global_position+Vector3.LEFT*1.9+Vector3.UP*1.15) < .001,"vidrio sigue posición, altura y dirección")
	game.cancel_skill(); await frames(1)
	check(game.moves.gate_nodes.is_empty(),"fin de habilidad limpia vidrio")
	await reset(); game.start_form("FORM2",true); game.presentation.reset(); game.moves.begin_domain(); await frames(5)
	var scene: Node3D = game.moves.domain_arena.get_child(game.moves.domain_arena.get_child_count()-1)
	check(scene.get("panels") != null and scene.panels.size() == 24,"dominio incluye 24 paneles de proyección")
	check(game.feedback.ambience.playing,"ambiente sonoro real del dominio")
	game.moves.end_domain(); await reset()
	game.route_trial.start(); Input.action_press("forward"); await frames(20); Input.action_release("forward")
	check(game.route_trial.samples.size() >= 3,"eco registra movimiento y huesos reales")
	for point in game.route_trial.ROUTE:
		game.player.position = point; game.player.velocity = Vector3.ZERO; game.route_trial.tick(.1)
	check(not game.route_trial.active and game.route_trial.best_samples.size() > 3,"desafío registra resultado al pasar seis puntos")
	game.route_trial.start(); await frames(12)
	check(is_instance_valid(game.route_trial.ghost) and game.route_trial.ghost_skeleton.get_bone_count() == original_count,"eco reutiliza rig real del jugador")
	game.route_trial.cancel(); await frames(1)
	check(not is_instance_valid(game.route_trial.ghost),"cancelación libera eco sin colisiones invisibles")
	await reset()
	for viewport in [Vector2i(1280,720),Vector2i(640,360)]:
		root.size = viewport; game.interface.resize(); game.interface.open_menu("settings"); await frames(3)
		check(game.interface.menu_panel.size.x <= viewport.x and game.interface.menu_panel.size.y <= viewport.y,"menú responsive "+str(viewport))
		game.set_paused(false)
	game.feedback.stop_all(); OS.delay_msec(150)
	game.queue_free(); await process_frame; await process_frame
	print("RESULTADO %d/%d" % [checks-failures,checks]); quit(1 if failures else 0)

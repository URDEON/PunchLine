extends SceneTree
var game: Node3D
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks += 1; print("PASS " if ok else "FAIL ",text)
	if not ok: failures += 1
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func prepare(chassis: int, distance: float = 1.5) -> void:
	game.robots.forced = chassis
	if game.robots.active: game.respawn_player()
	else: game.robots.select(1)
	game.robots.forced = -1; game.set_paused(false)
	for enemy in game.enemies:
		game.reset_enemy(enemy); game.set_dummy_mode(enemy,0); enemy.body.position = Vector3(40,0,40)
	game.player.position = Vector3(0,.1,8); game.model.rotation.y = 0; game.player.velocity = Vector3.ZERO
	await frames(40)
	game.enemies[0].body.position = game.player.position+Vector3.FORWARD*distance
	await frames(4)
func run() -> void:
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate(); root.add_child(game); await frames(8)
	game.interface.toggle_character(); await frames(3)
	var motion := InputEventMouseMotion.new(); motion.position = game.interface.character_rows[1].get_global_rect().get_center(); root.push_input(motion,true)
	for pressed in [true,false]:
		var mouse := InputEventMouseButton.new(); mouse.button_index = MOUSE_BUTTON_LEFT; mouse.pressed = pressed
		mouse.position = game.interface.character_rows[1].get_global_rect().get_center(); root.push_input(mouse,true)
	await frames(15)
	check(game.robots.active and not game.paused and not game.interface.character_popup.visible,"clic real en selector elige Robot y reanuda combate")
	for chassis in range(3):
		for slot in range(1,4):
			await prepare(chassis)
			game.moves.press(slot)
			check(game.skill_active == "robot" and not game.robots.attack.is_empty(),"inicia habilidad %d/%d" % [chassis,slot])
			await frames(80)
			var expected: float = [[87.0,86.0,82.0],[77.0,80.0,84.0],[84.0,86.0,86.0]][chassis][slot-1]
			check(is_equal_approx(game.enemies[0].hp,expected),"daño real completo %d/%d: %s" % [chassis,slot,str(game.enemies[0].hp)])
			check(game.skill_active == "" and game.robots.cooldowns[slot-1] > 0,"recuperación y cooldown %d/%d" % [chassis,slot])
	for distance in [3.5,5.0]:
		await prepare(2,distance); var start: Vector3 = game.player.position
		game.moves.press(2); await frames(65)
		check(game.enemies[0].hp == 86 and game.player.position.distance_to(start) > 2,"avance detecta contacto a "+str(distance)+" m")
	await prepare(3); game.moves.press(1); await frames(2)
	check(game.block and game.robots.guard_time > 0,"Mike activa guardia frontal real")
	game.hit_player_from_enemy(game.enemies[0],Vector3.BACK)
	check(game.hp == 100,"guardia reforzada evita daño frontal")
	await prepare(3); game.moves.press(2); await frames(5)
	game.hit_player_from_enemy(game.enemies[0],Vector3.BACK)
	check(game.hp == 100 and game.enemies[0].hp == 86 and game.enemies[0].ragdoll,"Mike contragolpea atacante dentro de ventana")
	await prepare(3); game.moves.press(2); await frames(35)
	check(game.moves.player_freeze == 0 and game.moves.player_frame == null,"counter fallido de Mike no activa penalización de Naoya")
	game.hit_player_from_enemy(game.enemies[0],Vector3.BACK)
	check(game.hp == 94,"fuera de ventana el ataque recibido hace daño normal")
	await prepare(3)
	var sidestep_origin: Vector3 = game.player.position
	check(game.robots.press(3) and not game.robots.press(4),"Mike conserva defensa, counter y nuevo paso de flanco")
	await frames(20)
	check(game.player.position.distance_to(sidestep_origin)>1.0 and game.robots.cooldowns[2]>0,"paso de flanco desplaza el cuerpo real y entra en cooldown")
	game.charge = 100; game.start_form("FORM1",true)
	check(game.form == "BASE" and not game.ult_ready(),"Robot no hereda transformación de Naoya")
	for chassis in range(4):
		await prepare(chassis)
		check(game.presentation.emote_entries().size() == 4,"cuatro emotes propios "+game.robots.NAMES[chassis])
		for emote in range(4):
			check(game.presentation.start_emote(emote),"reproduce emote %d/%d" % [chassis,emote])
			await frames(8)
			check(game.rig_anim.current_animation == game.presentation.emote_entries()[emote].clip,"clip real del chasis %d/%d" % [chassis,emote])
			game.presentation.cancel_emote(); await frames(3)
		game.route_trial.samples.clear(); game.route_trial.elapsed = 0; game.route_trial.capture_sample()
		game.route_trial.elapsed = 1; game.route_trial.capture_sample()
		game.route_trial.best_samples = game.route_trial.samples.duplicate(true); game.route_trial.best_time = 1
		game.route_trial.create_ghost(); game.route_trial.elapsed = .5; game.route_trial.playback()
		check(game.route_trial.ghost_skeleton.get_bone_count() == game.robots.current.skeleton.get_bone_count(),"eco reproduce rig correcto "+game.robots.NAMES[chassis])
		game.route_trial.cancel()
	game.robots.select(0); game.set_paused(false); await frames(40)
	check(game.presentation.emote_entries().size() == 8 and game.rig_anim.has_animation("dance/RunningMan"),"Naoya conserva emotes y animaciones originales")
	var inactive := true
	for model in game.robots.cached.values(): inactive = inactive and not model.rig_anim.active and not model.rig_holder.visible
	check(inactive,"chasis ocultos suspenden sus animaciones")
	game.feedback.stop_all(); OS.delay_msec(150); game.queue_free(); await process_frame; await process_frame
	print("RESULTADO %d/%d" % [checks-failures,checks]); quit(1 if failures else 0)

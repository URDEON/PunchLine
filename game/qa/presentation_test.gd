extends SceneTree
var game: Node3D
var checks := 0
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func verify(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ")+description)
func frames(n: int) -> void:
	for i in range(n):
		await physics_frame
func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	game._unhandled_input(event)
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for enemy in game.enemies:
		enemy.body.position = Vector3(30, 0, 30)
	await frames(30)
	key(KEY_B)
	verify(game.interface.emote_wheel.visible and not game.paused,"B abre selector de emotes sin pausar")
	game.interface.choose_emote(0)
	verify(game.presentation.emote_time > 0, "seleccionar inicia el emote")
	verify(not game.can_start_action(), "emote ocupa estado de accion")
	key(KEY_B)
	verify(game.presentation.emote_time == 0, "B cancela emote")
	key(KEY_B)
	game.interface.choose_emote(0)
	game.punch()
	verify(game.presentation.emote_time == 0 and game.attack_anim > 0, "M1 cancela emote y permite combatir")
	await frames(40)
	key(KEY_B)
	game.interface.choose_emote(0)
	var enemy: Dictionary = game.enemies[0]
	enemy.combo = 1
	game.player_wakeup_protection = 0
	game.hit_player_from_enemy(enemy, Vector3.BACK)
	verify(game.hp == 94 and game.presentation.emote_time == 0, "golpe cancela emote sin inmunidad")
	await frames(40)
	game.charge = 100
	key(KEY_G)
	verify(game.form == "FORM1" and game.presentation.transition_time > 0 and game.rig_holder.visible, "fase1 conserva humano al comenzar animacion")
	game.moves.press(1)
	game.punch()
	verify(game.skill_active == "" and game.attack_anim <= 0, "transformacion bloquea habilidad y M1")
	await frames(70)
	verify(game.moves.curse.visible and not game.rig_holder.visible, "modelo cambia en el punto medio")
	verify(game.ult_time == 60, "transicion no consume duracion de ulti")
	await frames(65)
	verify(game.presentation.transition_time == 0 and game.can_start_action(), "fase1 termina sin bloqueo")
	game.moves.phase_charge = 100
	key(KEY_G)
	verify(game.form == "FORM2" and game.presentation.source_form == "FORM1", "fase2 tiene su propia transicion")
	verify(not game.moves.feelers[0].visible, "tentaculos no aparecen antes de eclosion")
	await frames(105)
	verify(game.moves.feelers[0].visible and game.moves.curse.scale.is_equal_approx(Vector3.ONE), "fase2 despliega apendices y restaura escala")
	game.end_form()
	game.charge = 100
	key(KEY_G)
	game.hit_player_from_enemy(enemy, Vector3.BACK)
	verify(game.presentation.transition_time == 0 and game.moves.curse.visible, "golpe interrumpe presentacion sin modelo invisible")
	game.end_form()
	await frames(40)
	game.player.position = Vector3(0, 0.05, 5)
	game.model.rotation.y = 0
	await frames(5)
	key(KEY_1)
	await frames(80)
	verify(game.presentation.ghost_count > 0, "habilidad1 deja siluetas")
	verify(game.presentation.ghosts.size() > 0 and game.presentation.ghosts.size() <= 8, "rastro persiste al terminar con limite de instancias")
	await frames(85)
	verify(game.presentation.ghosts.is_empty(), "rastro se desvanece y elimina")
	for id in ["nanami", "gojo", "naoya"]:
		game.presentation.set_character(id)
		verify(game.presentation.character_id == id and game.presentation.wings.size() == 2, "Kogane perfil "+id)
	game.player.position = Vector3(200, 0, 0)
	await frames(3)
	verify(game.presentation.companion.global_position.distance_to(game.player.global_position) < 3, "Kogane acompana teletransporte")
	game.respawn_player()
	verify(not game.presentation.busy() and game.rig_holder.visible, "reset limpia animaciones")
	print("RESULTADO %d/%d" % [checks-failures, checks])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)

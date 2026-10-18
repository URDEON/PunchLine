extends SceneTree
var game: Node3D
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func verify(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+label)
func reset() -> void:
	game.reset_lab()
	for i in range(game.enemies.size()):
		game.set_dummy_mode(game.enemies[i],0)
		game.enemies[i].body.position = Vector3(35+i*4,0.05,30)
	await frames(45)
func run() -> void:
	game = load("res://main.tscn").instantiate(); root.add_child(game)
	await reset()
	var enemy: Dictionary = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,0,-1.8)
	game.moves.freeze_enemy(enemy,5)
	var pane: Node3D = enemy.projection_frame
	verify(pane.rear_portrait != null and pane.rear_viewport != null,"dos superficies y cámaras independientes para frente y espalda")
	verify(pane.portrait.material_override != pane.rear_portrait.material_override,"texturas/materiales independientes de las caras")
	verify(pane.portrait.material_override.cull_mode == BaseMaterial3D.CULL_BACK,"cada imagen visible desde su cara sin duplicación")
	verify(pane.global_basis.z.dot(-enemy.body.global_basis.z) > 0.99,"frente del vidrio sigue orientación del actor")
	verify(not enemy.rig_holder.visible,"actor 3D oculto durante cristalización")
	game.perform_hit(enemy,5,0,Vector3.FORWARD,2,0,.3)
	verify(enemy.hp == 95 and enemy.projection_freeze == 0,"un golpe válido hace daño una vez y rompe el vidrio")
	verify(enemy.rig_holder.visible and enemy.projection_frame == null,"rotura restaura 3D y limpia referencia antes de aplicar knockback")
	verify(not pane.dissolve("hit"),"un vidrio destruido no vuelve a romperse")
	verify(game.feedback.effects.size() >= 10,"fragmentos ligeros dispersados")
	await frames(70)
	verify(not is_instance_valid(pane) and game.feedback.effects.size() == 0,"residuos y vidrio desaparecen sin colisiones nuevas")
	for side in [-1,1]:
		await reset()
		enemy.body.position = game.player.position+Vector3(0,0,-1.8)
		enemy.body.rotation.y = 0 if side == 1 else PI
		game.moves.freeze_enemy(enemy,5)
		game.punch()
		await frames(12)
		verify(enemy.projection_freeze == 0 and enemy.hp < 100,"M1 real rompe vidrio desde lado "+str(side))
	await reset()
	game.moves.freeze_enemy(enemy,5)
	await frames(299)
	verify(enemy.projection_freeze > 0,"vidrio permanece antes de cumplir cinco segundos")
	await frames(2)
	verify(enemy.projection_freeze == 0 and enemy.rig_holder.visible,"vidrio finaliza a cinco segundos sin golpe")
	await reset()
	game.moves.press(2)
	await frames(36)
	verify(game.moves.player_freeze > 4.8 and game.moves.player_frame != null,"counter fallido cristaliza a Naoya durante cinco segundos")
	verify(not game.rig_holder.visible and enemy.projection_frame == null,"penalización aplicada al jugador y no al enemigo")
	game.hit_player_from_enemy(enemy,Vector3.BACK)
	verify(game.moves.player_freeze == 0 and game.hp == 94,"ataque real rompe penalización y conserva daño normal")
	verify(game.rig_holder.visible,"golpe no deja superposición ni representación oculta")
	await reset()
	enemy.body.position = game.player.position+Vector3(0,0,-1.8)
	game.moves.press(2); await frames(8)
	game.hit_player_from_enemy(enemy,Vector3.BACK)
	verify(enemy.hp == 92 and enemy.projection_freeze > 4.9 and game.moves.player_freeze == 0,"counter acertado conserva daño y cristaliza al atacante")
	await reset()
	game.start_form("FORM2",true); await frames(130)
	var model: Node3D = game.presentation.form_models[1]
	verify((-model.global_basis.z).normalized().dot(Vector3.UP) > .99,"fase2 en reposo vertical con cabeza arriba")
	verify(model.global_basis.x.normalized().dot(game.facing_forward()) > .99,"fase2 cara hacia delante en reposo")
	Input.action_press("forward"); await frames(30)
	verify((-model.global_basis.z).normalized().dot(game.facing_forward()) > .98 and model.global_basis.x.normalized().dot(Vector3.DOWN) > .98,"cabeza delante y torso hacia suelo durante desplazamiento")
	Input.action_release("forward")
	game.feedback.stop_all(); OS.delay_msec(100)
	print("RESULTADO %d/%d" % [checks-failures,checks])
	game.queue_free(); await process_frame; await process_frame
	quit(1 if failures else 0)

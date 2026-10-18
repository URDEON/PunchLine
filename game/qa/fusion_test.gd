extends SceneTree
var checks := 0
var passed := 0
var game: Node3D
func _initialize() -> void: run.call_deferred()
func check(ok: bool,title: String) -> void:
	checks += 1
	if ok: passed += 1
	print("PASS " if ok else "FAIL ",title)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	var demo: Node3D = preload("res://FusionDemo.tscn").instantiate(); demo.autoplay = false; demo.automatic_process = false; root.add_child(demo)
	check(demo._originals.size() == 4 and demo._pieces.size() == 22,"demo importa cuatro mechas y veintidós módulos")
	var finished := [0]; demo.fusion_finished.connect(func(_model: Node3D) -> void: finished[0] += 1)
	demo.play_fusion(); demo.advance(2.0)
	check(demo._jets.size() == 4 and demo._jets[1].visible,"propulsores visibles durante llegada")
	demo.advance(9.5); demo.advance(.1)
	check(finished[0] == 1 and demo._clock == 11.5,"señal única al completar 11.5 segundos")
	var min_y := INF; var max_y := -INF; var textured := 0
	for part in demo._pieces.values():
		var bounds: AABB = part.global_transform*part.get_aabb(); min_y = minf(min_y,bounds.position.y); max_y = maxf(max_y,bounds.end.y)
		var material: StandardMaterial3D = part.get_active_material(0)
		if material != null and material.albedo_texture != null: textured += 1
	check(absf(max_y-min_y-4.0) < .0001,"altura final exacta de cuatro metros")
	check(textured == 22,"veintidós piezas conservan sus texturas")
	check(demo._landed.size() == 22,"todos los módulos encajan una vez")
	demo.queue_free(); await process_frame
	game = preload("res://main.tscn").instantiate(); root.add_child(game); await frames(8)
	for enemy in game.enemies: game.set_dummy_mode(enemy,0)
	game.robots.forced = 1; game.robots.select(1); game.robots.forced = -1; await frames(5)
	game.player.position = Vector3(0,.2,0); game.player.velocity = Vector3.ZERO; await frames(5)
	game.charge = 100
	check(game.fusion.request(),"G se integra con el controlador robot")
	check(game.fusion.sequence.original_names[0] == "Stan" and game.fusion.sequence.original_names.size() == 4,"chasis actual al frente y otros tres sin repetir")
	check(not game.can_start_action() and game.player.collision_layer == 0,"cinemática bloquea combate y colisiones del jugador")
	check(not game.fusion.request(),"G repetida no reinicia la secuencia de combate")
	game.fusion.sequence.advance(11.5)
	check(game.fusion.fused and not game.fusion.cinematic,"fusion_finished activa el control final")
	check(is_equal_approx(game.robots.naoya.collision.shape.height,4.0) and game.robots.naoya.collision.position.y == 2,"colisión final adaptada a cuatro metros")
	check(game.can_start_action(),"habilidades del fusionado se desbloquean al terminar el montaje")
	game.fusion.shake_strength = 0; game.fusion.shake_time = 0
	game.fusion.impulse(game.player.position+Vector3.RIGHT*4.1,1); check(game.fusion.shake_strength == 0,"pasos no sacuden cámaras fuera de cuatro metros")
	game.fusion.impulse(game.player.position+Vector3.RIGHT*2,1); check(game.fusion.shake_strength > 0,"pasos alcanzan cámaras cercanas con atenuación")
	game.fusion.reset(); check(not game.fusion.busy() and game.rig_holder.visible and game.player.collision_layer != 0,"reinicio restaura robot, colisiones y controles")
	for index in range(4):
		game.robots.forced = index; game.respawn_player(); game.robots.forced = -1; await frames(3)
		game.skill_vfx.cast_local(1,100+index); check(not game.skill_vfx.effects.is_empty(),"efecto de habilidad para "+game.robots.NAMES[index]); game.skill_vfx.clear()
	game.feedback.stop_all(); game.queue_free(); await process_frame; await process_frame
	print("RESULTADO ",passed,"/",checks); quit(0 if passed == checks else 1)

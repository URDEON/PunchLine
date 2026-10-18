extends SceneTree
var game: Node3D
var output: String
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func photo(tag: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(tag+".png")); print("PHOTO ",tag)
func camera_at(offset: Vector3, focus: float = 2.1) -> void:
	game.camera.global_position = game.player.global_position+offset
	game.camera.look_at(game.player.global_position+Vector3.UP*focus)
func ready_attack() -> void:
	game.fusion.combat.interrupted(); game.fusion.combat.cooldowns = [0.0,0.0,0.0,0.0]
	game.fusion.combat.m1_cooldown = 0; game.stun = 0; game.block = false
func run() -> void:
	output = OS.get_environment("NAOYA_QA_OUTPUT")
	if output.is_empty(): output = ProjectSettings.globalize_path("user://revision_mega_v0915")
	DirAccess.make_dir_recursive_absolute(output)
	game = preload("res://main.tscn").instantiate(); root.add_child(game); await frames(10)
	for enemy in game.enemies: game.set_dummy_mode(enemy,0); enemy.body.position = Vector3(30,0,30)
	game.robots.forced = 1; game.robots.select(1); game.player.position = Vector3(0,.2,0); await frames(5)
	game.charge = 100; game.fusion.request(); game.fusion.sequence.advance(10.7)
	game.set_process(false); camera_at(Vector3(6,4,-8)); await photo("01_humo_final")
	game.fusion.sequence.advance(.8); await frames(5)
	camera_at(Vector3(3.8,3.2,-6.5)); await photo("02_hombros_idle")
	game.punch(); await frames(22); await photo("03_m1_preparacion")
	await frames(15); await photo("04_m1_suelo")
	ready_attack(); game.moves.press(1); await frames(38); await photo("05_canon_carga")
	await frames(22); await photo("06_canon_disparo")
	ready_attack(); game.moves.press(2); await frames(67); await photo("07_martillo")
	ready_attack(); game.moves.press(3); await frames(46); await photo("08_pisoton")
	ready_attack(); game.dash_cd = 0; game.start_dash(); await frames(12)
	camera_at(Vector3(5,3,-7)); await photo("09_propulsion")
	await frames(85); game.interface.open_menu("settings"); await frames(18); await photo("10_ajustes_3d")
	game.set_paused(false); game.fusion.reset()
	for index in range(4):
		game.robots.forced = index; game.respawn_player(); game.player.position = Vector3(0,.1,0); game.model.rotation.y = 0
		await frames(5); game.moves.press(1); await frames(18)
		camera_at(Vector3(3,2.1,-4.8),1); await photo("base_"+game.robots.NAMES[index])
	game.feedback.stop_all(); game.queue_free(); await create_timer(.25).timeout; quit.call_deferred()

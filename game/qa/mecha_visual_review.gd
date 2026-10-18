extends SceneTree
var game: Node3D
var output := ""
func _initialize() -> void: run.call_deferred()
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/"+name+".png")
	print("CAPTURA ",name)
func run() -> void:
	output = OS.get_environment("NAOYA_QA_OUTPUT")
	if output.is_empty(): output = ProjectSettings.globalize_path("user://mecha_visual_review")
	DirAccess.make_dir_recursive_absolute(output)
	game = preload("res://main.tscn").instantiate(); root.add_child(game)
	await frames(10)
	for enemy in game.enemies: game.set_dummy_mode(enemy,0)
	game.robots.forced = 1; game.robots.select(1); game.robots.forced = -1
	game.charge = 100; await frames(10); await shot("01_hud_base")
	game.set_paused(false); game.fusion.request()
	await frames(110); await shot("02_thrusters")
	await frames(440); await shot("03_activation")
	while game.fusion.elapsed < 10.82: await physics_frame
	await shot("03b_impact_dust")
	while not game.fusion.fused: await physics_frame
	await frames(20); await shot("04_idle")
	game.yaw = PI; await frames(20); await shot("04b_front")
	game.yaw = 0; await frames(20)
	Input.action_press("forward"); await frames(37); await shot("05_walk")
	await frames(55); await shot("06_walk_other_foot")
	Input.action_release("forward"); await frames(30)
	var enemy: Dictionary = game.enemies[0]
	game.set_dummy_mode(enemy,0); enemy.body.position = game.player.position+game.facing_forward()*3.5; enemy.body.velocity = Vector3.ZERO
	await frames(3); game.punch(); await frames(34); await shot("06b_heavy_punch")
	await frames(45)
	game.interface.open_menu("settings"); await frames(20); await shot("07_settings")
	print("REVISION_GRAFICA_TERMINADA")
	game.queue_free(); await process_frame; quit()

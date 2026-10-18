extends SceneTree
var game: Node3D
var output: String
func _initialize() -> void: run.call_deferred()
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func photo(tag: String) -> void:
	await RenderingServer.frame_post_draw
	print("PHOTO ",tag," physical=",game.physical_ragdoll.active," recovery=",game.physical_ragdoll.recovering)
	root.get_texture().get_image().save_png(output.path_join(tag+".png"))
func run() -> void:
	output = OS.get_environment("NAOYA_QA_OUTPUT"); DirAccess.make_dir_recursive_absolute(output)
	game = load("res://main.tscn").instantiate(); root.add_child(game); await frames(30)
	for index in range(4):
		game.robots.forced = index
		if game.robots.active: game.respawn_player()
		else: game.robots.select(1)
		game.robots.forced = -1; game.set_paused(false)
		for enemy in game.enemies: game.set_dummy_mode(enemy,0); enemy.body.position = Vector3(35,0,35)
		game.player.position = Vector3(0,.3,5); game.player.velocity = Vector3.ZERO; game.model.rotation.y = 0
		await frames(45)
		game.set_process(false); game.camera.global_position = Vector3(3,2.5,0); game.camera.look_at(game.player.global_position+Vector3.UP,Vector3.UP)
		await frames(8); await photo(str(index)+"_idle")
		Input.action_press("forward"); await frames(20); Input.action_release("forward")
		game.camera.global_position = game.player.position+Vector3(3,2.5,-5); game.camera.look_at(game.player.global_position+Vector3.UP,Vector3.UP)
		await photo(str(index)+"_run")
		await frames(30)
		var enemy: Dictionary = game.enemies[0]; enemy.combo = 4; enemy.body.position = game.player.position+Vector3.FORWARD*1.5
		game.player_wakeup_protection = 0; game.hit_player_from_enemy(enemy,Vector3.BACK)
		await frames(8)
		game.camera.global_position = game.player.position+Vector3(3,2.5,-5); game.camera.look_at(game.player.global_position+Vector3.UP,Vector3.UP)
		await photo(str(index)+"_ragdoll")
		for i in range(160):
			await physics_frame
			if not game.player_ragdoll and game.physical_ragdoll.recovering <= 0: break
		game.camera.global_position = game.player.position+Vector3(3,2.5,-5); game.camera.look_at(game.player.global_position+Vector3.UP,Vector3.UP)
		await photo(str(index)+"_recovery")
	game.feedback.stop_all(); game.queue_free(); await process_frame; await process_frame; quit()

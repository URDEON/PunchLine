extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,text: String) -> void:
	checks += 1; print("PASS " if ok else "FAIL ",text)
	if not ok: failures += 1
func run() -> void:
	var game: Node3D = load("res://main.tscn").instantiate(); root.add_child(game)
	var output := OS.get_environment("NAOYA_QA_OUTPUT")
	DirAccess.make_dir_recursive_absolute(output)
	for enemy in game.enemies: game.set_dummy_mode(enemy,0)
	for i in range(8): await process_frame
	game.moves.freeze_player(5)
	for i in range(8): await process_frame
	var frame: Node3D = game.moves.player_frame
	check(frame.image_ready,"captura gráfica real lista")
	var front: Image = frame.portrait.material_override.albedo_texture.get_image()
	var back: Image = frame.rear_portrait.material_override.albedo_texture.get_image()
	front.save_png(output.path_join("textura_frontal.png")); back.save_png(output.path_join("textura_trasera.png"))
	var difference := 0.0; var covered := 0
	back.flip_x()
	for y in range(0,front.get_height(),2):
		for x in range(0,front.get_width(),2):
			var a := front.get_pixel(x,y); var b := back.get_pixel(x,y)
			if maxf(a.a,b.a) < .1: continue
			covered += 1; difference += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)+absf(a.a-b.a)
	var mean := difference/maxi(covered,1)
	check(covered > 500 and mean > .05,"espalda real distinta del frente reflejado")
	print("PIXEL_METRICS covered=",covered," difference=",mean)
	game.yaw = PI
	for i in range(16): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("vidrio_frontal.png"))
	game.yaw = 0
	for i in range(16): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("vidrio_trasero.png"))
	check(not game.rig_holder.visible,"malla 3D oculta en ambos lados")
	game.moves.clear_player_frame()
	check(game.rig_holder.visible,"restaura malla al liberar")
	game.feedback.stop_all(); OS.delay_msec(150); game.queue_free(); await process_frame; await process_frame
	print("RESULTADO %d/%d" % [checks-failures,checks]); quit(1 if failures else 0)

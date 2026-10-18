extends SceneTree
# Ejecutar solo con un directorio de usuario de QA aislado.
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks += 1; print("PASS " if ok else "FAIL ",text)
	if not ok: failures += 1
func record(time: float) -> Dictionary:
	var bones: Array = []
	for i in range(53): bones.append(Quaternion.IDENTITY)
	return {"time":time,"samples":[{"time":0.0,"position":Vector3.ZERO,"pelvis":Vector3.ZERO,"rotation":0.0,"bones":bones},{"time":.1,"position":Vector3.ONE,"pelvis":Vector3.ZERO,"rotation":0.0,"bones":bones}]}
func dispose(game: Node3D) -> void:
	game.feedback.stop_all(); OS.delay_msec(150); game.queue_free(); await process_frame; await process_frame
func run() -> void:
	if not OS.get_cmdline_user_args().has("--qa-controlled") or OS.get_environment("NAOYA_QA_OUTPUT") == "":
		push_error("Esta prueba necesita directorio de usuario aislado, NAOYA_QA_OUTPUT y --qa-controlled"); quit(1); return
	var previous := OS.get_user_data_dir().get_base_dir().path_join("Naoya - Laboratorio de combate 0.9.6")
	DirAccess.make_dir_recursive_absolute(previous)
	var config := ConfigFile.new(); config.set_value("settings","hud_scale",.65); config.set_value("settings","camera_distance",4.2)
	config.save(previous.path_join("preferences_v09.cfg"))
	FileAccess.open(previous.path_join("route_echo_v096.dat"),FileAccess.WRITE).store_var(record(11.25))
	var game: Node3D = load("res://main.tscn").instantiate(); root.add_child(game)
	for i in range(5): await physics_frame
	check(is_equal_approx(game.preferences.values.hud_scale,.65),"migra tamaño del HUD")
	check(is_equal_approx(game.preferences.values.camera_distance,4.2),"migra distancia de cámara")
	check(game.preferences.bindings.dash == KEY_Q and game.preferences.bindings.character == KEY_P and game.preferences.bindings.interact == KEY_E,"mantiene Q/P y añade E")
	check(is_equal_approx(game.route_trial.best_time,11.25) and game.route_trial.best_samples.size() == 2,"migra récord y muestras del Eco")
	game.preferences.values.hud_scale = .8; game.preferences.save()
	FileAccess.open("user://route_echo_v096.dat",FileAccess.WRITE).store_var(record(10.5))
	await dispose(game)
	config.set_value("settings","hud_scale",.55); config.save(previous.path_join("preferences_v09.cfg"))
	game = load("res://main.tscn").instantiate(); root.add_child(game)
	for i in range(5): await physics_frame
	check(is_equal_approx(game.preferences.values.hud_scale,.8),"no sobrescribe preferencias actuales")
	check(is_equal_approx(game.route_trial.best_time,10.5),"no sobrescribe récord actual")
	await dispose(game)
	print("RESULTADO %d/%d" % [checks-failures,checks]); quit(1 if failures else 0)

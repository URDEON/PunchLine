extends "res://qa/preferences_migration_v097_test.gd"
# La versión más reciente debe ganar frente a 0.9.6, sin pisar datos actuales.
func run() -> void:
	if not OS.get_cmdline_user_args().has("--qa-controlled") or OS.get_environment("NAOYA_QA_OUTPUT") == "":
		push_error("Esta prueba requiere un directorio QA aislado"); quit(1); return
	var parent := OS.get_user_data_dir().get_base_dir()
	for version in ["0.9.6","0.9.7"]:
		var directory := parent.path_join("Naoya - Laboratorio de combate "+version)
		DirAccess.make_dir_recursive_absolute(directory)
		var config := ConfigFile.new()
		config.set_value("settings","hud_scale",.65 if version == "0.9.7" else .55)
		config.set_value("settings","camera_distance",4.2 if version == "0.9.7" else 5.5)
		config.save(directory.path_join("preferences_v09.cfg"))
		FileAccess.open(directory.path_join("route_echo_v096.dat"),FileAccess.WRITE).store_var(record(11.25 if version == "0.9.7" else 12.5))
	var game: Node3D = load("res://main.tscn").instantiate(); root.add_child(game)
	for i in range(5): await physics_frame
	check(is_equal_approx(game.preferences.values.hud_scale,.65),"prefiere HUD guardado en 0.9.7")
	check(is_equal_approx(game.preferences.values.camera_distance,4.2),"prefiere cámara guardada en 0.9.7")
	check(is_equal_approx(game.route_trial.best_time,11.25),"prefiere récord de 0.9.7")
	check(game.preferences.values.reference_audio and is_equal_approx(game.preferences.values.combat,1.0),"añade ajustes de audio conservando los anteriores")
	game.preferences.values.hud_scale = .8; game.preferences.save()
	FileAccess.open("user://route_echo_v096.dat",FileAccess.WRITE).store_var(record(10.5))
	await dispose(game)
	game = load("res://main.tscn").instantiate(); root.add_child(game)
	for i in range(5): await physics_frame
	check(is_equal_approx(game.preferences.values.hud_scale,.8),"no pisa preferencias actuales")
	check(is_equal_approx(game.route_trial.best_time,10.5),"no pisa récord actual")
	await dispose(game)
	print("RESULTADO %d/%d" % [checks-failures,checks]); quit(1 if failures else 0)

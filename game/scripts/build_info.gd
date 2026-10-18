extends Node
## application/config/version is the single source for the current game version.
var version: String = str(ProjectSettings.get_setting("application/config/version","dev"))

func _enter_tree() -> void:
	get_window().title = "PunchLine " + version
	# Earlier builds included their version in config/name and therefore user://.
	# Move to a stable name while retaining saved settings from that directory.
	var legacy: String = OS.get_user_data_dir().get_base_dir().path_join("PunchLine - Laboratorio de combate 0.9.24")
	for filename in ["preferences_v09.cfg","world.cfg","online_profile.cfg"]:
		var destination: String = ProjectSettings.globalize_path("user://"+filename)
		var source: String = legacy.path_join(filename)
		if FileAccess.file_exists(source) and not FileAccess.file_exists(destination):
			DirAccess.copy_absolute(source,destination)

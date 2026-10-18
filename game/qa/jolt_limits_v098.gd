extends SceneTree
func _initialize() -> void:
	for property in ProjectSettings.get_property_list():
		if "jolt" in property.name and ("velocity" in property.name or "stabil" in property.name):
			print(property.name," value=",ProjectSettings.get_setting(property.name)," hint=",property.hint_string)
	quit()

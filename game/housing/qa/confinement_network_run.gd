extends SceneTree
func _initialize() -> void:
	var driver=preload("res://housing/qa/confinement_network_driver.gd").new()
	driver.name="ConfinementNetworkTest";root.add_child.call_deferred(driver)

extends SceneTree
func _initialize() -> void:
	var driver=preload("res://housing/qa/multistorey_network_driver.gd").new()
	driver.name="MultiStoreyNetworkTest";root.add_child.call_deferred(driver)

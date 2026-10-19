extends SceneTree
func _initialize()->void:
	var driver:Node=load("res://housing/qa/greenery_network_driver.gd").new();driver.name="GreeneryNetworkTest";root.add_child.call_deferred(driver)

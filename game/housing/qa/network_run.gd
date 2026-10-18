extends SceneTree
func _initialize() -> void:
	var driver:=load("res://housing/qa/network_driver.gd").new() as Node
	driver.name="HousingNetworkTest";root.add_child.call_deferred(driver)

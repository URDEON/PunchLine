extends SceneTree
func _initialize()->void:
	var driver=load("res://qa/v0930/network_driver.gd").new();driver.name="SpiderNetworkTest";root.add_child.call_deferred(driver)

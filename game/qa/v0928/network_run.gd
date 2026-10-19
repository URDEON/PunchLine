extends SceneTree
func _initialize():
 var driver=load("res://qa/v0928/network_driver.gd").new();driver.name="SpiderNetworkTest";root.add_child.call_deferred(driver)

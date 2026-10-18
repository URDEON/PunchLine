extends SceneTree
func _initialize()->void:
	var driver:=load("res://qa/rustcrawler/network_driver.gd").new() as Node
	driver.name="SpiderNetworkTest";root.add_child.call_deferred(driver)

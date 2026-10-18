extends SceneTree
func _initialize() -> void:
	var driver: Node = preload("res://qa/network/mecha_cases.gd").new() if OS.get_environment("NAOYA_NET_SCENARIO") == "mechas" else preload("res://qa/network/lifecycle.gd").new() if OS.get_environment("NAOYA_NET_ROLE").begins_with("lifecycle") else preload("res://qa/network/cases.gd").new()
	driver.name = "NetworkQA"; root.add_child.call_deferred(driver)

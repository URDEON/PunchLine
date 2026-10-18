extends SceneTree
func _initialize() -> void:
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_server(18212,2,3)
	print("ENET_PROBE ",result," ",error_string(result))
	if result == OK: peer.close()
	quit(0 if result == OK else 1)

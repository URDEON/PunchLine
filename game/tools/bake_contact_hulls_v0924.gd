extends SceneTree
func _initialize() -> void: run.call_deferred()
func skeleton_in(node: Node) -> Skeleton3D:
	if node is Skeleton3D:return node
	for child in node.get_children():
		var found := skeleton_in(child)
		if found != null:return found
	return null
func run() -> void:
	var profiles: Dictionary = {}
	for id in ["alien","Leela","Stan","George","Mike"]:
		var path: String = "res://assets/characters/alien/Alien_Naoya_Rig_Combat.glb" if id == "alien" else "res://assets/characters/robots/"+id+"/model.gltf"
		var model: Node3D = load(path).instantiate();root.add_child(model)
		var sk := skeleton_in(model)
		var physics: Node = load("res://scripts/physical_ragdoll.gd").new();physics.skeleton = sk
		var start := Time.get_ticks_usec();physics.prepare_contact_hulls(sk)
		var names: Array[String] = []
		for i in range(sk.get_bone_count()):names.append(sk.get_bone_name(i))
		profiles[id] = {"bones":names,"hulls":physics.contact_hulls.duplicate()}
		print("BAKED ",id," ",profiles[id].hulls.size()," bounds in ",(Time.get_ticks_usec()-start)/1000.0," ms")
		physics.free();model.free()
	var resource := Resource.new();resource.set_meta("profiles",profiles)
	var error := ResourceSaver.save(resource,"res://assets/physics/contact_hulls_v0924.tres")
	quit(0 if error == OK else 1)

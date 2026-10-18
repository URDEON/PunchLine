extends SceneTree
func own(node: Node,scene: Node) -> void:
	for child in node.get_children():child.owner=scene;own(child,scene)
func _initialize() -> void:
	var map:=load("res://scripts/VectorDistrict.gd").new() as Node3D
	root.add_child(map);map.build();own(map,map)
	var packed:=PackedScene.new();var status:=packed.pack(map)
	if status==OK:status=ResourceSaver.save(packed,"res://scenes/District500.tscn")
	print("VECTOR_BAKE ",status);quit(0 if status==OK else 1)

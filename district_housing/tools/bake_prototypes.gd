extends SceneTree
func _initialize() -> void:
	var generator := load("res://scripts/DistrictHousingGenerator.gd").new() as Node3D
	generator.name = "SyntheticPrototypeGallery"
	generator.set_meta("warning", "Synthetic dimensions. Isolated test gallery, not district placements or actual robot measurements.")
	root.add_child(generator)
	var types := ["workshop_crouch","warehouse_standing","small_residential","facade_only"]
	for i in range(types.size()):
		var building := Node3D.new()
		building.name = types[i]
		building.position.x = (i%2)*18
		building.position.z = (i/2)*18
		generator.add_child(building)
		var access: String = ["mecha_crouch","mecha_standing","player_only","inaccessible"][i]
		building.set_meta("access",access)
		generator.build(building, {"width":10.0,"depth":10.0,"height":4.9 if i==1 else 3.4,"door_width":2.2 if i<2 else 1.3,"door_height":4.3 if i==1 else 2.3,"access":access,"archetype":types[i]})
	generator.own_tree(generator,generator)
	var packed := PackedScene.new()
	var status := packed.pack(generator)
	if status == OK: status = ResourceSaver.save(packed,"res://scenes/SyntheticPrototypeGallery.tscn")
	print("Prototype gallery save=",status)
	quit(0 if status == OK else 1)

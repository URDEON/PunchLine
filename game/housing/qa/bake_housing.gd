extends SceneTree

func _initialize() -> void:
	var generator := load("res://housing/scripts/DistrictHousingGenerator.gd").new() as Node3D
	generator.name = "DistrictHousing"
	root.add_child(generator)
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		generator.plan_path = args[0]
	var data: Dictionary = generator.generate()
	if data.is_empty():
		quit(1)
		return
	generator.own_tree(generator, generator)
	var packed := PackedScene.new()
	var error := packed.pack(generator)
	if error == OK:
		error = ResourceSaver.save(packed, "res://housing/scenes/GeneratedHousing.tscn")
	print("BAKE buildings=", data.buildings.size(), " result=", error, " blockers=", data.blockers)
	quit(0 if error == OK else 1)

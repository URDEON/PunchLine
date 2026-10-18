extends SceneTree
func _initialize()->void:
	var generator:Node3D=load("res://housing/scripts/DistrictHousingGenerator.gd").new()
	root.add_child(generator)
	var plan:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/generated_plan.json"))
	DirAccess.make_dir_recursive_absolute("res://housing/scenes/prefabs")
	for archetype in ["small_residential","corner_shop","workshop_crouch","warehouse_standing"]:
		for b in plan.buildings:
			if b.archetype!=archetype:continue
			var building:=Node3D.new();building.name=archetype;building.set_meta("access",b.access)
			root.add_child(building);generator.build(building,b);generator.own_tree(building,building)
			var scene:=PackedScene.new();var status:=scene.pack(building)
			if status==OK:status=ResourceSaver.save(scene,"res://housing/scenes/prefabs/"+archetype+".tscn")
			if status!=OK:quit(1);return
			print("PREFAB ",archetype);building.queue_free();break
	quit(0)

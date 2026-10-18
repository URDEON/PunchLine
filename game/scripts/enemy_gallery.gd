extends Node3D
var appearance = preload("res://scripts/enemy_appearance.gd").new()
var records: Array[Dictionary] = []

func setup(seed_value: int = 950) -> void:
	for i in range(6):
		var scene: Node3D = load("res://assets/enemies/y2k/UrbanShadow_Rig.gltf").instantiate()
		add_child(scene); scene.position = Vector3((i-2.5)*2.0,0,0)
		var record: Dictionary = appearance.apply(scene,seed_value,i,i)
		scene.scale = Vector3.ONE*.76*float(record.height)
		record["scene"] = scene; records.append(record)
		var label := Label3D.new(); label.text = "Bandido %02d\n%s" % [i+1,record.name]
		label.position = scene.position+Vector3.UP*2.35; label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; label.font_size = 22; add_child(label)
		play_idle(scene)

func play_idle(node: Node) -> void:
	if node is AnimationPlayer:
		for name in node.get_animation_list():
			if "IdleAlert1" in str(name): node.play(name)
	for child in node.get_children(): play_idle(child)

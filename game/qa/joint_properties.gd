extends SceneTree
func _initialize() -> void:
	print("PHYSICS_ENGINE ",ProjectSettings.get_setting("physics/3d/physics_engine"))
	for prop in ProjectSettings.get_property_list():
		if str(prop.name) == "physics/3d/physics_engine": print(prop)
	var bone := PhysicalBone3D.new()
	bone.joint_type = PhysicalBone3D.JOINT_TYPE_HINGE
	for prop in bone.get_property_list():
		if str(prop.name).begins_with("joint_constraints"): print(prop," VALUE ",bone.get(prop.name))
	bone.joint_type = PhysicalBone3D.JOINT_TYPE_CONE
	for prop in bone.get_property_list():
		if str(prop.name).begins_with("joint_constraints"): print(prop," VALUE ",bone.get(prop.name))
	bone.free(); quit()

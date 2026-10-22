extends Node3D
## Original uploaded geometry, normalized once. It follows the same animated right hand.
var data: Resource
var muzzle: Marker3D
var source: Node3D

func setup(definition: Resource) -> void:
	data = definition
	source = load(data.model_path).instantiate()
	add_child(source)
	var bounds := AABB()
	var first := true
	for part in source.find_children("*","MeshInstance3D",true,false):
		var box: AABB = global_transform.affine_inverse()*part.global_transform*part.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
		for surface in range(part.mesh.get_surface_count()):
			var original: Material = part.get_active_material(surface)
			var material := original.duplicate() as StandardMaterial3D if original is StandardMaterial3D else StandardMaterial3D.new()
			material.roughness = 0.65
			material.albedo_color = Color.WHITE
			if data.id=="mp5a5":
				var ammo := String(original.resource_name).to_lower().contains("ammo") if original!=null else false
				material.albedo_texture = load("res://assets/weapons/mp5a5/texture/"+("ammo_texture.jpg" if ammo else "mp5a5_texture.jpg"))
				material.normal_enabled = true
				material.normal_texture = load("res://assets/weapons/mp5a5/texture/"+("ammo_normal map.jpg" if ammo else "mp5a5_normal map.jpg"))
			elif data.id=="m4a1": material.albedo_texture = load("res://assets/weapons/m4a1/PichuliruPalette.png")
			part.set_surface_override_material(surface,material)
	var length := maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
	var factor: float = data.model_length/maxf(length,0.0001)
	var forward: Vector3 = data.model_forward.normalized()
	var up: Vector3 = data.model_up.normalized()
	var orientation := Basis(forward.cross(up).normalized(),up,-forward).inverse()
	source.transform = Transform3D(orientation.scaled(Vector3.ONE*factor),-(orientation*bounds.get_center())*factor)*source.transform
	muzzle = Marker3D.new()
	muzzle.position = Vector3(0,0,-data.model_length*0.5)
	add_child(muzzle)

func muzzle_position() -> Vector3:
	return muzzle.global_position

extends RefCounted
const SHADER = preload("res://assets/enemies/y2k/region_recolor.gdshader")
const REGION_A = preload("res://assets/enemies/y2k/textures/regions_a.png")
const REGION_B = preload("res://assets/enemies/y2k/textures/regions_b.png")
const PALETTES = [
	["Negro y gris","282b33","555961","20232b","bfc3ca","b4bac6"],
	["Rojo oscuro","7c2636","342d35","4c1826","b7a4a5","5c3c45"],
	["Azul urbano","254e88","394b66","223b68","b1c7dd","aac6e5"],
	["Verde militar","485f3b","414839","34442b","a1a991","737e65"],
	["Blanco y gris","b5b7bc","72777e","969aa3","dcdfe5","d1d6df"],
	["Morado oscuro","563370","383044","412552","c4b1d1","776487"]]
const SKINS = ["d9a47b","b47850","855439","efc5a1"]
const HAIRS = ["281e18","111318","3b281c"]

func meshes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D and node.mesh != null: result.append(node)
	for child in node.get_children(): result.append_array(meshes(child))
	return result

func apply(scene: Node, seed_value: int, member: int, forced: int = -1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var order: Array[int] = [0,1,2,3,4,5]
	for i in range(5,0,-1):
		var j := rng.randi_range(0,i)
		var temp := order[i]; order[i] = order[j]; order[j] = temp
	var index: int = clampi(forced,0,5) if forced >= 0 else order[posmod(member,6)]
	rng.seed = seed_value + member*104729
	var palette: Array = PALETTES[index]
	var height := rng.randf_range(.97,1.03)
	for mesh in meshes(scene):
		var original := mesh.mesh.surface_get_material(0) as StandardMaterial3D
		if original == null: continue
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter("base_texture",original.albedo_texture)
		material.set_shader_parameter("normal_texture",original.normal_texture)
		material.set_shader_parameter("orm_texture",original.roughness_texture)
		material.set_shader_parameter("regions_a",REGION_A)
		material.set_shader_parameter("regions_b",REGION_B)
		for i in range(5): material.set_shader_parameter(["jacket","pants","hat","hoodie","shoes"][i],Color(palette[i+1]))
		material.set_shader_parameter("skin",Color(SKINS[rng.randi_range(0,SKINS.size()-1)]))
		material.set_shader_parameter("hair",Color(HAIRS[rng.randi_range(0,HAIRS.size()-1)]))
		mesh.material_override = material
	return {"id":"%d:%d:%d" % [seed_value,member,index],"seed":seed_value,"palette":index,"name":palette[0],"height":height}

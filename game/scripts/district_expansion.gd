extends Node3D
# Distrito modular Kenney. Mallas compartidas; colisiones simples en metros.
const ROOT := "res://assets/environment/v098/"
var game: Node3D
var terrain: Node3D
var urban: Node3D
var scene_cache: Dictionary = {}
var road_tiles: Array[Node3D] = []
var buildings: Array[StaticBody3D] = []
var roof_points: Array[Vector3] = []
var instance_count := 0
var wall_groups: Dictionary = {}
var wall_batches: Array[MultiMeshInstance3D] = []
var material_mesh_cache: Dictionary = {}
var road_materials: Dictionary = {}
var sky_material: PanoramaSkyMaterial
var morning: Texture2D = preload("res://assets/environment/v098/sky/skybox-morning.png")
var night: Texture2D = preload("res://assets/environment/v098/sky/skybox-night.png")

func setup(host: Node3D, arena: Node3D, district: Node3D) -> void:
	game = host; terrain = arena; urban = district; name = "DistrictExpansion098"
	build_roads(); build_houses(); flush_walls(); build_street_props(); build_boundary()
	urban.district_sign("DISTRITO 24 / BULEVAR",Vector3(47,3,46),Color("f4d3a2"),36)
	urban.district_sign("CALLE DE ACELERACIÓN\n144 m · dash · proyección",Vector3(47,2.1,43),Color("a4d8db"),22)
	urban.district_sign("AZOTEAS CONECTADAS\nRampa y pasarela",Vector3(-45,2.2,31),Color("e3c99a"),26)
	urban.district_sign("PLAZA ABIERTA\nCombate y esquiva",Vector3(-31,2,-17),Color("d1d7e4"),26)

func model(kind: String, asset: String, point: Vector3, size: Vector3, yaw: float = 0) -> Node3D:
	var path := ROOT+kind+"/"+asset+".glb"
	if not scene_cache.has(path): scene_cache[path] = load(path)
	var node: Node3D = (scene_cache[path] as PackedScene).instantiate()
	apply_lighting(node)
	add_child(node); node.position = point; node.scale = size; node.rotation.y = yaw
	instance_count += 1
	return node

func apply_lighting(node: Node) -> void:
	if node is MeshInstance3D and node.mesh is ArrayMesh:
		var id: int = node.mesh.get_instance_id()
		if not material_mesh_cache.has(id):
			var mesh := node.mesh.duplicate() as ArrayMesh
			for surface in range(mesh.get_surface_count()):
				var original: Material = mesh.surface_get_material(surface)
				if original is StandardMaterial3D:
					var material := original.duplicate() as StandardMaterial3D
					material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
					material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
					material.roughness = .88; material.metallic = 0
					mesh.surface_set_material(surface,material)
			material_mesh_cache[id] = mesh
		node.mesh = material_mesh_cache[id]
	for child in node.get_children(): apply_lighting(child)

func collider(label: String, point: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new(); body.name = label; add_child(body); body.position = point
	var collision := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size
	collision.shape = shape; body.add_child(collision)
	return body

func wall(asset: String, point: Vector3, yaw: float = 0) -> void:
	var path := ROOT+"urban/"+asset+".glb"
	if not scene_cache.has(path): scene_cache[path] = load(path)
	if not wall_groups.has(path): wall_groups[path] = []
	wall_groups[path].append(Transform3D(Basis(Vector3.UP,yaw).scaled(Vector3.ONE*3),point))
	instance_count += 1

func collect_wall_meshes(node: Node, parent: Transform3D, collected: Array[Dictionary]) -> void:
	var transform := parent
	if node is Node3D: transform = parent*node.transform
	if node is MeshInstance3D: collected.append({"node":node,"transform":transform})
	for child in node.get_children(): collect_wall_meshes(child,transform,collected)

func flush_walls() -> void:
	# Conserva las mallas/materiales originales, con una llamada por lote repetido.
	for path in wall_groups:
		var source: Node3D = scene_cache[path].instantiate()
		apply_lighting(source)
		var meshes: Array[Dictionary] = []; collect_wall_meshes(source,Transform3D.IDENTITY,meshes)
		for item in meshes:
			var visual: MeshInstance3D = item.node
			var batch := MultiMeshInstance3D.new(); batch.name = "FacadeBatch"
			batch.multimesh = MultiMesh.new(); batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			batch.multimesh.mesh = visual.mesh; batch.multimesh.instance_count = wall_groups[path].size()
			batch.material_override = visual.material_override; batch.cast_shadow = visual.cast_shadow
			for i in range(wall_groups[path].size()):
				batch.multimesh.set_instance_transform(i,wall_groups[path][i]*item.transform)
			add_child(batch); wall_batches.append(batch)
		source.free()
	wall_groups.clear()

func build_roads() -> void:
	var cells: Dictionary = {}
	for side in [-1,1]:
		for z in range(-66,67,12): cells[Vector2i(side*54,z)] = 0.0
		for x in range(-54,55,12): cells[Vector2i(x,side*54)] = PI*.5
	for cell in cells:
		var junction: bool = abs(cell.x) == 54 and abs(cell.y) == 54
		var crossing: bool = not junction and (cell.y in [-18,18] or cell.x in [-18,18])
		var point := Vector3(cell.x,.008,cell.y)
		var key := "junction" if junction else ("crossing" if crossing else "straight")
		if not road_materials.has(key):
			var material := ShaderMaterial.new(); material.shader = preload("res://shaders/district_road.gdshader")
			material.set_shader_parameter("asphalt_texture",preload("res://assets/environment/v098/urban/Textures/asphalt.png"))
			material.set_shader_parameter("pavement_texture",preload("res://assets/environment/v098/urban/Textures/tiles.png"))
			material.set_shader_parameter("junction",junction); material.set_shader_parameter("crossing",crossing)
			road_materials[key] = material
		var tile := MeshInstance3D.new(); var plane := PlaneMesh.new(); plane.size = Vector2(12,12); tile.mesh = plane
		add_child(tile); tile.position = point+Vector3.UP*.1; tile.rotation.y = cells[cell]
		tile.material_override = road_materials[key]; road_tiles.append(tile); instance_count += 1
		collider("RoadContact",point+Vector3.UP*.05,Vector3(12,.10,12))
	# Calzada de 8 m y aceras de 2 m incluidas en cada módulo, sin duplicarlas.

func solid_deck(point: Vector3, size: Vector3) -> void:
	var mesh: MeshInstance3D = game.box(self,size,point,Color("8b9297"))
	var material := StandardMaterial3D.new(); material.albedo_texture = preload("res://assets/environment/v098/urban/Textures/roof_plates.png")
	material.albedo_color = Color("adb5b8"); material.roughness = .88; material.uv1_scale = Vector3(size.x/2,size.z/2,1)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS; mesh.material_override = material

func house(point: Vector3, variant: int) -> void:
	var body := collider("UrbanRoofHouse",point+Vector3.UP*3,Vector3(12,6,12)); buildings.append(body)
	for floor_index in range(2):
		for cell in range(4):
			var offset := -4.5+cell*3
			var asset := "wall-a-flat-window"
			wall(asset,point+Vector3(offset,floor_index*3,6),PI)
			wall(asset,point+Vector3(offset,floor_index*3,-6))
			wall(asset,point+Vector3(-6,floor_index*3,offset),PI*.5)
			wall(asset,point+Vector3(6,floor_index*3,offset),-PI*.5)
	solid_deck(point+Vector3.UP*6.098,Vector3(12,.196,12))
	collider("HouseRoofContact",point+Vector3.UP*6.098,Vector3(12,.196,12))
	roof_points.append(point+Vector3.UP*6.196)
	# Barandas físicas solo en los extremos, dejando libre el acceso de las rampas.
	for side in [-1,1]: terrain.platform(point+Vector3(side*5.8,6.7,0),Vector3(.15,1,8),Color("676370"))

func build_houses() -> void:
	var index := 0
	for side in [-1,1]:
		for z in [-14,30,50]: house(Vector3(side*68,0,z),index); index += 1
	for x in [-20,20]: house(Vector3(x,0,68),index); index += 1
	terrain.ramp(Vector3(-68,.10,0),Vector3(-68,6.196,24),3.8)
	terrain.ramp(Vector3(68,.10,-44),Vector3(68,6.196,-20),3.8)
	terrain.ramp(Vector3(-10,.10,68),Vector3(14,6.196,68),3.8)
	for side in [-1,1]:
		solid_deck(Vector3(side*68,6.098,40),Vector3(4,.196,8))
		collider("RoofWalkway",Vector3(side*68,6.098,40),Vector3(4,.196,8))

func build_street_props() -> void:
	for side in [-1,1]:
		for z in [-42,-6,36,60]: model("roads","light-curved",Vector3(side*47,0,z),Vector3.ONE*7,-side*PI*.5)
		for z in [-30,19,43]:
			model("urban","tree-park-large",Vector3(side*43,0,z),Vector3.ONE*4)
			collider("TreeTrunk",Vector3(side*43,1.8,z),Vector3(.65,3.6,.65))
		model("urban","detail-bench",Vector3(side*45,0,12),Vector3.ONE*3,side*PI*.5)
		model("urban","detail-dumpster-closed",Vector3(side*62,0,-28),Vector3.ONE*2)
	model("urban","truck-grey",Vector3(-61,.1,-40),Vector3.ONE*3)
	collider("ParkedTruck",Vector3(-61,1.5,-40),Vector3(2.5,2.8,4.9))
	model("urban","truck-green",Vector3(62,.1,40),Vector3.ONE*3,PI)
	collider("ParkedTruck",Vector3(62,1.5,40),Vector3(2.5,2.8,4.9))
	for x in [-37,37]:
		model("roads","construction-barrier",Vector3(x,0,-8),Vector3.ONE*7,PI*.5)
		model("roads","construction-cone",Vector3(x-2,0,-7),Vector3.ONE*6)

func build_boundary() -> void:
	for side in [-1,1]:
		terrain.platform(Vector3(side*79.5,1.5,0),Vector3(.5,3,160),Color("535562"))
		terrain.platform(Vector3(0,1.5,side*79.5),Vector3(160,3,.5),Color("535562"))

func set_sky(is_night: bool) -> void:
	if sky_material == null:
		sky_material = PanoramaSkyMaterial.new()
		sky_material.filter = true
	sky_material.panorama = night if is_night else morning
	var environment: WorldEnvironment = game.get_node("ArenaEnvironment")
	if environment.environment.sky == null: environment.environment.sky = Sky.new()
	environment.environment.sky.sky_material = sky_material

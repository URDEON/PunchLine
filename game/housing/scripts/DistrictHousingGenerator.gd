@tool
extends Node3D
## Instantiates only a geometrically validated offline plan. Explicit rebuild, never per frame.
@export_file("*.json") var plan_path := "res://housing/data/generated_plan.json"
var materials: Dictionary = {}

func material(key: String, color: Color) -> StandardMaterial3D:
	if not materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.85
		materials[key] = m
	return materials[key]

func part(parent: Node3D, label: String, size: Vector3, at: Vector3, mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = at
	parent.add_child(body)
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = mat
	mesh.visibility_range_end = 180.0
	mesh.visibility_range_end_margin = 15.0
	body.add_child(mesh)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	return body

func category(parent: Node3D, label: String) -> Node3D:
	var n := Node3D.new()
	n.name = label
	parent.add_child(n)
	return n

func generate() -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(plan_path))
	if not parsed is Dictionary or not parsed.has("buildings"):
		push_error("Invalid housing plan: " + plan_path)
		return {}
	var fingerprint := JSON.stringify(parsed).sha256_text()
	if get_meta("plan_hash", "") == fingerprint:
		return parsed
	var previous := get_node_or_null("GeneratedBuildings")
	if previous:
		remove_child(previous)
		previous.free()
	var root := category(self, "GeneratedBuildings")
	for b in parsed.buildings:
		var lot := root.get_node_or_null(NodePath(b.lot)) as Node3D
		if not lot:
			lot = category(root, b.lot)
		var building := category(lot, b.id)
		building.position = Vector3(b.center[0], 0.146, b.center[1])
		building.rotation.y = b.rotation
		building.set_meta("access", b.access)
		building.set_meta("archetype", b.archetype)
		building.set_meta("entry", b.entry)
		build(building, b)
	set_meta("plan_hash", fingerprint)
	return parsed

func build(root: Node3D, b: Dictionary) -> void:
	var w: float = b.width
	var d: float = b.depth
	var h: float = b.height
	var dw: float = b.door_width
	var dh: float = b.door_height
	var wall := material("wall_" + b.archetype, Color(0.68, 0.59, 0.43) if b.access == "inaccessible" else Color(0.67, 0.74, 0.70))
	var slab := material("slab", Color(0.34, 0.36, 0.38))
	var floors := category(root, "Floors")
	var walls := category(root, "Walls")
	var roof := category(root, "Roof")
	roof.add_to_group("housing_roofs")
	part(floors, "Slab", Vector3(w, 0.12, d), Vector3(0,-0.06,0), slab)
	part(roof, "RoofSlab", Vector3(w,0.25,d), Vector3(0,h+0.125,0), slab)
	if b.access == "inaccessible":
		part(walls, "SolidInaccessible", Vector3(w,h,d), Vector3(0,h/2,0), wall)
		return
	part(walls, "Back", Vector3(w,h,0.25), Vector3(0,h/2,-d/2+0.125), wall)
	part(walls, "Left", Vector3(0.25,h,d), Vector3(-w/2+0.125,h/2,0), wall)
	part(walls, "Right", Vector3(0.25,h,d), Vector3(w/2-0.125,h/2,0), wall)
	var doors := category(root, "Doors")
	doors.set_meta("functional", "open passage; collision preserved on jambs and lintel")
	var side := (w-dw)/2
	part(doors, "LeftJamb", Vector3(side,h,0.25), Vector3(-(dw+side)/2,h/2,d/2-0.125), wall)
	part(doors, "RightJamb", Vector3(side,h,0.25), Vector3((dw+side)/2,h/2,d/2-0.125), wall)
	part(doors, "Lintel", Vector3(dw,h-dh,0.25), Vector3(0,(h+dh)/2,d/2-0.125), wall)
	if b.has("support_footprint"):
		var ramps := category(root, "Ramps")
		# Ramp ends at floor top; stays wholly inside the validated support footprint.
		var ramp := part(ramps,"EntranceRamp",Vector3(dw,0.08,1.2),Vector3(0,-0.10,d/2+0.6),slab)
		ramp.rotation.x = atan2(0.12,1.2)
	var rooms := category(root, "Interiors")
	# Two connected rooms, with a straight through route wide enough for the same body.
	part(rooms, "PartitionLeft", Vector3(side,h,0.2), Vector3(-(dw+side)/2,h/2,0), wall)
	part(rooms, "PartitionRight", Vector3(side,h,0.2), Vector3((dw+side)/2,h/2,0), wall)
	var windows := category(root, "Windows")
	# Inset glass decoration never removes the load-bearing wall's collision.
	var glass := material("glass", Color(0.12,0.25,0.32))
	part(windows, "BackWindow", Vector3(minf(w-1,2.5),0.9,0.03), Vector3(0,1.8,-d/2+0.02), glass)

func set_roof_visible(building: Node3D, show_roof: bool) -> void:
	# Visibility only. StaticBody3D and collision shapes remain enabled.
	for child in building.get_node("Roof").find_children("*", "MeshInstance3D", true, false):
		child.visible = show_roof

func own_tree(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner = scene_root
		own_tree(child, scene_root)

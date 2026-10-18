extends RefCounted
## Agrupa únicamente superficies que comparten padre rígido y material.
## Las bisagras y las piezas del ensamblaje permanecen independientes.
var originals: Array[MeshInstance3D] = []
var batches: Array[MeshInstance3D] = []
var cache: Dictionary = {}
func build(sources: Array) -> void:
	var groups: Dictionary = {}
	for source in sources:
		if not source is MeshInstance3D or source.mesh == null or source.mesh.get_surface_count() != 1: continue
		var key := str(source.get_parent().get_instance_id())+":"+str(source.get_active_material(0).get_instance_id())
		if not groups.has(key): groups[key] = []
		groups[key].append(source)
	for group in groups.values():
		if group.size() < 2: continue
		var parent: Node3D = group[0].get_parent()
		var signature := ""
		for source in group: signature += str(source.mesh.get_instance_id())+str(source.transform)
		var mesh: ArrayMesh
		if cache.has(signature): mesh = cache[signature]
		else:
			var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for source in group: surface.append_from(source.mesh,0,source.transform)
			surface.set_material(group[0].get_active_material(0)); mesh = surface.commit(); cache[signature] = mesh
		var node := MeshInstance3D.new(); node.name = "RigidBatch"; node.mesh = mesh; parent.add_child(node); batches.append(node)
		for source in group: source.hide(); originals.append(source)
func restore() -> void:
	for node in batches:
		if is_instance_valid(node): node.free()
	batches.clear()
	for node in originals:
		if is_instance_valid(node): node.show()
	originals.clear()

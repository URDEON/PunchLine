extends Node3D
## Restos cosméticos acotados: mallas originales compartidas, solo colisión mundo.
var remaining := 3.6
var fragments: Array[MeshInstance3D] = []
var bodies: Array[RigidBody3D] = []
func capture(visual: Node3D, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = seed_value+119
	var meshes: Array[MeshInstance3D] = []
	preload("res://scripts/mesh_pose_snapshot.gd").collect(visual,meshes)
	var clusters: Dictionary = {}
	for source in meshes:
		var center: Vector3 = source.global_transform*source.get_aabb().get_center()
		var local: Vector3 = visual.to_local(center)
		var key := Vector3i(signf(local.x),floori(local.y*6),0)
		if not clusters.has(key): clusters[key] = []
		clusters[key].append(source)
	for cluster in clusters.values():
		var center := Vector3.ZERO
		for mesh in cluster: center += mesh.global_transform*mesh.get_aabb().get_center()
		center /= float(cluster.size())
		var body := RigidBody3D.new(); add_child(body); body.global_position = center
		body.collision_layer = 4; body.collision_mask = 1; body.mass = 7
		body.linear_damp = .5; body.angular_damp = .9; body.continuous_cd = true
		var shape := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3(.35,.35,.3)
		shape.shape = box; body.add_child(shape)
		for original in cluster:
			var mesh := MeshInstance3D.new(); mesh.mesh = original.mesh; mesh.material_override = original.material_override
			body.add_child(mesh); mesh.global_transform = original.global_transform; fragments.append(mesh)
		body.linear_velocity = Vector3(rng.randf_range(-2.3,2.3),rng.randf_range(1,3.5),rng.randf_range(-2.3,2.3))
		body.angular_velocity = Vector3(rng.randf_range(-1,1),rng.randf_range(-2,2),rng.randf_range(-1,1))
		bodies.append(body)
	for body in bodies:
		for other in bodies:
			if other != body: body.add_collision_exception_with(other)
func _process(delta: float) -> void:
	remaining -= delta
	if remaining < .65:
		for mesh in fragments: mesh.transparency = clampf(1-remaining/.65,0,1)
	if remaining <= 0: queue_free()

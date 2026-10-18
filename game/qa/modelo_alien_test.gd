extends SceneTree

var game: Node3D
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func verify(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + description)

func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node
	for child in node.get_children():
		var found := find_skeleton(child)
		if found != null: return found
	return null

func find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D: return node
	for child in node.get_children():
		var found := find_mesh(child)
		if found != null: return found
	return null

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for enemy in game.enemies: enemy.body.position = Vector3(30,0,30)
	for i in range(20): await physics_frame
	game.set_physics_process(false)
	verify(game.rig_enabled, "personaje enviado cargado con AnimationPlayer")
	var skeleton := find_skeleton(game.rig_scene)
	var mesh := find_mesh(game.rig_scene)
	verify(skeleton != null and skeleton.get_bone_count() == 53, "53 huesos compatibles con rig de combate")
	verify(mesh != null and mesh.skin != null and mesh.skin.get_bind_count() == 53, "malla vinculada al esqueleto")
	if skeleton == null or mesh == null:
		quit(1)
		return
	var material := mesh.mesh.surface_get_material(0) as StandardMaterial3D
	verify(mesh.material_override == null, "materiales del personaje conservados")
	verify(material != null and material.albedo_texture != null and material.albedo_texture.get_width() == 1024, "textura 1K del ultimo modelo enviado cargada")
	verify(material != null and material.normal_enabled and material.normal_texture != null, "mapa de normales cargado")
	var arrays: Array = mesh.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	verify(indices.size()/3 <= 12000 and indices.size()/3 >= 10000, "presupuesto de geometria del personaje")
	verify(vertices.size() < 12000, "vertices exportados dentro del presupuesto")
	verify(weights.size() == vertices.size()*4 and bones.size() == weights.size(), "cuatro influencias por vertice")
	var weights_ok := true
	var joints_ok := true
	var finite_ok := true
	var seams_ok := true
	var seams: Dictionary = {}
	for v in range(vertices.size()):
		finite_ok = finite_ok and vertices[v].is_finite()
		var total := 0.0
		var influences: Dictionary = {}
		for j in range(4):
			var w: float = weights[v*4+j]
			var bone: int = bones[v*4+j]
			total += w
			weights_ok = weights_ok and is_finite(w) and w >= 0
			joints_ok = joints_ok and bone >= 0 and bone < 53
			if w > 0.00001: influences[bone] = influences.get(bone,0.0)+w
		weights_ok = weights_ok and absf(total-1.0) < 0.001
		var position := vertices[v]
		var key := Vector3i(roundi(position.x*100000),roundi(position.y*100000),roundi(position.z*100000))
		if seams.has(key):
			var reference: Dictionary = seams[key]
			for bone in influences:
				seams_ok = seams_ok and absf(influences[bone]-reference.get(bone,0.0)) < 0.001
			for bone in reference:
				seams_ok = seams_ok and absf(reference[bone]-influences.get(bone,0.0)) < 0.001
		else: seams[key] = influences
	verify(weights_ok, "todos los vertices tienen pesos finitos normalizados")
	verify(joints_ok, "todos los pesos apuntan a huesos existentes")
	verify(finite_ok, "geometria sin posiciones invalidas")
	verify(seams_ok, "costuras UV comparten pesos y no se separan al animar")
	var original: Node3D = load(game.RIG_SCENE_PATH).instantiate()
	var original_anim: AnimationPlayer = game.find_animation_player(original)
	for name in original_anim.get_animation_list():
		verify(game.rig_anim.has_animation(name), "clip conservado: " + String(name))
	var clips := ["UnarmedIdleAlert1","UnarmedRunForward","UnarmedBlock","UnarmedAttackR1","UnarmedAttackKickR1","UnarmedKnockdown1","UnarmedGetup1","dance/RunningMan"]
	for name in clips:
		game.rig_anim.stop()
		game.rig_anim.play(name)
		game.rig_anim.seek(0.0,true)
		skeleton.force_update_all_bone_transforms()
		var hand := skeleton.find_bone("B_R_Hand")
		var before := skeleton.get_bone_global_pose(hand)
		game.rig_anim.seek(minf(0.25,game.rig_anim.get_animation(name).length*0.6),true)
		skeleton.force_update_all_bone_transforms()
		var after := skeleton.get_bone_global_pose(hand)
		verify(after.origin.is_finite() and not before.is_equal_approx(after), "pose real cambia en " + name)
	var collider: CollisionShape3D
	for child in game.player.get_children():
		if child is CollisionShape3D: collider = child
	verify(collider != null and collider.shape is CapsuleShape3D and is_equal_approx(collider.shape.height,1.9) and is_equal_approx(collider.shape.radius,0.38), "collider de movimiento conservado")
	original.free()
	print("RESULTADO %d/%d" % [checks-failures,checks])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)

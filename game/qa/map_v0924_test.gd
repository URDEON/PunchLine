extends SceneTree
var checks := 0
var passed := 0
func _initialize() -> void: run.call_deferred()
func check(value: bool,label: String) -> void:
	checks += 1
	if value: passed += 1
	print("PASS " if value else "FAIL ",label)
func run() -> void:
	var game: Node3D = load("res://main.tscn").instantiate();root.add_child(game)
	for i in range(30): await physics_frame
	var map: Node3D = game.arena.punchline
	check(map != null,"Ruined City se inicia como escenario principal")
	check(map.scene.scale.is_equal_approx(Vector3.ONE*map.MAP_SCALE),"escala aplicada una sola vez al nodo del mapa")
	check(map.collision_count == 29,"suelo, edificios y cinco vehículos tienen colisión")
	var car: MeshInstance3D
	for m in map.scene.find_children("*","MeshInstance3D",true,false):
		if m.mesh.get_aabb().size.is_equal_approx(Vector3(.74316075,.25385225,.43061405)):car = m
	if car != null:
		var box: AABB = car.global_transform*car.get_aabb()
		var axis: int = car.mesh.get_aabb().size.max_axis_index()
		var length: float = (car.global_basis[axis]*car.mesh.get_aabb().size[axis]).length()
		check(absf(length-4.4)<.03,"vehículo de referencia mide 4,4 m sobre su eje longitudinal")
		check(box.size.y > 1.45 and box.size.y < 1.55,"vehículo mide aproximadamente 1,5 m de alto")
	else: check(false,"vehículo de referencia identificable")
	check(game.player.global_position.y > -.2 and game.player.is_on_floor(),"aparición inicial sobre superficie real")
	check(map.height_adjustments == 3,"tres garajes ajustados por altura de piso, sin cambiar personajes")
	for marker in map.player_spawns:
		var position: Vector3 = map.grounded_point(marker.global_position)
		var ray := PhysicsRayQueryParameters3D.create(position+Vector3.UP,position-Vector3.UP,1);ray.exclude = [game.player.get_rid()]
		check(not game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(),"spawn con suelo: "+marker.name)
	var viewport := SubViewport.new();viewport.world_3d = World3D.new();root.add_child(viewport)
	var online: Node3D = load("res://network/online.tscn").instantiate();viewport.add_child(online)
	for i in range(5): await physics_frame
	check(online.map.scene.scale == map.scene.scale,"online utiliza la misma escala y geometría")
	check(online.map.collision_count == map.collision_count,"online conserva colisiones y vehículos")
	for i in range(3): check(online.spawn_for(i).distance_to(map.grounded_point(map.player_spawns[i].global_position))<.15,"spawn online coherente "+str(i))
	game.queue_free();viewport.queue_free()
	for i in range(10): await physics_frame
	print("RESULTADO ",passed,"/",checks);quit(0 if passed == checks else 1)

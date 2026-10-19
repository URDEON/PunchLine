@static_unload
extends Node3D
# District500, reconstructed from the user's vector data; original layers are preserved.
const MAP_SCALE := 1.0
const SCENE: PackedScene = preload("res://housing/scenes/District500.tscn")
var game: Node3D
var scene: Node3D
var housing: Node3D
var ambience: Node3D
var destruction: Node3D
var collision_count := 0
var height_adjustments := 0
var player_spawns: Array[Marker3D] = []
var enemy_spawns: Array[Marker3D] = []
var rng := RandomNumberGenerator.new()
var spawn_index := 0
var world_settings:Dictionary={}
var layout_hash:=""
var generation_worker:Thread

func setup(host: Node3D) -> void:
    game = host
    var config=preload("res://scripts/world_config.gd")
    var settings:Dictionary=game.world_settings if "session" in game else config.current()
    world_settings=config.normalized(settings)
    var plan:Dictionary=config.make_plan(settings)
    layout_hash=JSON.stringify(plan).sha256_text()
    rng.seed = 923
    scene = SCENE.instantiate()
    add_child(scene)
    housing = preload("res://housing/scripts/DistrictHousingGenerator.gd").new();housing.name="DistrictHousing"
    if OS.get_environment("PUNCHLINE_HOUSING_MODE") == "none":
        housing.free(); housing = null
    else:
        add_child(housing)
        housing.generate_plan(plan)
        housing.set_meta("world_settings",settings)
    ambience=preload("res://scripts/district_ambience.gd").new();add_child(ambience)
    ambience.setup(plan if housing!=null else {"buildings":[]},settings,game.preferences.values)
    destruction=preload("res://scripts/district_destruction.gd").new();add_child(destruction)
    destruction.setup(self,bool(settings.get("destructible",true)))
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/vector_meshes.json"))
    for point in data.spawns.slice(0,3):
        player_spawns.append(marker("Jugador",Vector3(point[0],.1,point[1])))
    for point in data.spawns.slice(3,6):
        enemy_spawns.append(marker("Enemigo",Vector3(point[0],.1,point[1])))
    collision_count = scene.find_children("*","CollisionShape3D",true,false).size()

func setup_async(host:Node3D,loading:CanvasLayer)->void:
    game=host
    var config=preload("res://scripts/world_config.gd")
    var settings:Dictionary=game.world_settings if "session" in game else config.current()
    world_settings=config.normalized(settings)
    loading.report(.08,"Calculando el mundo por semilla")
    await get_tree().process_frame
    generation_worker=Thread.new();var worker:Thread=generation_worker
    worker.start(func()->Dictionary:return config.make_plan(settings))
    while worker.is_alive():await get_tree().process_frame
    var plan:Dictionary=worker.wait_to_finish()
    layout_hash=JSON.stringify(plan).sha256_text()
    loading.report(.24,"Creando calles y colisiones del terreno")
    await get_tree().process_frame
    rng.seed = 923
    scene = SCENE.instantiate()
    add_child(scene)
    housing = preload("res://housing/scripts/DistrictHousingGenerator.gd").new();housing.name="DistrictHousing"
    if OS.get_environment("PUNCHLINE_HOUSING_MODE") == "none":
        housing.free(); housing = null
    else:
        add_child(housing)
        await housing.generate_plan_staged(plan,loading)
        housing.set_meta("world_settings",settings)
    ambience=preload("res://scripts/district_ambience.gd").new();add_child(ambience)
    loading.report(.65,"Sembrando árboles, hierba y decoraciones")
    await get_tree().process_frame
    await ambience.setup_staged(plan if housing!=null else {"buildings":[]},settings,game.preferences.values,loading)
    loading.report(.91,"Preparando colisiones y destrucción")
    await get_tree().process_frame
    destruction=preload("res://scripts/district_destruction.gd").new();add_child(destruction)
    destruction.setup(self,bool(settings.get("destructible",true)))
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/vector_meshes.json"))
    for point in data.spawns.slice(0,3):
        player_spawns.append(marker("Jugador",Vector3(point[0],.1,point[1])))
    for point in data.spawns.slice(3,6):
        enemy_spawns.append(marker("Enemigo",Vector3(point[0],.1,point[1])))
    collision_count = scene.find_children("*","CollisionShape3D",true,false).size()

func marker(label: String, point: Vector3) -> Marker3D:
    var node := Marker3D.new()
    node.name = label + str(get_child_count())
    add_child(node)
    node.position = point
    return node

func grounded_point(point: Vector3) -> Vector3:
    var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP*14.0,point - Vector3.UP*15.0,1)
    var excluded: Array[RID] = []
    var player: CharacterBody3D = game.get("player")
    if is_instance_valid(player): excluded.append(player.get_rid())
    var enemies: Array = game.get("enemies") if game.get("enemies") != null else []
    for enemy in enemies:
        if is_instance_valid(enemy.body): excluded.append(enemy.body.get_rid())
    ray.exclude = excluded
    var hit := get_world_3d().direct_space_state.intersect_ray(ray)
    return Vector3(point.x,float(hit.position.y)+0.06,point.z) if not hit.is_empty() else point+Vector3.UP*0.1

func respawn() -> void:
    spawn_index = rng.randi_range(0,player_spawns.size()-1)
    game.player.global_position = grounded_point(player_spawns[spawn_index].global_position)
    game.player.velocity = Vector3.ZERO
    game.player.reset_physics_interpolation()
    var facing: Vector3 = Vector3(0,0,-18)*MAP_SCALE-game.player.global_position
    facing.y = 0
    game.yaw = atan2(-facing.x,-facing.z)
    game.model.rotation.y = game.yaw
    game.camera_initialized = false

func place_enemies() -> void:
    for i in range(game.enemies.size()):
        var enemy: Dictionary = game.enemies[i]
        enemy.spawn = grounded_point(enemy_spawns[i%enemy_spawns.size()].global_position)
        game.reset_enemy(enemy)
        enemy.body.reset_physics_interpolation()

func finalize() -> void:
    await get_tree().physics_frame
    await get_tree().physics_frame
    if not is_inside_tree(): return
    place_enemies()
    respawn()

func rebuild_world(settings:Dictionary)->void:
    world_settings=preload("res://scripts/world_config.gd").normalized(settings)
    var plan:Dictionary=preload("res://scripts/world_config.gd").make_plan(world_settings)
    layout_hash=JSON.stringify(plan).sha256_text()
    for node in [destruction,ambience]:
        if is_instance_valid(node):remove_child(node);node.free()
    if housing!=null:
        housing.set_meta("plan_hash","");housing.generate_plan(plan);housing.set_meta("world_settings",world_settings)
    ambience=preload("res://scripts/district_ambience.gd").new();add_child(ambience);ambience.setup(plan,world_settings,game.preferences.values)
    destruction=preload("res://scripts/district_destruction.gd").new();add_child(destruction);destruction.setup(self,bool(world_settings.destructible))

func rebuild_world_async(settings:Dictionary,loading:CanvasLayer)->void:
    world_settings=preload("res://scripts/world_config.gd").normalized(settings)
    loading.report(.08,"Calculando el mundo del anfitrión")
    generation_worker=Thread.new();var worker:Thread=generation_worker;worker.start(func()->Dictionary:return preload("res://scripts/world_config.gd").make_plan(world_settings))
    while worker.is_alive():await get_tree().process_frame
    var plan:Dictionary=worker.wait_to_finish();layout_hash=JSON.stringify(plan).sha256_text()
    for node in [destruction,ambience]:
        if is_instance_valid(node):remove_child(node);node.free()
    if housing!=null:
        await housing.generate_plan_staged(plan,loading);housing.set_meta("world_settings",world_settings)
    ambience=preload("res://scripts/district_ambience.gd").new();add_child(ambience)
    await ambience.setup_staged(plan,world_settings,game.preferences.values,loading)
    destruction=preload("res://scripts/district_destruction.gd").new();add_child(destruction);destruction.setup(self,bool(world_settings.destructible))

func _exit_tree()->void:
    if generation_worker!=null and generation_worker.is_started():generation_worker.wait_to_finish()

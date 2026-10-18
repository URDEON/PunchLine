extends SceneTree
# Prueba local con Godot 4.4.1: usar --headless --path . --script res://qa/ruined_city_smoke_v0921_exp.gd
var passed := 0
var total := 0
func verify(ok: bool,description: String) -> void:
    total += 1
    if ok: passed += 1
    print(("PASS " if ok else "FAIL ")+description)
func _initialize() -> void:
    run.call_deferred()
func run() -> void:
    var loaded := load("res://main.tscn")
    verify(loaded is PackedScene,"escena principal importada")
    if not loaded is PackedScene:
        quit(1)
        return
    var game: Node3D = loaded.instantiate()
    root.add_child(game)
    for i in range(12): await physics_frame
    verify(game.arena.punchline != null,"mapa nuevo presente")
    if game.arena.punchline != null:
        verify(game.arena.punchline.scene.name == "RuinedCityFree5","GLB Ruined City activo")
        verify(game.arena.punchline.collision_count > 8,"superficies de ciudad tienen colisiones")
    game.robots.select(1)
    game.robots.forced = 3
    game.robots.spawn()
    for i in range(10): await physics_frame
    verify(game.robots.ability_count() == 3,"Mike tiene tercera habilidad")
    verify(game.robot_clearance != null,"control de altura procedural inicializado")
    game.player.global_position = Vector3(0,.1,-18)
    game.player.velocity = Vector3.ZERO
    game.robot_clearance.restore()
    var roof := StaticBody3D.new()
    roof.collision_layer = 1
    game.add_child(roof)
    roof.global_position = game.player.global_position+Vector3.UP*1.7
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(4,.2,4)
    collision.shape = shape
    roof.add_child(collision)
    for i in range(25): await physics_frame
    verify(game.robot_clearance.current_height < 1.97,"robot reduce capsula bajo cubierta")
    roof.queue_free()
    game.queue_free()
    for i in range(3): await physics_frame
    print("RESULTADO ",passed,"/",total)
    quit(0 if passed == total else 1)

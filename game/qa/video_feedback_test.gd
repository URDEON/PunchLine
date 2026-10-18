extends SceneTree
# Regresión de los casos observados en las grabaciones del usuario (Godot 4.7.2).
# Ejecuta contactos y física reales. Las posiciones iniciales son preparación de laboratorio.
var game: Node3D
var checks := 0
var failures := 0

func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func verify(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+description)

func prepare(distance: float, degrees: float) -> Dictionary:
	for action in ["left","right","forward","back","attack","block"]: Input.action_release(action)
	game.reset_lab()
	game.preferences.values.hold_attack = false
	game.preferences.values.effects = true
	game.yaw = 0
	for i in range(game.enemies.size()):
		var enemy: Dictionary = game.enemies[i]
		enemy.kind = 0
		enemy.body.position = Vector3(35+i*4,0.05,30)
		enemy.body.velocity = Vector3.ZERO
	await frames(12)
	var enemy: Dictionary = game.enemies[0]
	enemy.body.position = game.player.position+Vector3.FORWARD.rotated(Vector3.UP,deg_to_rad(degrees))*distance
	enemy.body.velocity = Vector3.ZERO
	await frames(2)
	return enemy

func until_stage(stage: String, limit: int = 130) -> bool:
	for i in range(limit):
		if game.moves.stage == stage: return true
		await frames(1)
	return false

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for distance in [1.2,1.8,2.2,4.0,8.0]:
		for degrees in [-49.0,-45.0,-30.0,-15.0,0.0,15.0,30.0,45.0,49.0]:
			var enemy: Dictionary = await prepare(distance,degrees)
			game.moves.press(1)
			var activated: bool = game.moves.key == "b1" and not game.moves.target.is_empty()
			await frames(125)
			verify(activated and enemy.hp == 82 and game.moves.projection.damage_applied == 18,"1 conecta18 contra quieto a%.1fm/%+.0f°" % [distance,degrees])
	var enemy: Dictionary = await prepare(1.8,45)
	var origin: Vector3 = game.player.position
	game.moves.press(1)
	var bounded := true
	for i in range(6):
		var before: Vector3 = game.moves.direction
		await frames(1)
		bounded = bounded and before.angle_to(game.moves.direction) <= game.tuning.turn_rate/60.0+0.002
	verify(bounded and game.moves.direction.x < -0.1,"preparación gira gradualmente hacia el blanco lateral")
	verify(game.player.position.distance_to(origin) < 0.03,"preparación gira sin teletransportar ni adelantar al jugador")
	enemy = await prepare(1.8,-30)
	game.moves.freeze_enemy(enemy,5)
	game.moves.press(1)
	await frames(125)
	verify(enemy.hp == 82 and enemy.projection_freeze == 0 and enemy.rig_holder.visible,"1 cercano conecta sobre blanco lateral y rompe vidrio al primer golpe válido")
	enemy = await prepare(1.8,45)
	game.moves.press(1)
	var committed: bool = await until_stage("commit")
	var heading: Vector3 = game.moves.direction
	game.yaw = -1.2
	var dodged: bool = game.start_enemy_dash(enemy,heading.cross(Vector3.UP))
	await frames(2)
	verify(committed and game.moves.direction.is_equal_approx(heading),"rumbo lateral queda fijo al comprometerse aunque cambie cámara")
	await frames(70)
	verify(dodged and enemy.hp == 100 and game.moves.projection.last_result == "esquivado" and enemy.sequence_hold == 0,"dash lateral final aún evita1 cercano sin retención gratuita")
	for degrees in [-55.0,55.0]:
		enemy = await prepare(1.8,degrees)
		game.moves.press(1)
		verify(game.moves.target.is_empty(),"selección sigue excluyendo blanco a%+.0f° fuera del cono" % degrees)
		await frames(125)
	enemy = await prepare(1.8,45)
	game.start_form("FORM2",true)
	await frames(130)
	game.moves.press(1)
	await frames(125)
	verify(enemy.hp == 78 and game.moves.projection.damage_applied == 22,"embestida evolucionada cercana lateral conecta22 una vez")
	enemy = await prepare(6,0)
	game.moves.press(1)
	await until_stage("barrage")
	# Dejar terminar el desplazamiento del último tick de entrada antes de medir reposo.
	await frames(4)
	var emitted: int = game.presentation.ghost_count
	verify(emitted > 0 and not game.presentation.ghosts.is_empty(),"avance real conserva estelas visibles en movimiento")
	var max_ghosts: int = game.presentation.ghosts.size()
	for i in range(20):
		await frames(1)
		max_ghosts = maxi(max_ghosts,game.presentation.ghosts.size())
	verify(game.presentation.ghost_count == emitted,"ráfaga estacionaria no acumula siluetas superpuestas")
	verify(max_ghosts <= 4,"avance y detención mantienen como máximo cuatro estelas")
	await frames(80)
	verify(game.presentation.ghosts.is_empty(),"estelas se eliminan después de la acción")
	enemy = await prepare(1.8,0)
	game.moves.press(1)
	await until_stage("barrage")
	emitted = game.presentation.ghost_count
	await frames(20)
	verify(game.presentation.ghost_count > emitted,"recorrido cercano físico sí deja estelas al desplazarse")
	game.reset_lab()
	verify(game.presentation.ghosts.is_empty(),"reiniciar laboratorio limpia las estelas anteriores")
	enemy = await prepare(6,0)
	game.preferences.values.effects = false
	emitted = game.presentation.ghost_count
	game.moves.press(1)
	await frames(125)
	verify(game.presentation.ghost_count == emitted and enemy.hp == 82,"desactivar efectos quita estelas y mantiene contactos reales")
	print("RESULT %d/%d OK" % [checks-failures,checks])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)

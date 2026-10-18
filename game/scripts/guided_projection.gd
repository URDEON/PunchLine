extends Node
# Giro limitado durante preparación/aproximación; el compromiso conserva el rumbo.
var game: Node3D
var moves: Node3D
var speed := 0.0
var close_variant := false
var target_lost := false
var phase_elapsed := 0.0
var orbit_start := 0.0
var sequence_elapsed := 0.0
var strike_index := 0
var strike_landed := false
var damage_hits := PackedFloat32Array()
var last_result := ""
var last_close_variant := false
var damage_applied := 0.0
var strike_revision := 0
var pose_timer := 0.0
var pose_mesh: ArrayMesh
const LEAD_DISTANCES := [1.9,3.15]

func setup(owner_game: Node3D, owner_moves: Node3D) -> void:
	game = owner_game
	moves = owner_moves

func camera_forward() -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, game.yaw)

func eligible(enemy: Dictionary) -> bool:
	return not enemy.is_empty() and is_instance_valid(enemy.body) and float(enemy.hp) > 0 and not bool(enemy.ragdoll) and float(enemy.get("wakeup_protection", 0.0)) <= 0.0

func line_of_sight(enemy: Dictionary) -> bool:
	if not eligible(enemy): return false
	var ray := PhysicsRayQueryParameters3D.create(game.player.global_position+Vector3.UP, preload("res://scripts/combat_geometry.gd").point(enemy,game.player.global_position+Vector3.UP))
	ray.exclude = [game.player.get_rid(), enemy.body.get_rid()]
	return game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func select_target() -> Dictionary:
	var best: Dictionary = {}
	var score := INF
	var forward := camera_forward()
	var threshold: float = cos(deg_to_rad(game.tuning.aim_half_angle_degrees))
	for enemy in game.enemies:
		if not eligible(enemy): continue
		var offset: Vector3 = preload("res://scripts/combat_geometry.gd").offset(enemy,game.player.global_position)
		if absf(offset.y) > 2.2: continue
		offset.y = 0
		var distance := offset.length()
		if distance < 0.01 or distance > float(game.tuning.aim_range): continue
		var dot := forward.dot(offset.normalized())
		if dot < threshold or not line_of_sight(enemy): continue
		var candidate: float = 1.0-dot+distance/game.tuning.aim_range*0.015
		if candidate < score:
			score = candidate
			best = enemy
	return best

func start() -> void:
	moves.target = select_target()
	target_lost = false
	close_variant = not moves.target.is_empty() and moves.target.body.global_position.distance_to(game.player.global_position) <= float(game.tuning.close_activation_range)
	last_close_variant = false
	last_result = "pendiente"
	damage_applied = 0.0
	phase_elapsed = 0.0
	sequence_elapsed = 0.0
	speed = game.tuning.initial_speed
	moves.direction = camera_forward()
	moves.stage = "windup"
	moves.remaining = game.tuning.projection_windup
	game.skill_dir = moves.direction
	strike_revision += 1
	if moves.key == "b1":
		game.feedback.sound("rush",game.player.global_position,-2.0)
		for distance in LEAD_DISTANCES:
			var point: Vector3 = game.player.global_position+moves.direction*distance
			var gate := preload("res://scripts/projection_echo.gd").new()
			moves.add_child(gate); gate.setup(moves.CYAN)
			moves.gates.append(point); moves.gate_nodes.append(gate)
		pose_timer = 0; refresh_pose(); update_gate()

func refresh_pose() -> void:
	if game.form != "BASE" or not game.rig_enabled: return
	var frame := Transform3D(Basis(Vector3.UP,game.model.rotation.y),game.player.global_position+Vector3.UP*1.15)
	pose_mesh = preload("res://scripts/mesh_pose_snapshot.gd").silhouette(game.rig_holder,game.visual_motion.skeleton,frame)
	for gate in moves.gate_nodes:
		if is_instance_valid(gate): gate.set_pose(pose_mesh)
	pose_timer = .12

func steer(delta: float) -> void:
	var desired := camera_forward()
	if not moves.target.is_empty():
		if not eligible(moves.target) or not line_of_sight(moves.target):
			target_lost = true
			moves.target = {}
			# Conserva el rumbo al perderlo; no adquiere otro objetivo durante esta acción.
			desired = moves.direction
		else:
			var offset: Vector3 = moves.target.body.global_position-game.player.global_position
			var prediction: float = minf(game.tuning.velocity_prediction, offset.length()/maxf(1.0, speed))
			offset += moves.target.body.velocity*prediction
			offset.y = 0
			if offset.length() > 0.01:
				# La cámara ayuda a dirigir lejos; cerca no desvía la entrada del blanco elegido.
				var camera_weight: float = game.tuning.camera_influence*clampf((offset.length()-game.tuning.commit_distance)/maxf(0.01,game.tuning.commit_distance),0.0,1.0)
				desired = offset.normalized().slerp(camera_forward(), camera_weight).normalized()
	elif target_lost:
		desired = moves.direction
	var angle: float = moves.direction.angle_to(desired)
	if angle > 0.001:
		moves.direction = moves.direction.slerp(desired, minf(1.0, game.tuning.turn_rate*delta/angle)).normalized()
	game.skill_dir = moves.direction

func wall_ahead() -> bool:
	var start: Vector3 = game.player.global_position+Vector3.UP
	var ray := PhysicsRayQueryParameters3D.create(start, start+moves.direction*0.85)
	var exclude: Array[RID] = [game.player.get_rid()]
	for enemy in game.enemies: exclude.append(enemy.body.get_rid())
	ray.exclude = exclude
	return not game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func commit() -> void:
	moves.stage = "commit"
	moves.remaining = game.tuning.commit_duration
	phase_elapsed = 0.0
	strike_revision += 1
	# direction queda fija hasta el impacto: ni cámara ni objetivo la corrigen aquí.

func update_gate() -> void:
	if moves.key != "b1" or moves.gate_nodes.is_empty(): return
	var forward: Vector3 = game.facing_forward() if moves.stage == "barrage" else moves.direction
	for i in range(moves.gate_nodes.size()):
		var point: Vector3 = game.player.global_position+forward*LEAD_DISTANCES[i]
		moves.gates[i] = point
		var gate: Node3D = moves.gate_nodes[i]
		gate.global_position = point+Vector3.UP*1.15
		gate.rotation.y = atan2(-forward.x,-forward.z)
		gate.set_opacity(.8 if i == 0 else .45)

func can_contact(enemy: Dictionary) -> bool:
	if not eligible(enemy) or not line_of_sight(enemy): return false
	var offset: Vector3 = preload("res://scripts/combat_geometry.gd").offset(enemy,game.player.global_position)
	if absf(offset.y) > 2.2: return false
	var start: Vector3 = game.player.global_position
	var end: Vector3 = start+moves.direction*float(game.tuning.impact_reach)
	start.y = 0; end.y = 0
	var point: Vector3 = enemy.body.global_position
	point.y = 0
	return Geometry3D.get_closest_point_to_segment(point, start, end).distance_to(point) <= float(game.tuning.impact_radius)

func fail(reason: String) -> void:
	last_result = reason
	game.presentation.comment("projection_miss")
	release_hold()
	moves.recover(game.tuning.miss_recovery)

func contact() -> void:
	var enemy: Dictionary = moves.target
	if enemy.is_empty() and not target_lost:
		# Contacto incidental sin fijación: solo la zona física delante del personaje.
		for candidate in game.enemies:
			if can_contact(candidate):
				enemy = candidate
				break
	if not can_contact(enemy):
		fail("esquivado" if not enemy.is_empty() else "sin contacto")
		return
	moves.target = enemy
	if moves.key == "u1":
		var damage: float = game.tuning.form2_dash_damage if game.form == "FORM2" else game.tuning.form1_dash_damage
		if game.perform_hit(enemy, damage, 18.0, moves.direction, 11.0, 2.5, 0.7, 0.7):
			damage_applied = damage
			last_result = "impacto"
			moves.recover(0.28)
		else: fail("bloqueado")
		return
	if not game.perform_hit(enemy, game.tuning.projection_entry_damage, 4.0, moves.direction, 0, 0, 0.18):
		fail("bloqueado")
		return
	damage_applied = game.tuning.projection_entry_damage
	last_close_variant = close_variant
	damage_hits = game.tuning.projection_close_hits if close_variant else game.tuning.projection_normal_hits
	if damage_hits.is_empty():
		last_result = "impacto"
		moves.recover(0.25)
		return
	moves.stage = "barrage"
	moves.remaining = game.tuning.barrage_interval
	phase_elapsed = 0
	sequence_elapsed = 0
	strike_index = 0
	strike_landed = false
	strike_revision += 1
	var relative: Vector3 = game.player.global_position-enemy.body.global_position
	orbit_start = atan2(relative.z, relative.x)
	enemy["sequence_hold"] = float(damage_hits.size())*float(game.tuning.barrage_interval)+0.15
	game.interrupt_enemy_attack(enemy)

func tick(delta: float) -> void:
	pose_timer -= delta
	if moves.key == "b1" and not moves.gate_nodes.is_empty() and pose_timer <= 0: refresh_pose()
	phase_elapsed += delta
	match moves.stage:
		"windup":
			steer(delta)
			if moves.remaining <= 0:
				moves.stage = "approach"
				moves.remaining = game.tuning.approach_timeout
				phase_elapsed = 0
		"approach":
			steer(delta)
			speed = move_toward(speed, float(game.tuning.maximum_speed), float(game.tuning.acceleration)*delta)
			if wall_ahead():
				fail("pared")
			elif moves.remaining <= 0 or (not moves.target.is_empty() and moves.target.body.global_position.distance_to(game.player.global_position) <= float(game.tuning.commit_distance)):
				commit()
		"commit":
			if wall_ahead(): fail("pared")
			elif moves.remaining <= 0: contact()
		"barrage":
			sequence_elapsed += delta
			if not eligible(moves.target) or not line_of_sight(moves.target) or moves.target.body.global_position.distance_to(game.player.global_position) > 3.5:
				fail("interrumpido")
				return
			var offset: Vector3 = moves.target.body.global_position-game.player.global_position
			offset.y = 0
			if offset.length() > 0.01:
				moves.direction = offset.normalized()
				game.skill_dir = moves.direction
			if not strike_landed and phase_elapsed >= float(game.tuning.strike_anticipation):
				strike_landed = true
				var final_hit := strike_index == damage_hits.size()-1
				var gain := 2.0 if close_variant else (4.0 if final_hit else 3.0)
				if game.perform_hit(moves.target, damage_hits[strike_index], gain, moves.direction, 7.0 if final_hit else 0.0, 2.0 if final_hit else 0.0, 0.3, 0.65 if final_hit else 0.0):
					damage_applied += damage_hits[strike_index]
				else:
					fail("interrumpido")
					return
				if final_hit:
					last_result = "impacto cercano" if close_variant else "impacto"
					release_hold()
					moves.recover(0.25)
					return
			if moves.remaining <= 0:
				strike_index += 1
				strike_landed = false
				phase_elapsed = 0
				moves.remaining = game.tuning.barrage_interval
				strike_revision += 1
	if moves.stage in ["windup", "approach", "commit", "barrage"]:
		game.model.rotation.y = lerp_angle(game.model.rotation.y, atan2(-moves.direction.x, -moves.direction.z), 1.0-exp(-delta*18.0))

func velocity() -> Vector3:
	if moves.stage in ["approach", "commit"]: return moves.direction*speed
	if moves.stage == "barrage" and close_variant and eligible(moves.target):
		var total: float = maxf(0.1, damage_hits.size()*game.tuning.barrage_interval)
		var angle := orbit_start+TAU*clampf(sequence_elapsed/total, 0, 1)
		var destination: Vector3 = moves.target.body.global_position+Vector3(cos(angle),0,sin(angle))*float(game.tuning.orbit_radius)
		var displacement: Vector3 = destination-game.player.global_position
		displacement.y = 0
		return (displacement*18.0).limit_length(game.tuning.orbit_speed)
	return Vector3.ZERO

func animation() -> String:
	if moves.stage == "approach": return "UnarmedRunForward"
	if moves.stage == "commit": return "UnarmedAttackR1"
	if moves.stage == "barrage":
		var names := ["UnarmedAttackL1", "UnarmedAttackR1", "UnarmedAttackL2", "UnarmedAttackR2", "UnarmedAttackR3"] if close_variant else ["UnarmedAttackL1", "UnarmedAttackR1", "UnarmedAttackR2"]
		return names[mini(strike_index, names.size()-1)]
	return "UnarmedIdleAlert1"

func release_hold() -> void:
	if not moves.target.is_empty(): moves.target["sequence_hold"] = 0.0

func cancel() -> void:
	release_hold()
	if last_result == "pendiente": last_result = "cancelado"

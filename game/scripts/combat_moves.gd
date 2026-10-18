extends Node3D
# Extensión incremental: rutas, counter, formas malditas y dominio.
var game: Node3D
var projection: Node = preload("res://scripts/guided_projection.gd").new()
var cooldowns := {"b1": 0.0, "b2": 0.0, "u1": 0.0, "u2": 0.0, "u3": 0.0, "u4": 0.0}
var key := ""
var stage := ""
var remaining := 0.0
var elapsed := 0.0
var direction := Vector3.FORWARD
var previous_position := Vector3.ZERO
var target: Dictionary = {}
var hit_ids: Array[int] = []
var gates: Array[Vector3] = []
var gate_nodes: Array[Node3D] = []
var gate_index := 0
var barrage_hits := 0
var effects: Array[Dictionary] = []
var phase_charge := 0.0
var domain_time := 0.0
var domain_center := Vector3(200, 0, 0)
var domain_arena: Node3D
var domain_exterior: Node3D
var domain_saved_player := Vector3.ZERO
var domain_targets: Array[Dictionary] = []
var curse: Node3D
var segments: Array[Node3D] = []
var feelers: Array[Node3D] = []
var evolution_parts: Array[Node3D] = []
var camera_pulse := 0.0
var player_freeze := 0.0
var player_frame: Node3D
var player_frame_offset := Vector3.ZERO
const CYAN := Color("66e7fa")
const GOLD := Color("f4cb75")
const VIOLET := Color("a58cff")

func setup(owner_game: Node3D) -> void:
	game = owner_game
	add_child(projection)
	projection.setup(game,self)
	build_curse()

func sphere(parent: Node3D, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radial_segments = 16
	mesh.rings = 8
	node.mesh = mesh
	node.material_override = game.get_box_material(color)
	parent.add_child(node)
	node.position = position
	node.scale = size
	return node

func ring(parent: Node3D, position: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = maxf(0.01, radius - 0.025)
	mesh.outer_radius = radius + 0.025
	mesh.rings = 64
	mesh.ring_segments = 8
	node.mesh = mesh
	node.material_override = game.get_glow_material(color)
	parent.add_child(node)
	node.position = position
	return node

func frame(position: Vector3, color: Color, life: float = 0.0) -> Node3D:
	var node: Node3D = preload("res://scripts/projection_frame.gd").new()
	add_child(node)
	node.setup(color)
	node.global_position = position + Vector3.UP * 1.15
	node.rotation.y = atan2(-direction.x, -direction.z)
	if life > 0:
		effects.append({"node": node, "life": life, "total": life, "grow": false})
	return node

func pulse(position: Vector3, color: Color, radius: float = 0.6) -> void:
	if effects.size() >= 80:
		return
	var node := Node3D.new()
	add_child(node)
	node.global_position = position + Vector3.UP * 0.08
	ring(node, Vector3.ZERO, radius, color)
	effects.append({"node": node, "life": 0.32, "total": 0.32, "grow": true})
	camera_pulse = maxf(camera_pulse, 0.12)

func streak(a: Vector3, b: Vector3, color: Color, width: float = 0.035) -> void:
	if effects.size() >= 80 or a.distance_to(b) < 0.01:
		return
	var node: MeshInstance3D = game.glow_box(self, Vector3(width, width, a.distance_to(b)), (a + b) * 0.5, color)
	node.look_at(b)
	effects.append({"node": node, "life": 0.18, "total": 0.18, "grow": false})

func build_curse() -> void:
	curse = Node3D.new()
	game.player.add_child(curse)
	for i in range(8):
		var segment := Node3D.new()
		curse.add_child(segment)
		segment.position = Vector3(0, 0.9, float(i) * 0.26)
		sphere(segment, Vector3.ZERO, Vector3(0.8 - i * 0.055, 0.57 - i * 0.035, 0.7 - i * 0.035), Color("807082"))
		ring(segment, Vector3.ZERO, maxf(0.12, 0.38 - i * 0.022), GOLD).rotation.x = PI / 2
		segments.append(segment)
	var head := sphere(curse, Vector3(0, 1.03, -0.39), Vector3(0.78, 0.68, 0.8), Color("ded2b9"))
	for side in [-1, 1]:
		sphere(head, Vector3(side * 0.23, 0.1, -0.42), Vector3(0.18, 0.08, 0.08), Color("ffac64"))
		var fin: MeshInstance3D = game.box(curse, Vector3(0.10, 0.55, 0.85), Vector3(side * 0.64, 1.05, 0.1), Color("ded2b9"))
		fin.rotation.z = side * 0.65
		evolution_parts.append(fin)
	for i in range(4):
		var pivot := Node3D.new()
		curse.add_child(pivot)
		pivot.position = Vector3((-1 if i % 2 == 0 else 1) * 0.47, 0.8 + (i / 2) * 0.16, 0.4)
		for j in range(4):
			sphere(pivot, Vector3(0, -j * 0.07, j * 0.27), Vector3(0.12, 0.12, 0.37), Color("695878"))
		feelers.append(pivot)
	curse.hide()

func form_changed() -> void:
	cancel()
	var active: bool = game.form != "BASE"
	curse.visible = active
	game.rig_holder.visible = not active and game.rig_enabled
	game.model.visible = not active and not game.rig_enabled
	phase_charge = 0.0
	for id in ["u1", "u2", "u3", "u4"]:
		cooldowns[id] = 0.0
	for part in evolution_parts:
		part.visible = game.form == "FORM2"
	for part in feelers:
		part.visible = game.form == "FORM2"
	pulse(game.player.position, VIOLET if game.form == "FORM2" else GOLD, 1.2)
	if game.form != "FORM2":
		end_domain()

func add_evolution_charge(amount: float) -> void:
	if game.form == "FORM1":
		phase_charge = minf(100.0, phase_charge + amount * 1.5)

func transform_input() -> void:
	if game.robots.active: game.fusion.request(); return
	if not game.can_start_action():
		return
	if game.ult_ready():
		game.start_form("FORM1")
	elif game.form == "FORM1" and phase_charge >= 100.0:
		game.start_form("FORM2")

func can_use(index: int) -> bool:
	if not game.can_start_action() or not game.player.is_on_floor():
		return false
	if game.form == "BASE":
		return true
	if game.form == "FORM1" and index != 1:
		return false
	if index == 4 and (game.domain_used or game.ult_time < 14.8 or domain_time > 0.0):
		return false
	return true

func press(index: int) -> void:
	if game.fusion.fused: game.fusion.combat.press(index); return
	if game.robots.active: game.robots.press(index); return
	if not can_use(index):
		return
	if game.form == "BASE" and index >= 3:
		if index == 3 and game.skill3_cd <= 0:
			game.start_skill3()
		elif index == 4 and game.skill4_cd <= 0:
			game.start_skill4()
		return
	var requested := ("b" if game.form == "BASE" else "u") + str(index)
	if float(cooldowns[requested]) > 0:
		return
	key = requested
	game.skill_active = "extra"
	game.combo = 0
	game.combo_timeout = 0.0
	direction = game.facing_forward()
	game.skill_dir = direction
	elapsed = 0.0
	target = {}
	hit_ids.clear()
	previous_position = game.player.position
	match key:
		"b1":
			cooldowns[key] = game.tuning.projection_cooldown
			projection.start()
		"b2":
			cooldowns[key] = game.tuning.counter_cooldown
			stage = "prepare"
			remaining = 0.10
			frame(game.player.position, GOLD, 0.6)
		"u1":
			cooldowns[key] = game.tuning.evolved_dash_cooldown
			projection.start()
		"u2":
			cooldowns[key] = 9.0
			stage = "prepare"
			remaining = 0.32
			pulse(game.player.position + direction * 3.0, VIOLET, 1.1)
		"u3":
			game.feedback.sound("evolved_accel",game.player.global_position,-3)
			cooldowns[key] = 12.0
			stage = "prepare"
			remaining = 0.7
			pulse(game.player.position, GOLD, 1.6)
		"u4":
			stage = "prepare"
			remaining = 0.8
			frame(game.player.position, VIOLET, 0.8)

func cancel() -> void:
	projection.cancel()
	key = ""
	stage = ""
	target = {}
	clear_gates()

func clear_gates() -> void:
	for node in gate_nodes:
		if is_instance_valid(node):
			node.queue_free()
	gate_nodes.clear()
	gates.clear()

func recover(duration: float) -> void:
	stage = "recover"
	remaining = duration
	clear_gates()

func freeze_enemy(enemy: Dictionary, duration: float) -> void:
	if is_instance_valid(enemy.get("physics")) and enemy.physics.active:
		enemy.physics.cancel(); enemy.ragdoll = false; enemy.ragdoll_time = 0.0
	var total := maxf(float(enemy.get("projection_freeze",0.0)),duration)
	clear_enemy_frame(enemy)
	enemy["projection_freeze"] = total
	game.interrupt_enemy_attack(enemy)
	enemy.body.velocity = Vector3.ZERO
	# Las inmovilizaciones cortas existentes conservan su tiempo como stun 3D;
	# únicamente la cristalización completa crea un vidrio de cinco segundos.
	if total < 4.999: return
	var photograph := frame(enemy.body.position,CYAN)
	# El frente del panel corresponde al frente del actor, no al atacante.
	photograph.look_at(photograph.global_position+enemy.body.global_basis.z,Vector3.UP)
	enemy["projection_frame"] = photograph
	photograph.capture(enemy.rig_holder if enemy.rig_enabled else enemy.visual,game)
	game.feedback.sound("glass_enter",enemy.body.position,-2)
	enemy["projection_frame_offset"] = photograph.global_position-enemy.body.global_position

func freeze_player(duration: float = 5.0) -> void:
	game.descending_time = 0.0
	if is_instance_valid(game.physical_ragdoll) and game.physical_ragdoll.active:
		game.physical_ragdoll.cancel(); game.player_ragdoll = false; game.player_ragdoll_time = 0.0
	var total := maxf(player_freeze,duration)
	clear_player_frame()
	game.presentation.cancel_emote()
	game.cancel_skill()
	game.player.velocity = Vector3.ZERO
	game.block = false
	game.attack_buffer = 0
	game.ability_buffer = 0
	game.jump_buffer = 0
	player_freeze = total
	direction = game.facing_forward()
	player_frame = frame(game.player.global_position,CYAN)
	player_frame.look_at(player_frame.global_position-game.facing_forward(),Vector3.UP)
	var visual: Node3D = game.rig_holder if game.form == "BASE" and game.rig_enabled else (game.model if game.form == "BASE" else curse)
	player_frame.capture(game.fusion.visual() if game.fusion.fused else visual,game)
	game.feedback.sound("glass_enter",game.player.global_position,-2)
	player_frame_offset = player_frame.global_position-game.player.global_position

func tick_player_freeze(delta: float) -> bool:
	if player_freeze <= 0: return false
	player_freeze = maxf(0.0,player_freeze-delta)
	game.attack_buffer = 0
	game.ability_buffer = 0
	game.jump_buffer = 0
	game.player.velocity = Vector3.ZERO
	if player_freeze <= 0:
		break_player_frame("timeout")
		return false
	if is_instance_valid(player_frame):
		player_frame.global_position = game.player.global_position+player_frame_offset
		player_frame.enforce()
	return true

func break_player_frame(reason: String = "hit") -> bool:
	if player_freeze <= 0 and not is_instance_valid(player_frame): return false
	player_freeze = 0
	var old := player_frame
	player_frame = null
	if is_instance_valid(old): return old.dissolve(reason)
	return false

func break_enemy_frame(enemy: Dictionary,reason: String = "hit") -> bool:
	if float(enemy.get("projection_freeze",0)) <= 0 and not is_instance_valid(enemy.get("projection_frame")): return false
	enemy.projection_freeze = 0.0
	var old: Node3D = enemy.get("projection_frame")
	enemy.projection_frame = null
	if enemy.rig_anim != null: enemy.rig_anim.speed_scale = 1.0
	if is_instance_valid(old): return old.dissolve(reason)
	return false

func clear_player_frame() -> void:
	player_freeze = 0
	if is_instance_valid(player_frame):
		player_frame.release()
		player_frame.queue_free()
	player_frame = null

func frozen_tick(enemy: Dictionary, delta: float) -> bool:
	var duration := float(enemy.get("projection_freeze", 0.0))
	if duration <= 0:
		return false
	enemy.projection_freeze = maxf(0.0, duration - delta)
	if is_instance_valid(enemy.get("projection_frame")):
		enemy.projection_frame.global_position = enemy.body.global_position+enemy.projection_frame_offset
		enemy.projection_frame.enforce()
	enemy.stun = maxf(0.0,float(enemy.stun)-delta)
	if float(enemy.hp) <= 0:
		if enemy.rig_anim != null:
			enemy.rig_anim.speed_scale = 1.0
		enemy.projection_freeze = 0.0
		clear_enemy_frame(enemy)
		return false
	if enemy.rig_anim != null:
		enemy.rig_anim.speed_scale = 0.0 if enemy.projection_freeze > 0 else 1.0
	enemy.label.text = "FOTOGRAMA %.1f s\n%d / 100" % [enemy.projection_freeze,int(enemy.hp)]
	if enemy.projection_freeze <= 0: break_enemy_frame(enemy,"timeout")
	return enemy.projection_freeze > 0

func clear_enemy_frame(enemy: Dictionary) -> void:
	var photograph: Node3D = enemy.get("projection_frame")
	if is_instance_valid(photograph):
		photograph.release()
		photograph.queue_free()
	enemy["projection_frame"] = null
	for i in range(effects.size()-1,-1,-1):
		if effects[i].get("follow") == enemy.body:
			if is_instance_valid(effects[i].node): effects[i].node.queue_free()
			effects.remove_at(i)

func counter(enemy: Dictionary) -> bool:
	if key != "b2" or stage != "window":
		return false
	var offset: Vector3 = enemy.body.position - game.player.position
	offset.y = 0
	if offset.length() > 2.6 or direction.dot(offset.normalized()) < 0.1 or not projection.line_of_sight(enemy):
		return false
	if not game.perform_hit(enemy, game.tuning.counter_damage, 10.0, direction, 0.0, 0.0, 0.0, 0.0, false, true): return false
	freeze_enemy(enemy, game.tuning.counter_frame_duration)
	game.presentation.comment("counter_hit")
	game.player_wakeup_protection = maxf(game.player_wakeup_protection, 0.18)
	stage = "counter_hit"
	remaining = 0.25
	pulse(enemy.body.position, GOLD)
	return true

func closest(distance: float, cone: float = 0.25) -> Dictionary:
	game.skill_dir = direction
	var enemy: Dictionary = game.find_skill_target(distance, cone)
	if not enemy.is_empty() and absf(enemy.body.position.y - game.player.position.y) > 2.0:
		return {}
	return enemy

func tick_skill(delta: float) -> void:
	elapsed += delta
	remaining -= delta
	if stage == "recover":
		if remaining <= 0:
			game.cancel_skill()
		return
	if key in ["b1","u1"]:
		projection.tick(delta)
		return
	match key:
		"b2":
			if remaining <= 0:
				if stage == "prepare":
					stage = "window"
					remaining = 0.45
				else:
					if stage == "window":
						# Falló la ventana: penaliza a Naoya, no al NPC atacante.
						game.cancel_skill()
						freeze_player(5.0)
						game.presentation.comment("counter_miss")
						return
					recover(0.35 if stage == "window" else 0.12)
		"u3":
			if stage == "rush":
				resolve_swept_hit()
				if int(elapsed * 60) % 3 == 0:
					frame(game.player.position, GOLD if key == "u1" else VIOLET, 0.14)
			if remaining <= 0:
				if stage == "prepare":
					stage = "rush"
					remaining = 0.65
					previous_position = game.player.position
				else:
					recover(0.3 if not hit_ids.is_empty() else 0.55)
		"u2":
			if stage == "hold" and not target.is_empty():
				var destination: Vector3 = game.player.position + direction * 2.0
				var motion: Vector3 = (destination - target.body.position).limit_length(12.0 * delta)
				target.body.move_and_collide(motion)
				if int(elapsed * 60) % 3 == 0:
					for side in [-1, 1]:
						streak(game.player.position + Vector3(side * 0.6, 1.0, 0), target.body.position + Vector3.UP, VIOLET, 0.09)
			if remaining <= 0:
				if stage == "prepare":
					target = closest(7.0, 0.4)
					if target.is_empty() or not game.perform_hit(target, game.tuning.tendril_entry_damage, 0.0, direction, 0.0, 0.0, 0.75):
						recover(0.4)
					else:
						freeze_enemy(target, 0.75)
						stage = "hold"
						remaining = 0.60
				else:
					if not target.is_empty() and float(target.hp) > 0:
						game.perform_hit(target, game.tuning.tendril_throw_damage, 0.0, direction, 8.0, 3.0, 0.8, 0.8)
						pulse(target.body.position, VIOLET, 0.8)
					recover(0.25)
		"u4":
			if remaining <= 0:
				begin_domain()
				recover(0.2)

func resolve_swept_hit() -> void:
	var a := Vector3(previous_position.x, 0, previous_position.z)
	var b := Vector3(game.player.position.x, 0, game.player.position.z)
	for enemy in game.enemies:
		var actor: CharacterBody3D = enemy.body
		if hit_ids.has(actor.get_instance_id()) or float(enemy.hp) <= 0:
			continue
		if absf(actor.position.y - game.player.position.y) > 2.2:
			continue
		var point := Vector3(actor.position.x, 0, actor.position.z)
		if Geometry3D.get_closest_point_to_segment(point, a, b).distance_to(point) > 1.35:
			continue
		hit_ids.append(actor.get_instance_id())
		var damage: float = game.tuning.acceleration_damage
		if game.perform_hit(enemy, damage, 22.0, direction, 14.0, 3.0, 0.9, 0.9, false, key == "u3"):
			pulse(actor.position, VIOLET if key == "u3" else GOLD, 1.0)
	previous_position = game.player.position

func skill_velocity(delta: float) -> Vector3:
	if key in ["b1","u1"]: return projection.velocity()
	if stage == "rush" and key in ["u1", "u3"]:
		var speed := 34.0 if key == "u1" else lerpf(20.0, 52.0, clampf((0.65 - remaining) / 0.65, 0, 1))
		return direction * speed
	return Vector3.ZERO

func animation() -> String:
	if key in ["b1","u1"]: return projection.animation()
	if key == "b2":
		return "UnarmedAttackR2" if stage == "counter_hit" else "UnarmedBlock"
	return "UnarmedIdleAlert1"

func tick(delta: float) -> void:
	for id in cooldowns:
		cooldowns[id] = maxf(0.0, float(cooldowns[id]) - delta)
	for i in range(effects.size() - 1, -1, -1):
		var effect: Dictionary = effects[i]
		if effect.has("follow") and is_instance_valid(effect.follow):
			effect.node.global_position = effect.follow.global_position + Vector3.UP * 1.05
		effect.life -= delta
		if effect.life <= 0:
			if effect.get("shatter",false):
				game.feedback.shatter(effect.node.global_position,CYAN)
			effect.node.queue_free()
			effects.remove_at(i)
		elif effect.grow:
			effect.node.scale = Vector3.ONE * (1.0 + (1.0 - effect.life / effect.total) * 2.0)
	camera_pulse = maxf(0, camera_pulse - delta)
	if curse.visible:
		curse.rotation.y = game.model.rotation.y
		curse.rotation.x = 0.0 if game.form == "FORM2" else (-0.12 if stage == "rush" else sin(game.attack_anim * 16.0) * 0.15)
		curse.position.y = 0.08 * sin(game.clock * 4.0)
		if game.player_ragdoll:
			curse.rotation.z = 1.3
		else:
			curse.rotation.z = lerpf(curse.rotation.z, 0.0, minf(1.0, delta * 10.0))
		for i in range(segments.size()):
			segments[i].position.x = sin(game.clock * (16.0 if stage == "rush" else 5.0) - i * 0.6) * 0.055
			segments[i].position.y = 0.9 + sin(game.clock * 5 - i * 0.5) * 0.035
		for i in range(feelers.size()):
			feelers[i].rotation = Vector3(sin(game.clock * 6 + i) * 0.15, (-0.8 if i % 2 == 0 else 0.8) + sin(game.clock * 4 + i) * 0.15, 0)
	if domain_time > 0:
		domain_time = maxf(0, domain_time - delta)
		keep_inside(game.player)
		for entry in domain_targets:
			var enemy: Dictionary = entry.enemy
			var actor: CharacterBody3D = enemy.body
			keep_inside(actor)
			entry.penalty -= delta
			var moving: bool = actor.position.distance_to(entry.last_position) > 0.025 and float(enemy.stun) <= 0 and not bool(enemy.ragdoll)
			var attacking: bool = str(enemy.attack_phase) != "idle"
			if entry.penalty <= 0 and (moving or attacking) and float(enemy.hp) > 0 and float(enemy.get("projection_freeze", 0)) <= 0:
				game.perform_hit(enemy, game.tuning.domain_tick_damage, 0, Vector3.ZERO, 0, 0, 0.12, 0, false, true)
				frame(actor.position, VIOLET, 0.15)
				entry.penalty = 0.8
			entry.last_position = actor.position
		if domain_time <= 0:
			end_domain()

func keep_inside(actor: CharacterBody3D) -> void:
	var offset := actor.position - domain_center
	offset.y = 0
	if offset.length() > 9.0:
		var point := domain_center + offset.normalized() * 9.0
		actor.position.x = point.x
		actor.position.z = point.z

func begin_domain() -> void:
	if game.domain_used or game.form != "FORM2":
		return
	game.domain_used = true
	cooldowns.u4 = 999.0
	domain_time = 14.0
	game.feedback.sound("domain_open",game.player.global_position,-3)
	domain_saved_player = game.player.position
	domain_exterior = Node3D.new()
	domain_exterior.name = "DomainExteriorBarrier"
	game.add_child(domain_exterior)
	domain_exterior.position = domain_saved_player
	var exterior := MeshInstance3D.new()
	var exterior_mesh := SphereMesh.new()
	exterior_mesh.radius = 12.0
	exterior_mesh.height = 24.0
	exterior_mesh.radial_segments = 48
	exterior_mesh.rings = 24
	exterior.mesh = exterior_mesh
	exterior.material_override = game.get_box_material(Color("171324"))
	exterior.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	domain_exterior.add_child(exterior)
	domain_arena = Node3D.new()
	domain_arena.name = "DomainInterior"
	game.add_child(domain_arena)
	domain_arena.position = domain_center
	var shell := MeshInstance3D.new()
	var shell_mesh := SphereMesh.new()
	shell_mesh.radius = 10.0
	shell_mesh.height = 20.0
	shell_mesh.radial_segments = 48
	shell_mesh.rings = 24
	shell.mesh = shell_mesh
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shell_material := StandardMaterial3D.new()
	shell_material.cull_mode = BaseMaterial3D.CULL_FRONT
	shell_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shell_material.albedo_color = Color("100e21")
	shell.material_override = shell_material
	domain_arena.add_child(shell)
	var floor_body := StaticBody3D.new()
	floor_body.name = "CircularDomainFloor"
	domain_arena.add_child(floor_body)
	var floor_visual := MeshInstance3D.new()
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 9.6
	floor_mesh.bottom_radius = 9.6
	floor_mesh.height = 1.0
	floor_mesh.radial_segments = 96
	floor_visual.mesh = floor_mesh
	floor_visual.position.y = -0.5
	floor_visual.material_override = game.get_box_material(Color("19162b"))
	floor_body.add_child(floor_visual)
	var collider := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 9.6
	shape.height = 1.0
	collider.shape = shape
	collider.position.y = -0.5
	floor_body.add_child(collider)
	var wall := StaticBody3D.new()
	wall.name = "CircularDomainBoundary"
	domain_arena.add_child(wall)
	var wall_collision := CollisionShape3D.new()
	var wall_shape := ConcavePolygonShape3D.new()
	var faces := PackedVector3Array()
	for i in range(64):
		var a := Vector3(cos(i*TAU/64),0,sin(i*TAU/64))*9.5
		var b := Vector3(cos((i+1)*TAU/64),0,sin((i+1)*TAU/64))*9.5
		faces.append_array(PackedVector3Array([a,b,b+Vector3.UP*6,a,b+Vector3.UP*6,a+Vector3.UP*6]))
	wall_shape.set_faces(faces)
	wall_shape.backface_collision = true
	wall_collision.shape = wall_shape
	wall.add_child(wall_collision)
	for radius in [3.0, 6.0, 9.3]:
		ring(domain_arena, Vector3(0, 0.035, 0), radius, VIOLET)
	for i in range(24):
		var angle := i * TAU / 24.0
		var p := Vector3(cos(angle), 0, sin(angle)) * 9.6
		game.glow_box(domain_arena, Vector3(0.035, 5.2, 0.035), p + Vector3.UP * 2.6, VIOLET)
		game.glow_box(domain_arena, Vector3(0.6, 0.05, 0.05), p + Vector3.UP * 5.2, GOLD)
	for enemy in game.enemies:
		if float(enemy.hp) <= 0 or enemy.body.position.distance_to(domain_saved_player) > 12.0:
			continue
		var original: Vector3 = enemy.body.position
		var destination: Vector3 = domain_center + (original - domain_saved_player).limit_length(8.0)
		domain_targets.append({"enemy": enemy, "original": original, "arena_position": destination, "last_position": destination, "penalty": 0.8})
		enemy.body.position = destination
		enemy.body.velocity = Vector3.ZERO
	var scenery := preload("res://scripts/domain_scenery.gd").new()
	domain_arena.add_child(scenery); scenery.setup(game)
	game.player.position = domain_center + Vector3.UP * 0.05
	game.player.velocity = Vector3.ZERO
	game.player.reset_physics_interpolation()
	for entry in domain_targets: entry.enemy.body.reset_physics_interpolation()
	game.camera_initialized = false
	game.ult_msg = "DOMINIO · MOVERSE O ATACAR ACTIVA LA PENALIZACIÓN"
	game.ult_msg_time = 3.0

func end_domain() -> void:
	if is_instance_valid(domain_arena):
		game.player.position = domain_saved_player
		game.player.velocity = Vector3.ZERO
		game.player.reset_physics_interpolation()
		game.camera_initialized = false
	for entry in domain_targets:
		entry.enemy.body.position = entry.original
		entry.enemy.body.velocity = Vector3.ZERO
		entry.enemy.body.reset_physics_interpolation()
	domain_targets.clear()
	if is_instance_valid(domain_arena): domain_arena.queue_free()
	if is_instance_valid(domain_exterior): domain_exterior.queue_free()
	domain_arena = null
	domain_exterior = null
	domain_time = 0

func enemy_reset(enemy: Dictionary) -> void:
	clear_enemy_frame(enemy)
	enemy["projection_freeze"] = 0.0
	if enemy.rig_anim != null:
		enemy.rig_anim.speed_scale = 1.0
	for entry in domain_targets:
		if entry.enemy.body == enemy.body:
			enemy.body.position = entry.arena_position
			entry.last_position = entry.arena_position

func hud_text() -> String:
	if game.form == "BASE":
		return "1 Proyecciones [%s] · 2 Counter [%s]\n3 Projection Rush [%s] · 4 Patada [%s]" % [game.cooldown_text(cooldowns.b1), game.cooldown_text(cooldowns.b2), game.cooldown_text(game.skill3_cd), game.cooldown_text(game.skill4_cd)]
	if game.form == "FORM1":
		return "1 Embestida [%s] · Evolución %d%% (G al 100%%)\nFase 2 desbloquea tentáculos, aceleración y dominio" % [game.cooldown_text(cooldowns.u1), int(phase_charge)]
	var domain_status := "USADO" if game.domain_used else ("POCO TIEMPO" if game.ult_time < 14.8 else "LISTO")
	var text := "1 Embestida [%s] · 2 Tentáculos [%s]\n3 Aceleración [%s] · 4 Dominio [%s]" % [game.cooldown_text(cooldowns.u1), game.cooldown_text(cooldowns.u2), game.cooldown_text(cooldowns.u3), domain_status]
	if domain_time > 0:
		text += " · %.1fs" % domain_time
	return text

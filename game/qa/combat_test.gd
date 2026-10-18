extends SceneTree
var game: Node3D
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("run")
func verify(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
	print(("PASS " if condition else "FAIL ") + description)
func advance(frames: int) -> void:
	for i in range(frames):
		await physics_frame
func reset() -> void:
	game.end_form()
	game.respawn_player()
	game.player.position = Vector3(0, 0.05, 5)
	game.model.rotation.y = 0
	game.hp = 100
	game.stun = 0
	game.player_wakeup_protection = 0
	game.attack_cd = 0
	game.dash_time = 0
	game.attack_anim = 0
	for id in game.moves.cooldowns:
		game.moves.cooldowns[id] = 0.0
	for enemy in game.enemies:
		game.reset_enemy(enemy)
		enemy.body.position = Vector3(30 + int(enemy.kind) * 5, 0.05, 25)
	await advance(6)
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await advance(6)
	verify(game.rig_enabled and game.enemies.size() == 3, "rig y tres NPC importados")
	await reset()
	game.moves.press(1)
	verify(game.moves.gates.size() == 2, "base1 crea dos fotogramas móviles")
	var start: Vector3 = game.player.position
	await advance(85)
	verify(game.player.position.distance_to(start) > 12, "base1 avanza automaticamente")
	verify(game.moves.gates.size() <= 2, "avance conserva como máximo dos fotogramas")
	await advance(35)
	verify(game.skill_active == "", "base1 sale de recovery")
	verify(game.moves.gates.is_empty(),"fin de proyección limpia el cuadro móvil")
	await reset()
	game.moves.press(1)
	game.player.position.x = 5
	await advance(115)
	verify(game.skill_active == "" and game.stun == 0, "sin objetivo termina sin castigo de ruta")
	verify(game.moves.gates.is_empty(), "fallo limpia cuadros")
	await reset()
	var enemy: Dictionary = game.enemies[2]
	enemy.body.position = game.player.position + Vector3(0, 0, -1.8)
	game.moves.press(2)
	await advance(8)
	var hp: float = game.hp
	game.hit_player_from_enemy(enemy, Vector3.BACK)
	verify(game.hp == hp, "counter evita golpe en ventana")
	verify(float(enemy.hp) == 92 and float(enemy.get("projection_freeze", 0)) > 0, "counter inflige8 y congela")
	await advance(310)
	verify(enemy.rig_anim.speed_scale == 1, "animacion recuperada tras congelacion")
	await reset()
	game.moves.press(2)
	await advance(42)
	enemy.body.position = game.player.position + Vector3(0, 0, -1.8)
	game.hit_player_from_enemy(enemy, Vector3.BACK)
	verify(game.hp < 100, "counter tardio recibe dano")
	await reset()
	game.charge = 100
	game.moves.transform_input()
	await advance(130)
	verify(game.form == "FORM1" and game.moves.curse.visible and not game.rig_holder.visible, "G transforma gusano 60s")
	game.add_charge(20)
	verify(game.moves.phase_charge == 30, "carga evolucion multiplica1.5")
	game.moves.press(2)
	verify(game.skill_active == "", "fase1 bloquea movimientos evolucionados")
	enemy = game.enemies[0]
	enemy.body.position = game.player.position + Vector3(0, 0, -5)
	game.moves.press(1)
	await advance(65)
	verify(float(enemy.hp) == 82, "embestida fase1 aplica18 una sola vez")
	verify(game.moves.phase_charge >= 57, "impacto carga evolucion")
	game.moves.phase_charge = 100
	game.moves.transform_input()
	await advance(130)
	verify(game.form == "FORM2" and game.ult_time > 44 and game.ult_time <= 45, "G evoluciona y renueva45s")
	await reset()
	game.charge = 100
	game.on_player_death()
	verify(game.form == "FORM1" and game.hp == 60 and game.moves.phase_charge == 0, "renacimiento fase1 con60HP y evolucion cero")
	await reset()
	game.start_form("FORM2", true)
	await advance(130)
	enemy = game.enemies[0]
	enemy.body.position = game.player.position + Vector3(0, 0, -5)
	game.moves.press(2)
	await advance(78)
	verify(float(enemy.hp) == 82, "tentaculos golpe6+12")
	verify(game.skill_active == "", "tentaculos finalizan sin bloqueo de estado")
	await reset()
	game.start_form("FORM2", true)
	await advance(130)
	enemy = game.enemies[1]
	enemy.body.position = game.player.position + Vector3(0, 0, -8)
	game.moves.press(3)
	await advance(110)
	verify(float(enemy.hp) == 74, "aceleracion atraviesa guardia y aplica26 una vez")
	await reset()
	game.start_form("FORM2", true)
	await advance(130)
	var origin: Vector3 = game.player.position
	var npc_origin := Vector3(4, 0.05, 1)
	game.enemies[0].body.position = npc_origin
	game.enemies[2].body.position = Vector3(6, 0.05, 1)
	game.moves.press(4)
	await advance(55)
	verify(game.moves.domain_time > 13 and game.domain_used, "dominio se activa14s una vez")
	verify(game.player.position.x > 190, "dominio teletransporta a arena separada")
	await advance(150)
	verify(float(game.enemies[0].hp) == 100, "dominio no dana al inmovil")
	verify(float(game.enemies[2].hp) < 100, "dominio penaliza movimiento atacante")
	await advance(710)
	verify(game.moves.domain_time == 0 and game.player.position.distance_to(origin) < 0.2, "dominio devuelve jugador al terminar14s")
	verify(game.enemies[0].body.position.distance_to(npc_origin) < 0.2, "dominio devuelve NPC")
	game.moves.press(4)
	verify(game.skill_active == "", "dominio usado no se repite")
	await reset()
	game.start_form("FORM2", true)
	await advance(130)
	game.moves.begin_domain()
	game.on_player_death()
	verify(game.moves.domain_targets.is_empty() and game.form == "BASE" and not game.moves.curse.visible, "morir restaura arena y forma humana")
	await reset()
	game.start_form("FORM2", true)
	await advance(130)
	game.moves.press(3)
	game.ult_time = 0.02
	await advance(6)
	verify(game.form == "BASE" and game.skill_active == "", "expiracion cancela habilidad y restaura humano")
	await reset()
	enemy = game.enemies[0]
	enemy.body.position = Vector3(0, 0.05, -10)
	game.moves.press(1)
	await advance(140)
	verify(float(enemy.hp) == 82, "proyecciones conecta rafaga18 con colision real")
	await reset()
	game.moves.press(2)
	await advance(8)
	enemy = game.enemies[2]
	enemy.body.position = game.player.position + Vector3(0, 0, 1.8)
	game.hit_player_from_enemy(enemy, Vector3.FORWARD)
	verify(game.hp < 100, "counter no cubre espalda")
	await reset()
	game.start_form("FORM2", true)
	await advance(130)
	game.moves.press(4)
	enemy.body.position = game.player.position + Vector3(0, 0, -1.8)
	game.hit_player_from_enemy(enemy, Vector3.BACK)
	await advance(60)
	verify(game.moves.domain_time == 0 and not game.domain_used, "ataque interrumpe preparacion dominio")
	await reset()
	game.start_form("FORM2", true)
	await advance(130)
	game.ult_time = 10
	game.moves.press(4)
	verify(game.skill_active == "", "dominio exige tiempo para14s completos")
	await reset()
	game.moves.press(1)
	game.charge = 100
	game.moves.transform_input()
	await advance(130)
	verify(game.form == "BASE", "G no cancela gratuitamente habilidad activa")
	game.cancel_skill()
	game.moves.transform_input()
	await advance(130)
	verify(game.form == "FORM1", "G funciona al estar libre")
	await reset()
	game.start_form("FORM2", true)
	await advance(130)
	game.moves.begin_domain()
	game.end_form()
	game.start_form("FORM2", true)
	await advance(130)
	verify(not game.domain_used and game.moves.cooldowns.u4 == 0, "nueva transformacion recupera dominio")
	print("RESULT %d/%d OK" % [checks - failures, checks])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

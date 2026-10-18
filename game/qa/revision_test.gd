extends SceneTree
# Integración: ejecuta física, estados y contactos del proyecto, sin imágenes sintéticas.
var game: Node3D
var checks := 0
var failures := 0
var walls: Array[Node3D] = []

func _initialize() -> void: call_deferred("run")

func verify(ok: bool, name: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+name)

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func reset() -> void:
	for action in ["left","right","forward","back","attack","block"]: Input.action_release(action)
	for wall in walls: wall.queue_free()
	walls.clear()
	game.reset_lab()
	game.preferences.values.hold_attack = false
	game.player_wakeup_protection = 0
	game.yaw = 0
	game.model.rotation = Vector3.ZERO
	for i in range(game.enemies.size()):
		var enemy: Dictionary = game.enemies[i]
		enemy.kind = 0
		enemy.body.position = Vector3(35+i*4,0.05,25)
	await frames(6)

func place(index: int, offset: Vector3, mode: int = 0) -> Dictionary:
	var enemy: Dictionary = game.enemies[index]
	enemy.kind = mode
	enemy.body.position = game.player.position+offset
	enemy.body.velocity = Vector3.ZERO
	return enemy

func wall(position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	game.add_child(body)
	body.position = position
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	walls.append(body)

func until_stage(name: String, limit: int = 130) -> bool:
	for i in range(limit):
		if game.moves.stage == name: return true
		await frames(1)
	return false

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await reset()
	var centered := place(0,Vector3(0,0,-10))
	place(1,Vector3(2,0,-4))
	place(2,Vector3(0,0,3))
	await frames(2)
	var selected: Dictionary = game.moves.projection.select_target()
	verify(not selected.is_empty() and selected.body == centered.body,"selección prioriza centro de cámara sobre enemigo lateral más cercano")
	verify(not game.camera_lock,"autoapuntado no requiere fijación manual")
	centered.hp = 0
	game.enemies[1].ragdoll = true
	verify(game.moves.projection.select_target().is_empty(),"selección descarta muertos, derribados y objetivos detrás de cámara")
	await reset()
	var enemy := place(0,Vector3(0,0,-19))
	verify(game.moves.projection.select_target().is_empty(),"alcance de selección limitado a18m")
	enemy.body.position = game.player.position+Vector3(8,0,-2)
	verify(game.moves.projection.select_target().is_empty(),"cono de cámara descarta objetivo fuera de50 grados")
	await reset()
	enemy = place(0,Vector3(0,0,-8))
	wall(game.player.position+Vector3(0,1.5,-4),Vector3(4,3,0.7))
	await frames(3)
	verify(game.moves.projection.select_target().is_empty(),"pared bloquea selección por línea de visión")
	game.moves.press(1)
	await frames(110)
	verify(enemy.hp == 100 and game.moves.projection.last_result == "pared","habilidad no atraviesa pared ni daña al objetivo oculto")
	verify(game.player.position.z > 1.0,"cuerpo mantiene colisión contra la pared")
	await reset()
	place(0,Vector3(0,0,-8))
	var visible := place(1,Vector3(6,0,-8))
	wall(game.player.position+Vector3(0,1.5,-4),Vector3(4,3,0.7))
	await frames(3)
	selected = game.moves.projection.select_target()
	verify(not selected.is_empty() and selected.body == visible.body,"selección elige rival visible cuando el central está tras pared")
	await reset()
	game.moves.press(1)
	await frames(15)
	var speed1: float = game.moves.projection.speed
	var initial_direction: Vector3 = game.moves.direction
	game.yaw = 0.55
	await frames(14)
	verify(game.moves.projection.speed > speed1,"velocidad aumenta progresivamente durante aproximación")
	verify(game.moves.direction.angle_to(initial_direction) > 0.08,"sin objetivo la cámara puede dirigir la trayectoria")
	await frames(110)
	verify(game.skill_active == "" and game.stun == 0,"sin objetivo recupera el control sin castigo artificial")
	await reset()
	enemy = place(0,Vector3(1.0,0,-11))
	game.moves.press(1)
	await frames(12)
	game.start_enemy_dash(enemy,Vector3.RIGHT)
	await frames(8)
	verify(game.moves.direction.x > 0.08,"seguimiento actualiza posición y velocidad de objetivo que se desplaza")
	var before_camera: Vector3 = game.moves.direction
	game.yaw = -0.45
	await frames(1)
	verify(game.moves.direction.angle_to(before_camera) <= game.tuning.turn_rate/60.0+0.002,"giro está limitado por velocidad angular")
	await reset()
	enemy = place(0,Vector3(0,0,-12))
	game.moves.press(1)
	await frames(12)
	game.yaw = 0.6
	await frames(10)
	verify(game.moves.direction.x < -0.03 and game.moves.target.body == enemy.body,"cámara influye en trayectoria manteniendo objetivo durante aproximación")
	await reset()
	enemy = place(0,Vector3(0,0,-6))
	game.moves.press(1)
	verify(await until_stage("commit"),"aproximación entra en ventana de compromiso")
	var committed: Vector3 = game.moves.direction
	game.yaw = 1.6
	await frames(2)
	verify(game.moves.direction.is_equal_approx(committed),"cámara deja de corregir el rumbo durante compromiso")
	verify(game.start_enemy_dash(enemy,Vector3.RIGHT),"dash real del enemigo se inicia antes del contacto")
	await frames(50)
	verify(enemy.hp == 100 and game.moves.projection.last_result == "esquivado","dash final evita el impacto por posición e hitbox")
	verify(float(enemy.get("sequence_hold",0)) == 0 and game.skill_active == "","esquiva no activa agarre ni ráfaga y recupera control")
	await reset()
	enemy = place(0,Vector3(0,0,-6))
	game.moves.press(1)
	await frames(125)
	verify(enemy.hp == 82 and is_equal_approx(game.moves.projection.damage_applied,18.0),"contacto normal aplica18 en impactos separados sin duplicación")
	verify(game.charge == 14 and game.skill_active == "","ráfaga normal carga14 y devuelve control")
	await reset()
	enemy = place(0,Vector3(0,0,-1.8))
	game.moves.press(1)
	verify(await until_stage("barrage"),"variante cercana necesita contacto real antes de inmovilizar")
	var orbit_origin: Vector3 = game.player.position
	var max_side := 0.0
	for i in range(55):
		await frames(1)
		max_side = maxf(max_side,absf(game.player.position.x-orbit_origin.x))
	verify(max_side > 0.35,"variante cercana produce recorrido lateral físico alrededor del rival")
	verify(enemy.hp == 82 and game.moves.projection.last_close_variant,"variante cercana limita daño total a18 igual que la normal")
	verify(enemy.sequence_hold == 0 and game.skill_active == "","final cercano libera inmovilización y control")
	await reset()
	enemy = place(0,Vector3(0,0,-1.8))
	game.moves.press(1)
	verify(await until_stage("commit"),"variante cercana conserva compromiso previo")
	game.start_enemy_dash(enemy,Vector3.RIGHT)
	await frames(75)
	verify(enemy.hp == 100 and not game.moves.projection.last_close_variant,"dash al aproximarse impide activar gratis la secuencia cercana")
	await reset()
	enemy = place(0,Vector3(0,0,-1.8))
	game.moves.press(1)
	await until_stage("barrage")
	game.cancel_skill()
	verify(enemy.sequence_hold == 0,"interrumpir habilidad libera al objetivo sin dejar bloqueos")
	await reset()
	enemy = place(0,Vector3(0,0,-1.8))
	wall(game.player.position+Vector3(1.5,1.5,-1.8),Vector3(0.5,3,4))
	await frames(3)
	game.moves.press(1)
	var max_x := 0.0
	for i in range(125):
		await frames(1)
		max_x = maxf(max_x,game.player.position.x)
	verify(max_x < 0.91,"órbita utiliza colisiones y no atraviesa el muro lateral")
	verify(enemy.sequence_hold == 0 and game.skill_active == "","órbita obstruida termina y libera estados")
	await reset()
	enemy = place(0,Vector3(0,0,-6),1)
	game.moves.press(1)
	await frames(120)
	verify(enemy.hp == 100 and enemy.sequence_hold == 0 and game.moves.projection.last_result == "bloqueado","bloqueo frontal evita contacto inicial y secuencia gratuita")
	await reset()
	enemy = place(0,Vector3(0,0,-10))
	game.moves.press(1)
	await frames(12)
	enemy.hp = 0
	place(1,Vector3(0,0,-5))
	await frames(3)
	verify(game.moves.projection.target_lost and game.moves.target.is_empty(),"perder objetivo no adquiere instantáneamente un reemplazo")
	await reset()
	enemy = place(0,Vector3(0,0,-1.8))
	game.moves.press(2)
	await frames(8)
	game.hit_player_from_enemy(enemy,Vector3.BACK)
	verify(enemy.projection_freeze == 5.0 and enemy.hp == 92,"Counter activa exactamente5s de frame y8 de daño")
	await frames(298)
	verify(enemy.projection_freeze > 0 and enemy.rig_anim.speed_scale == 0,"frame sigue activo hasta el final de los5s")
	await frames(4)
	verify(enemy.projection_freeze == 0 and enemy.rig_anim.speed_scale == 1,"frame termina y restaura animación después de5s")
	await reset()
	enemy = place(0,Vector3(0,0,-1.8))
	game.perform_hit(enemy,1,0,Vector3.FORWARD,0,0,0.1,0.5)
	game.punch()
	await frames(15)
	verify(enemy.hp == 99,"M1 real no daña enemigo derribado")
	await frames(18)
	game.punch()
	await frames(10)
	verify(enemy.hp == 99 and enemy.wakeup_protection > 0,"M1 respeta ventana de recuperación del derribo")
	await frames(30)
	game.punch()
	await frames(15)
	verify(enemy.hp < 99,"protección al levantarse termina y permite golpes posteriores")
	await reset()
	enemy = place(0,Vector3(0,0,-1.8))
	for i in range(4):
		game.punch()
		await frames(24)
	verify(enemy.hp == 77 and game.attack_variant == "normal" and enemy.ragdoll,"combo M1 conserva cuatro golpes y remate normal con23 de daño")
	await reset()
	enemy = place(0,Vector3(0,0,-1.8))
	game.jump_buffer = 0.12
	await frames(4)
	game.combo = 3
	game.combo_timeout = 1
	game.punch()
	await frames(15)
	verify(game.attack_variant == "uppercut" and enemy.hp == 91 and enemy.ragdoll,"cuarto M1 al subir conserva uppercut y derribo")
	await reset()
	enemy = place(0,Vector3(0,0,-1.8))
	game.jump_buffer = 0.12
	await frames(32)
	game.combo = 3
	game.combo_timeout = 1
	game.punch()
	await frames(15)
	verify(game.attack_variant == "downslam" and enemy.hp == 90 and enemy.slam_pending,"cuarto M1 al caer conserva downslam y contacto real")
	await reset()
	game.charge = 100
	game.on_player_death()
	verify(game.form == "FORM1" and game.hp == 60 and game.charge == 0 and game.moves.phase_charge == 0,"muerte con ultimate renace fase1 y consume energía")
	await frames(130)
	game.moves.transform_input()
	verify(game.form == "FORM1","G no evoluciona sin completar barra propia de fase1")
	game.moves.phase_charge = 100
	game.moves.transform_input()
	verify(game.form == "FORM2","evolución exige fase1 y100 de su barra")
	game.on_player_death()
	verify(game.form == "BASE" and game.hp == 100,"morir transformado vuelve aBASE sin regalar otra fase")
	await reset()
	game.start_form("FORM2")
	verify(game.form == "BASE","progresión normal rechaza salto directo aFORM2")
	game.start_form("FORM2",true)
	verify(game.form == "FORM2","laboratorio prepara fase2 de forma explícita")
	await frames(130)
	enemy = place(0,Vector3(0,0,-6),4)
	game.moves.press(1)
	verify(game.skill_active == "extra" and game.moves.key == "u1","habilidad evolucionada se activa después de terminar transición")
	await until_stage("commit")
	await frames(4)
	verify(enemy.dash_time > 0,"dummy inicia dash real durante compromiso de habilidad evolucionada")
	await frames(100)
	verify(enemy.hp == 100 and game.moves.projection.last_result == "esquivado","habilidad1 evolucionada también admite esquiva final")
	await reset()
	game.start_form("FORM2",true)
	await frames(130)
	enemy = place(0,Vector3(0,0,-6))
	game.moves.press(1)
	await frames(120)
	verify(enemy.hp == 78 and game.moves.projection.damage_applied == 22,"habilidad1 evolucionada aplica22 una sola vez cuando conecta")
	await reset()
	enemy = place(0,Vector3(0,0,-7),3)
	var station: Vector3 = enemy.body.position
	await frames(60)
	verify(enemy.body.position.distance_to(station) < 0.05,"atacante estacionario no persigue")
	enemy.body.position = game.player.position+Vector3(0,0,-1.8)
	enemy.cd = 0
	await frames(30)
	verify(game.hp < 100,"atacante estacionario sí golpea cuando está a alcance")
	await reset()
	enemy = place(0,Vector3(0,0,-7),2)
	var distance: float = enemy.body.position.distance_to(game.player.position)
	await frames(30)
	verify(enemy.body.position.distance_to(game.player.position) < distance-1.0,"perseguidor mantiene comportamiento de acercarse")
	await reset()
	enemy = place(0,Vector3(0,0,-6),4)
	game.moves.press(1)
	await frames(120)
	verify(enemy.hp == 100 and absf(enemy.body.position.x) > 1.0,"dummy evasor usa dash en compromiso y evita daño")
	game.interface.open_menu("test")
	var selectors: Array[OptionButton] = []
	for row in game.interface.menu_content.get_children():
		for child in row.get_children():
			if child is OptionButton: selectors.append(child)
	verify(selectors.size() == 3,"laboratorio ofrece selector independiente para cada dummy")
	if selectors.size() == 3:
		selectors[0].item_selected.emit(3)
		selectors[1].item_selected.emit(4)
		selectors[2].item_selected.emit(0)
		verify(game.enemies[0].kind == 3 and game.enemies[1].kind == 4 and game.enemies[2].kind == 0,"selectores cambian el dummy correspondiente sin mezclar referencias")
	game.set_paused(false)
	await reset()
	enemy = place(0,Vector3(0,0,-1.8))
	game.start_dash()
	game.hit_player_from_enemy(enemy,Vector3.BACK)
	verify(game.hp == 94,"dash conserva defensa posicional sin inventar invulnerabilidad permanente")
	game.moves.freeze_enemy(enemy,5)
	game.reset_lab()
	verify(enemy.projection_freeze == 0 and enemy.sequence_hold == 0 and enemy.rig_anim.speed_scale == 1,"reinicio limpia freeze, agarre y animación")
	print("RESULT %d/%d OK" % [checks-failures,checks])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)

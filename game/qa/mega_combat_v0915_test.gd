extends SceneTree
var game: Node3D
var checks := 0
var passed := 0
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func check(ok: bool,title: String) -> void:
	checks += 1
	if ok: passed += 1
	print("PASS " if ok else "FAIL ",title)
func target(offset: Vector3 = Vector3(0,0,-3)) -> Dictionary:
	game.fusion.combat.interrupted(); game.fusion.combat.m1_cooldown = 0
	game.fusion.combat.cooldowns = [0.0,0.0,0.0,0.0]
	game.fusion.boost_time = 0; game.dash_time = 0; game.dash_cd = 0; game.stun = 0; game.block = false
	game.player.global_position = Vector3(0,.2,0); game.player.velocity = Vector3.ZERO
	game.model.rotation.y = 0; game.yaw = 0; game.camera_lock = true
	game.fusion.sequence.global_position = game.player.global_position; game.fusion.sequence.rotation.y = 0
	var enemy: Dictionary = game.enemies[0]
	for e in game.enemies:
		e.physics.cancel(); e.ragdoll = false; e.ragdoll_time = 0; e.wakeup_protection = 0; e.projection_freeze = 0
		e.stun = 0; e.hp = 100.0; e.kind = 0; e.body.velocity = Vector3.ZERO
		e.body.position = Vector3(40+game.enemies.find(e)*5,.2,40)
	enemy.body.position = game.player.position+offset; enemy.body.rotation.y = PI
	return enemy
func run() -> void:
	game = preload("res://main.tscn").instantiate(); root.add_child(game); await frames(10)
	for enemy in game.enemies: game.set_dummy_mode(enemy,0)
	game.robots.forced = 1; game.robots.select(1); game.player.position = Vector3(0,.2,0); await frames(8)
	game.charge = 100; check(game.fusion.request(),"G usa la fusión existente")
	game.fusion.sequence.advance(11.5); await frames(4)
	var combat: Node3D = game.fusion.combat
	var rig: Node3D = game.fusion.sequence.articulation
	check(game.fusion.fused and rig.pieces.size() == 22,"22 piezas originales ensambladas")
	check(rig.shoulder_covers.size() == 2 and rig.shoulder_covers[0].get_parent() == rig.pivots.BrazoSuperior_Der,"sellos de hombros ligados a la articulación")
	var torso_before: Quaternion = rig.pivots.Torso_Pecho.quaternion
	for i in range(120): rig.locomotion(1.0/60,0,true,0,0,true)
	check(torso_before.angle_to(rig.pivots.Torso_Pecho.quaternion) > .005,"torso tiene respiración y balanceo en idle")
	var shape: CapsuleShape3D = game.robots.naoya.collision.shape
	check(shape.height == 4 and is_equal_approx(shape.radius,1.05),"colisión de desplazamiento del mega conserva cuatro metros")
	check(game.fusion.hurt_area.get_child(0).shape.size == Vector3(3,4,1.5),"receptor de daño mide 3 por 4 por 1,5 m según la malla")
	check(game.fusion.hurt_area.collision_layer == 4 and not game.fusion.hurt_area.monitoring,"receptor dedicado no empuja personajes ni el escenario")
	game.interface.tick(.1)
	for i in range(4):
		check(not game.interface.cards[i].panel.unavailable and game.interface.cards[i].panel.tooltip_text.contains("Desventaja") and game.interface.cards[i].panel.tooltip_text.contains("s de recarga"),"habilidad descrita y desbloqueada "+str(i+1))
	var enemy := target(Vector3(0,0,-3.6)); await frames(4)
	game.punch(); await frames(20)
	check(enemy.hp == 100,"M1 respeta su preparación; no golpea al pulsar")
	await frames(21)
	check(enemy.hp < 100 and enemy.ragdoll,"primer M1 golpea suelo y derriba desde el primer contacto")
	var fist_bounds: AABB = rig.pieces.Mano_Der.global_transform*rig.pieces.Mano_Der.get_aabb()
	check(fist_bounds.position.y < .45 and fist_bounds.position.y > -.15 and absf(rig.sole_height("Izq")) < .02,"puño llega al suelo con pies plantados y uniones cerradas")
	check(combat.m1_cooldown > 0,"M1 pesado conserva recuperación")
	enemy = target(Vector3(2.4,0,0)); await frames(4)
	game.punch(); await frames(18)
	check(rig.sole_height("Der")-rig.sole_height("Izq") > .025,"pisotón levanta el pie derecho manteniendo apoyo izquierdo")
	await frames(27)
	check(enemy.hp < 100 and enemy.ragdoll,"segundo M1 alterna pisotón con área lateral más grande")
	enemy = target(); await frames(4); game.punch(); await frames(8)
	var hp_before: float = game.hp
	game.fusion.receive_enemy(enemy,Vector3.BACK)
	check(game.hp < hp_before and game.stun == 0 and not combat.current.is_empty(),"golpe normal hace daño sin interrumpir el M1 del mega")
	check(game.fusion.protected_m1(false) and not game.fusion.protected_m1(true),"armadura discrimina atacante normal de otro mega")
	combat.interrupted(); await frames(2)
	check(combat.current.is_empty(),"interrupción autorizada limpia el ataque y la pose")
	for slot in [2,3,4]:
		enemy = target(Vector3(0,0,-3 if slot == 2 else (-4.2 if slot == 3 else -4.8))); await frames(4)
		check(combat.press(slot),"activa habilidad "+str(slot))
		check(not combat.press(slot) and not combat.punch(),"no permite activación duplicada ni M1 simultáneo "+str(slot))
		await frames(90)
		check(enemy.hp < 100 and enemy.ragdoll,"habilidad "+str(slot)+" aplica daño y derribo reales")
		check(combat.cooldowns[slot-1] > 0,"recarga independiente "+str(slot))
	# Proyectil barrido por la física, sin resolver daño directamente desde el test.
	enemy = target(Vector3(0,0,-7)); await frames(4)
	check(combat.press(1),"cañón inicia carga")
	await frames(40); check(enemy.hp == 100,"cañón no hace daño antes del disparo")
	await frames(45)
	if enemy.hp == 100: print("DIAG canon mano ",rig.pivots.Mano_Der.global_position," punta ",combat.barrel_tip.global_position," objetivo ",enemy.body.global_position," proyectiles ",combat.projectiles)
	check(enemy.hp < 100 and enemy.ragdoll,"cañón físico alcanza a siete metros y derriba")
	check(combat.projectiles.is_empty(),"proyectil desaparece después de colisionar")
	# Una pared real intercepta el cañón y protege al objetivo detrás.
	enemy = target(Vector3(0,0,-8)); await frames(4)
	var wall := StaticBody3D.new(); var col := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3(12,8,.5)
	col.shape = box; wall.add_child(col); game.add_child(wall); wall.position = Vector3(0,4,-3.6); await frames(3)
	combat.press(1); await frames(95)
	check(enemy.hp == 100 and combat.projectiles.is_empty(),"cañón choca con paredes sin dañar a través de ellas")
	wall.queue_free(); await frames(3)
	enemy = target(Vector3(0,0,-3.8)); await frames(4)
	wall = StaticBody3D.new(); col = CollisionShape3D.new(); box = BoxShape3D.new(); box.size = Vector3(10,6,.25)
	col.shape = box; wall.add_child(col); game.add_child(wall); wall.position = Vector3(0,3,-1.7); await frames(3)
	combat.press(2); await frames(80)
	check(enemy.hp == 100,"martillazo no coloca el impacto al otro lado de una pared")
	wall.queue_free(); await frames(3)
	enemy = target(Vector3(0,3,-3)); await frames(4)
	enemy.body.position.y = 3.2; enemy.body.velocity = Vector3.ZERO
	combat.press(3); combat.elapsed = .7; combat.ground_attack()
	check(enemy.hp == 100,"pisotón no alcanza objetivos por encima del área de suelo")
	combat.interrupted(); await frames(4)
	# Bloqueo de mira al estar quieto y propulsión con entrada real al controlador.
	target(); await frames(4); game.yaw = PI/2; game.camera_lock = true; await frames(25)
	check(game.facing_forward().dot(Vector3.LEFT) > .98,"bloqueo de mira orienta al mega aun estando quieto")
	var start: Vector3 = game.player.position
	game.start_dash(); await frames(12)
	check(game.player.position.y > start.y+.6 and game.player.position.x < start.x-.8,"Q impulsa hacia arriba y hacia delante diagonalmente")
	check(not game.fusion.start_boost(),"propulsión impide doble activación en el aire")
	await frames(80)
	check(game.player.is_on_floor() and game.dash_time == 0 and game.dash_cd > 0,"propulsión aterriza con colisiones y recarga")
	check(game.skill_vfx.dust.crowns_emitted > 0 and game.fusion.sequence.dust.crowns_emitted > 0,"coronas de humo en despegue y ensamblaje final")
	check(game.skill_vfx.effects.size() <= game.skill_vfx.MAX_EFFECTS and game.skill_vfx.dust.particle_count() <= 440,"efectos y partículas tienen presupuesto finito")
	game.interface.open_menu("character"); await frames(3)
	check(game.interface.menu_depth.viewport.own_world_3d and game.interface.menu_depth.rig.get_child_count() > 5,"menú tiene geometría 3D independiente")
	game.set_paused(false)
	game.fusion.reset(); game.interface.tick(.1)
	check(not game.fusion.busy() and combat.projectiles.is_empty() and game.max_hp == 100,"reinicio limpia cañón, proyectiles, colisiones y estadísticas")
	game.feedback.stop_all(); game.queue_free()
	var until := Time.get_ticks_msec()+250
	while Time.get_ticks_msec() < until: await process_frame
	print("RESULTADO ",passed,"/",checks); quit.call_deferred(0 if passed == checks else 1)

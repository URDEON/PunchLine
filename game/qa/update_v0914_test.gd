extends SceneTree
var checks := 0
var passed := 0
var game: Node3D
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func check(ok: bool, title: String) -> void:
	checks += 1; if ok: passed += 1
	print("PASS " if ok else "FAIL ",title)
func target(blocking: bool = false, close: bool = true) -> Dictionary:
	game.robots.cancel(); game.cancel_skill(); game.attack_cd = 0; game.attack_anim = 0; game.combo = 0; game.combo_timeout = 0
	game.stun = 0; game.wakeup_anim = 0; game.player_ragdoll = false; game.charge = 0
	game.player.position = Vector3(0,.2,4); game.player.velocity = Vector3.ZERO; game.model.rotation.y = 0
	var enemy: Dictionary = game.enemies[0]
	enemy.body.position = Vector3(0,.2,2 if close else -12); enemy.body.rotation.y = PI
	enemy.body.velocity = Vector3.ZERO
	enemy.hp = 100.0; enemy.stun = 0.0; enemy.ragdoll = false; enemy.ragdoll_time = 0.0
	enemy.wakeup_protection = 0; enemy.projection_freeze = 0; enemy.kind = 1 if blocking else 0
	for i in range(1,game.enemies.size()): game.enemies[i].body.position = Vector3(40+i*5,.2,40)
	return enemy
func run() -> void:
	game = preload("res://main.tscn").instantiate(); root.add_child(game); await frames(10)
	for enemy in game.enemies: game.set_dummy_mode(enemy,0)
	game.robots.forced = 0; game.robots.select(1); await frames(4)
	for variant in range(4):
		game.robots.forced = variant; game.respawn_player(); await frames(3)
		var enemy := target()
		game.robots.punch(); game.robots.elapsed = float(game.robots.attack.duration)*.55; game.robots.resolve_contact()
		check(game.charge == game.M1_CHARGE and enemy.hp < 100,"M1 carga Ultimate en "+game.robots.NAMES[variant])
		enemy = target(true)
		game.robots.punch(); game.robots.elapsed = float(game.robots.attack.duration)*.55; game.robots.resolve_contact()
		check(game.charge == 0 and enemy.hp == 100,"guardia no da energía en "+game.robots.NAMES[variant])
		enemy = target(false,false)
		game.robots.punch(); game.robots.elapsed = float(game.robots.attack.duration)*.55; game.robots.resolve_contact()
		check(game.charge == 0,"fallo no da energía en "+game.robots.NAMES[variant])
		game.interface.tick(.1)
		check(game.interface.identity.holographic and game.interface.cards[0].panel.holographic,"HUD holográfico en "+game.robots.NAMES[variant])
	game.robots.cancel(); game.attack_anim = 0; game.attack_cd = 0; game.charge = 0
	game.charge = 42; game.respawn_player(); await frames(3)
	check(game.charge == 42,"carga compartida se conserva al reaparecer con otro chasis")
	game.charge = 0
	game.player.position = Vector3(0,.2,0); await frames(8)
	check(not game.fusion.request(),"G requiere Ultimate completa")
	game.charge = 100; game.interface.tick(.1)
	check(game.interface.identity.holo_energy.value == 100,"barra y medidor muestran energía lista")
	check(game.fusion.request() and game.charge == 0,"G consume la carga al iniciar")
	game.fusion.sequence.advance(11.5)
	check(game.fusion.fused and game.max_hp == 300 and game.hp == 300,"forma definitiva aumenta vida máxima a 300")
	check(game.fusion.HEAVY_SPEED < game.SPEED*.4 and game.fusion.FUSED_HEIGHT == 4,"unidad pesada lenta y altura de cuatro metros")
	var rig: Node3D = game.fusion.sequence.articulation
	check(rig != null and rig.pivots.size() == 22,"veintidós piezas enlazadas por articulaciones reales")
	check(absf(rig.pivots.BrazoSuperior_Der.rotation.z) > 1,"activación baja brazos y elimina T-pose")
	var model_forward: Vector3 = game.fusion.visual().global_basis.z.normalized()
	check(model_forward.dot(game.facing_forward()) > .999,"frente del GLB coincide con dirección de combate")
	var thigh_before: Quaternion = rig.pivots.Muslo_Der.quaternion
	for i in range(30): rig.locomotion(1.0/60,2.2,true,0,.035,true)
	check(thigh_before.angle_to(rig.pivots.Muslo_Der.quaternion) > .03,"marcha mueve muslos y rodillas")
	check(absf(rig.pivots.Rodilla_Der.rotation.x)+absf(rig.pivots.Rodilla_Izq.rotation.x) > .1,"rodillas articuladas durante locomoción")
	var steps_before: int = game.fusion.step_index
	for i in range(30): rig.locomotion(1.0/60,0,true,0,0)
	check(game.fusion.step_index == steps_before,"reposo no emite pasos")
	for i in range(30): rig.locomotion(1.0/60,2.2,false,-3,.04)
	check(game.fusion.step_index == steps_before and rig.state == "fall","caída no emite pasos y cambia pose")
	for i in range(20): rig.locomotion(1.0/60,0,true,0,0)
	check(rig.state in ["idle","land"],"aterrizaje transiciona a control normal")
	check(game.fusion.sequence._rings.is_empty(),"sin aros provisionales de ensamblaje")
	for jet in game.fusion.sequence._jets:
		check(jet.throttle == 0 and jet.flames.size() == 2,"chorro animado se apaga tras el vuelo")
	var dust: Node3D = game.fusion.sequence.dust
	check(dust.bursts.size() <= dust.MAX_BURSTS,"polvo acotado por presupuesto de efectos")
	var soft_materials := true
	for emitter in dust.find_children("*","CPUParticles3D",true,false): soft_materials = soft_materials and emitter.mesh.material is ShaderMaterial
	check(soft_materials,"polvo suave procedural compatible con Compatibility")
	var enemy := target()
	enemy.body.position = game.player.position+Vector3(0,0,-3.7)
	await frames(3)
	game.punch(); await frames(46)
	if enemy.hp == 100:
		var ray := PhysicsRayQueryParameters3D.create(game.player.global_position+Vector3.UP*1.8,enemy.body.global_position+Vector3.UP,1)
		print("DIAG M1 ",game.player.position," -> ",enemy.body.position," facing ",game.facing_forward()," hit ",game.get_world_3d().direct_space_state.intersect_ray(ray)," contact ",game.fusion.heavy_contact)
	check(enemy.hp < 100,"M1 pesado alcanza a 3.7 m con contacto real")
	check(game.fusion.heavy_attack_cd > 0,"M1 pesado tiene recuperación lenta")
	await frames(35)
	Input.action_press("block"); await frames(3)
	var before_hp: float = game.hp
	game.fusion.receive_enemy(enemy,Vector3.BACK)
	check(game.block and game.hp == before_hp,"guardia frontal de la forma definitiva")
	Input.action_release("block"); await frames(3)
	game.fusion.receive_enemy(enemy,Vector3.BACK)
	check(game.hp < before_hp,"forma definitiva recibe daño válido al soltar guardia")
	game.hp = 150; game.fusion.reset()
	check(game.max_hp == 100 and is_equal_approx(game.hp,50),"salir de fusión conserva porcentaje de vida sin curación gratis")
	game.robots.select(0); game.interface.tick(.1)
	check(not game.interface.identity.holographic and not game.interface.cards[0].panel.holographic,"Naoya recupera su HUD original")
	check(game.max_hp == 100,"reaparición y cambio de personaje restauran estadísticas")
	game.feedback.stop_all(); game.queue_free()
	var drain_until := Time.get_ticks_msec()+200
	while Time.get_ticks_msec() < drain_until: await process_frame
	print("RESULTADO ",passed,"/",checks); quit.call_deferred(0 if passed == checks else 1)

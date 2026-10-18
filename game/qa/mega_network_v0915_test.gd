extends SceneTree
var arena: Node3D
var checks := 0
var passed := 0
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func check(ok: bool,title: String) -> void:
	checks += 1
	if ok: passed += 1
	print("PASS " if ok else "FAIL ",title)
func park(actor: Node3D,point: Vector3,yaw: float = 0) -> void:
	actor.physical_ragdoll.cancel(); actor.player_ragdoll = false; actor.player_ragdoll_time = 0
	actor.stun = 0; actor.spawn_protection = 0; actor.player_wakeup_protection = 0
	actor.hp = actor.max_hp; actor.block = false; actor.attack_cd = 0; actor.attack_anim = 0
	actor.combo = 0; actor.combo_timeout = 0; actor.attack_buffer = 0; actor.ability_buffer = 0
	actor.player.position = point; actor.player.velocity = Vector3.ZERO; actor.model.rotation.y = yaw
	actor.camera_lock = false
	actor.input_state = {"axis":Vector2.ZERO,"yaw":yaw,"flags":0,"seq":actor.input_state.seq,"time":actor.clock}
	actor.fusion.combat.interrupted(); actor.fusion.combat.m1_cooldown = 0; actor.fusion.combat.cooldowns = [0.0,0.0,0.0,0.0]
func run() -> void:
	arena = preload("res://network/online.tscn").instantiate(); root.add_child(arena)
	arena.session.active = true; arena.session.server = true
	for i in range(3):
		arena.session.upsert_player(i+1,{"id":i+1,"nickname":"QA"+str(i+1),"character":1 if i < 2 else 0,"variant":i,"color":0,"slot":i,"generation":0,"spawn":Vector3(i*15,.25,0),"yaw":0.0})
	await frames(10)
	var pilot: Node3D = arena.session.actors[1]; var rival: Node3D = arena.session.actors[2]; var normal: Node3D = arena.session.actors[3]
	for actor in [pilot,rival]:
		actor.charge = 100
		check(actor.fusion.request(),"fusión disponible en actor "+str(actor.peer_id))
		actor.fusion.sequence.advance(11.5)
	await frames(4)
	park(pilot,Vector3(0,.1,0)); park(rival,Vector3(20,.1,0)); park(normal,Vector3(0,.1,-1.9),PI)
	pilot.fusion.combat.punch(); normal.queue_action("attack"); await frames(18)
	check(pilot.hp < 300,"M1 normal resta vida al mega")
	check(not pilot.fusion.combat.current.is_empty() and pilot.stun == 0,"M1 normal no cancela M1 protegido del mega")
	await frames(65)
	park(pilot,Vector3(0,.1,0)); park(normal,Vector3(0,3.0,-1.9),PI)
	normal.queue_action("attack"); await frames(18)
	check(pilot.hp < 300,"golpe elevado alcanza torso/cabeza del volumen de cuatro metros")
	park(normal,Vector3(30,.1,0)); park(pilot,Vector3(0,.1,0)); park(rival,Vector3(0,.1,-3.8),PI)
	rival.fusion.combat.m1_next_stomp = false; rival.queue_action("attack"); await frames(15)
	pilot.queue_action("attack"); await frames(23)
	check(pilot.hp < 300 and pilot.stun > 0,"M1 de otro mega causa daño y aturdimiento")
	check(pilot.fusion.combat.current.is_empty(),"otro mega sí interrumpe el M1 protegido")
	park(pilot,Vector3(0,.1,0)); park(rival,Vector3(18,.1,0)); park(normal,Vector3(0,.1,-7))
	pilot.camera_lock = true; pilot.pitch = -.24; pilot.input_state.yaw = 0; pilot.input_state.time = pilot.clock
	await frames(8) # El fixture viene de un derribo; esperar contacto real con el suelo.
	pilot.queue_action("ability1"); await frames(62)
	var snapshot: Dictionary = pilot.make_snapshot()
	check(snapshot.full.fusion.combat.cooldowns[0] > 15,"snapshot contiene recarga autoritativa del cañón")
	check(snapshot.full.fusion.combat.id == "cannon" and snapshot.full.fusion.combat.aim is Vector3,"snapshot contiene pose de disparo y punto de mira")
	await frames(22)
	check(normal.hp < 100 and normal.player_ragdoll,"cañón usa daño y ragdoll del controlador online")
	park(pilot,Vector3(0,.1,0)); park(normal,Vector3(20,.1,15)); await frames(5)
	arena.session.apply_input(1,int(pilot.input_state.seq)+1,Vector2.ZERO,PI/2,0,-.5)
	check(is_equal_approx(pilot.pitch,-.5),"inclinación de mira llega a autoridad")
	var old_sequence: int = pilot.input_state.seq
	arena.session.apply_input(1,old_sequence+1,Vector2.ZERO,0,0,NAN)
	check(int(pilot.input_state.seq) == old_sequence,"entrada con pitch no finito se rechaza")
	pilot.camera_lock = true; pilot.dash_cd = 0; pilot.queue_action("dash"); await frames(8)
	check(pilot.player.position.y > .5 and pilot.player.position.x < -.5,"dash online usa propulsión diagonal de la forma final")
	var data: Dictionary = pilot.fusion.state()
	check(data.boost > 0 and data.dash_cd > 0 and data.combat.cooldowns.size() == 4,"snapshot incluye vuelo y las cuatro recargas")
	# Aplicación real a un controlador réplica en otro World3D, sin simular daño dos veces.
	var viewport := SubViewport.new(); viewport.own_world_3d = true; root.add_child(viewport)
	var remote: Node3D = preload("res://network/online.tscn").instantiate(); viewport.add_child(remote)
	remote.session.active = true; remote.session.server = false
	remote.session.upsert_player(1,pilot.metadata); await frames(3)
	var copy: Node3D = remote.session.actors[1]
	copy.accept_snapshot(1,pilot.make_snapshot()); copy.interpolate_state(.05)
	check(copy.fusion.fused and copy.fusion.boost_time > 0,"réplica aplica fusión y vuelo recibido")
	check(copy.fusion.combat.cooldowns.size() == 4 and copy.fusion.sequence.articulation.shoulder_covers.size() == 2,"réplica tiene habilidades y hombros corregidos")
	check(not copy.physical_ragdoll.active,"réplica no inicia una segunda simulación física")
	remote.session.leave(); viewport.queue_free()
	arena.session.leave(); arena.queue_free()
	var until := Time.get_ticks_msec()+250
	while Time.get_ticks_msec() < until: await process_frame
	print("RESULTADO ",passed,"/",checks); quit.call_deferred(0 if passed == checks else 1)

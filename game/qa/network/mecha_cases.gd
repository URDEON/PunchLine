extends "res://qa/network/cases.gd"

@rpc("authority","call_remote","reliable")
func mecha_inspect(tag: String) -> void:
	var actors: Array[Dictionary] = []
	for actor in arena.session.actors.values():
		var fusion: Node3D = actor.fusion
		actors.append({"id":actor.peer_id,"charge":actor.charge,"hp":actor.hp,"max_hp":actor.max_hp,"cinematic":fusion.cinematic,"fused":fusion.fused,"position":actor.player.position,"gait":fusion.sequence.articulation.phase if fusion.sequence != null and fusion.sequence.articulation != null else -1.0,"pieces":fusion.sequence._pieces.size() if fusion.sequence != null else 0,"roster":fusion.sequence.original_names if fusion.sequence != null else [],"holo":actor.interface.identity.holographic,"shake":fusion.shake_strength,"generation":actor.metadata.generation})
	var local_actor: Node3D = arena.session.actors.get(arena.session.local_id())
	var sound_count := 0
	if local_actor != null:
		for other in arena.session.actors.values():
			for event in other.feedback.audio_events:
				if String(event.id).begins_with("mecha_step"): sound_count += 1
	observation.rpc_id(1,tag,{"actors":actors,"sounds":sound_count,"local_shake":local_actor.fusion.shake_strength if local_actor != null else 0})

func ask_mecha(id: int, tag: String) -> Dictionary:
	mecha_inspect.rpc_id(id,tag)
	var key := tag+str(id); var until := Time.get_ticks_msec()/1000.0+5
	while not reports.has(key) and Time.get_ticks_msec()/1000.0 < until: await pause(.02)
	return reports.get(key,{})

func found_actor(report: Dictionary,id: int) -> Dictionary:
	for actor in report.get("actors",[]):
		if int(actor.id) == id: return actor
	return {}

func run_host() -> void:
	check(await wait_players(3),"tres procesos conectados por ENet real")
	if arena.session.actors.size() != 3: finish_mechas(); return
	var deadline := Time.get_ticks_msec()+90000
	while arena.session.ready_peers.size()<2 and Time.get_ticks_msec()<deadline: await pause(.05)
	check(arena.session.ready_peers.size()==2,"ambos invitados terminan de cargar sus modelos")
	if arena.session.ready_peers.size()!=2:finish_mechas();return
	var ids: Array = arena.session.actors.keys(); ids.sort()
	var near_id := int(ids[1]); var far_id := int(ids[2])
	for id in [near_id,far_id]:
		var initial: Dictionary = await query(id,"initial")
		check(initial.get("actors",[]).size() == 3,"invitado termina carga inicial de tres actores "+str(id))
	arena.session.respawn(1,1)
	deadline=Time.get_ticks_msec()+60000
	while arena.session.ready_peers.size()<2 and Time.get_ticks_msec()<deadline: await pause(.05)
	check(arena.session.ready_peers.size()==2,"cambio a robot termina en ambos invitados")
	fixture(ids); await pause(.3)
	var pilot: Node3D = arena.session.actors[1]
	arena.session.actors[near_id].player.position = pilot.player.position+Vector3(0,0,-2.0)
	arena.session.local_action("attack"); await pause(.9)
	if pilot.charge <= 0: print("DIAG M1 chassis ",pilot.robots.index," range ",pilot.robots.REACH[pilot.robots.index]," enemy ",arena.session.actors[near_id].player.position-pilot.player.position," attack ",pilot.robots.attack)
	check(pilot.charge > 0,"robot gana Ultimate por M1 resuelto en anfitrión")
	var report := await ask_mecha(near_id,"energy")
	for attempt in range(8):
		if float(found_actor(report,1).get("charge",0)) == pilot.charge: break
		await pause(.2); report = await ask_mecha(near_id,"energy_retry"+str(attempt))
	if float(found_actor(report,1).get("charge",0)) != pilot.charge: print("DIAG energy ",pilot.charge," ",report)
	check(pilot.charge > 0 and float(found_actor(report,1).get("charge",0)) == pilot.charge,"energía se replica al invitado")
	var charge_before: float = pilot.charge
	fixture(ids); await pause(.2)
	arena.session.actors[near_id].player.position = pilot.player.position+Vector3(0,0,-2.0)
	var blocks_before: int = arena.session.telemetry.blocked
	drive.rpc_id(near_id,Vector2.ZERO,PI,1,60)
	for attempt in range(30):
		if arena.session.actors[near_id].block: break
		await pause(.03)
	pilot.attack_cd = 0; arena.session.local_action("attack"); await pause(.8)
	if pilot.charge != charge_before: print("DIAG block ",charge_before," -> ",pilot.charge," targetblock ",arena.session.actors[near_id].block," facing ",arena.session.actors[near_id].facing_forward())
	check(pilot.charge == charge_before and arena.session.telemetry.blocked > blocks_before,"golpe bloqueado no añade Ultimate por red")
	drive.rpc_id(near_id,Vector2.ZERO,0,0,0)
	pilot.player.position = Vector3(0,.25,0); pilot.player.velocity = Vector3.ZERO
	arena.session.actors[near_id].player.position = Vector3(7,.25,0)
	arena.session.actors[far_id].player.position = Vector3(-7,.25,0)
	pilot.stun = 0; pilot.robots.cancel(); pilot.attack_anim = 0; pilot.charge = 100; pilot.hp = 50
	await pause(.3); arena.session.local_action("transform"); await pause(.35)
	check(pilot.fusion.cinematic and pilot.charge == 0,"G autoritativa consume 100 de energía")
	for id in [near_id,far_id]:
		report = await ask_mecha(id,"cinema")
		var actor := found_actor(report,1)
		check(bool(actor.get("cinematic",false)) and actor.get("roster",[]).size() == 4,"invitado recibe fusión y cuatro chasis únicos "+str(id))
	await pause(11.8)
	check(pilot.fusion.fused and pilot.max_hp == 300 and is_equal_approx(pilot.hp,150),"forma final activa 300 HP sin curación gratis")
	for id in [near_id,far_id]:
		report = await ask_mecha(id,"fused")
		var actor := found_actor(report,1)
		check(bool(actor.get("fused",false)) and int(actor.get("pieces",0)) == pilot.fusion.sequence._pieces.size() and float(actor.get("max_hp",0)) == 300,"invitado recibe forma, piezas y vida máxima "+str(id))
	qa_axis = Vector2(0,-1); qa_yaw = 0; await pause(1.7); qa_axis = Vector2.ZERO
	check(pilot.fusion.step_index > 0,"contactos de pies generan pasos durante desplazamiento real")
	report = await ask_mecha(near_id,"walking")
	var remote := found_actor(report,1)
	check(float(remote.get("gait",-1)) > 0,"ciclo articulado se replica por snapshots")
	check(int(report.get("sounds",0)) > 0,"audio de pasos llega al otro proceso")
	# Deceleration and the last two foot plants finish before testing idle.
	# The measured local stop trace settles within 1.5 s, rather than 0.9 s.
	await pause(1.8); var stable_steps: int = pilot.fusion.step_index; await pause(.6)
	check(pilot.player.velocity.length()<.05 and pilot.fusion.step_index == stable_steps,"tras completar apoyos cesan los pasos por red")
	var position: Vector3 = pilot.player.position
	arena.session.actors[near_id].player.position = position+Vector3.RIGHT*2
	arena.session.actors[far_id].player.position = position+Vector3.RIGHT*8
	qa_axis = Vector2(0,-1)
	var near_shook := false; var far_shook := false
	for sample in range(7):
		await pause(.12)
		var near_report := await ask_mecha(near_id,"near"+str(sample))
		var far_report := await ask_mecha(far_id,"far"+str(sample))
		near_shook = near_shook or float(near_report.get("local_shake",0)) > 0
		far_shook = far_shook or float(far_report.get("local_shake",0)) > 0
	qa_axis = Vector2.ZERO
	check(near_shook and not far_shook,"sacudida llega al jugador cercano y excluye al distante")
	pilot.fusion.reset(); await pause(.4)
	for id in [near_id,far_id]:
		report = await ask_mecha(id,"reset")
		check(not bool(found_actor(report,1).get("fused",true)) and float(found_actor(report,1).get("max_hp",0)) == 100,"salir restaura estadísticas en invitado "+str(id))
	finish_mechas()

func finish_mechas() -> void:
	var passed := 0
	for result in checks:
		if result.ok: passed += 1
	arena.session.leave("QA mechas terminada")
	var file := FileAccess.open(directory.path_join("finished.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"total":checks.size(),"checks":checks},"  ")); file.close()
	print("RESULTADO ",passed,"/",checks.size())
	await pause(.4); finish(0 if passed == checks.size() else 1)

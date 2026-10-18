extends Node
# Prueba con tres procesos reales ENet. Las posiciones iniciales son fixtures;
# acciones, colisiones, contactos, daño y posturas utilizan el código de producción.
var arena: Node3D
var role := "host"
var directory := ""
var port := 17877
var checks: Array[Dictionary] = []
var reports: Dictionary = {}
var qa_axis := Vector2.ZERO
var qa_yaw := 0.0
var qa_flags := 0
var drive_until := 0.0
var input_timer := 0.0
var drive_remaining := 0.0
var drive_ack := ""
var command_counter := 0
var started := 0.0
var ended := false

func _ready() -> void:
	role = OS.get_environment("NAOYA_NET_ROLE"); directory = OS.get_environment("NAOYA_NET_OUTPUT")
	port = int(OS.get_environment("NAOYA_NET_PORT"))
	started = Time.get_ticks_msec()/1000.0
	arena = preload("res://network/online.tscn").instantiate(); add_child(arena)
	# Contact/movement fixtures require a flat, obstacle-free test arena.
	# The actual Ruined City geometry/spawns have their separate map_v0924 suite.
	for body in arena.map.find_children("*","StaticBody3D",true,false): body.collision_layer=0
	arena.map.hide()
	var floor_body:=StaticBody3D.new();floor_body.collision_layer=1;arena.add_child(floor_body)
	floor_body.position=Vector3(0,-.1,0)
	var floor_shape:=CollisionShape3D.new();var floor_box:=BoxShape3D.new();floor_box.size=Vector3(2000,.2,2000)
	floor_shape.shape=floor_box;floor_body.add_child(floor_shape)
	if not OS.get_environment("NAOYA_NET_CAPTURE").is_empty(): await RenderingServer.frame_post_draw
	await get_tree().create_timer(.3).timeout
	if role == "host":
		check(arena.session.host_game("Anfitrión",0,port) == OK,"host crea ENet")
		run_host()
	else:
		if role == "bad":
			multiplayer.connected_to_server.disconnect(arena.session.connected)
			multiplayer.connected_to_server.connect(func() -> void:
				arena.session.active = true; arena.session.hello.rpc_id(1,"version-incompatible","incompatible",0))
		var error: Error = arena.session.join_game("127.0.0.1",port,role,1 if role == "client1" else 0)
		print("JOIN ",role," ",error)
		arena.session.message.connect(func(value: String) -> void: print("MESSAGE ",role," ",value))

func check(ok: bool, title: String) -> void:
	checks.append({"ok":ok,"title":title}); print("PASS " if ok else "FAIL ",title)

func pause(seconds: float) -> void: await get_tree().create_timer(seconds).timeout

func wait_players(count: int, seconds: float = 45.0) -> bool:
	var until := Time.get_ticks_msec()/1000.0+seconds
	while arena.session.actors.size() != count and Time.get_ticks_msec()/1000.0 < until: await pause(.05)
	return arena.session.actors.size() == count

func fixture(ids: Array) -> void:
	for index in range(ids.size()):
		var actor: Node3D = arena.session.actors[ids[index]]
		actor.physical_ragdoll.cancel(); actor.player_ragdoll = false; actor.player_ragdoll_time = 0
		actor.hp = 100; actor.spawn_protection = 0; actor.stun = 0; actor.attack_cd = 0; actor.attack_anim = 0
		actor.attack_hit_done = true; actor.dash_cd = 0; actor.dash_time = 0; actor.combo = 0; actor.combo_timeout = 0
		actor.robots.cancel()
		actor.block = false; actor.action_queue.clear(); actor.player.velocity = Vector3.ZERO
		actor.player.position = [Vector3(0,.25,4),Vector3(0,.25,2),Vector3(6,.25,4)][index]
		actor.model.rotation.y = 0 if index == 0 else PI
		actor.input_state = {"axis":Vector2.ZERO,"yaw":actor.model.rotation.y,"flags":0,"seq":actor.input_state.seq,"time":actor.clock}
		if int(ids[index]) != 1: drive.rpc_id(int(ids[index]),Vector2.ZERO,actor.model.rotation.y,0,0)
	qa_axis = Vector2.ZERO; qa_yaw = 0; qa_flags = 0

@rpc("authority","call_remote","reliable")
func drive(axis: Vector2, view_yaw: float, flags: int, seconds: float, token: String = "") -> void:
	qa_axis = axis; qa_yaw = view_yaw; qa_flags = flags; drive_until = Time.get_ticks_msec()/1000.0+seconds
	drive_remaining = seconds; drive_ack = token
	arena.menu_open = false
	if seconds <= 0: drive_until = Time.get_ticks_msec()/1000.0+60

@rpc("authority","call_remote","reliable")
func action(value: String, token: String = "") -> void:
	arena.session.local_action(value)
	if not token.is_empty(): observation.rpc_id(1,token,{"accepted":true})

@rpc("authority","call_remote","reliable")
func choose(value: int, token: String = "") -> void:
	arena.session.local_character(value)
	if not token.is_empty(): observation.rpc_id(1,token,{"accepted":true})

@rpc("authority","call_remote","reliable")
func inspect(tag: String) -> void:
	if tag == "initial" and not OS.get_environment("NAOYA_NET_CAPTURE").is_empty(): await RenderingServer.frame_post_draw
	var actors: Array[Dictionary] = []
	for actor in arena.session.actors.values():
		var finite := true
		for index in range(actor.skeleton.get_bone_count()):
			finite = finite and actor.skeleton.get_bone_pose_position(index).is_finite() and actor.skeleton.get_bone_pose_rotation(index).is_finite()
		actors.append({"id":actor.peer_id,"hp":actor.hp,"generation":actor.metadata.generation,"kind":actor.model_kind,"variant":actor.robot_index,"position":actor.player.position,"snapshot_position":actor.states[-1].position if not actor.states.is_empty() else Vector3.ZERO,"snapshot_velocity":actor.states[-1].velocity if not actor.states.is_empty() else Vector3.ZERO,"snapshot_sequence":actor.last_snapshot,"pose":actor.streamed_pose,"physics":actor.physical_ragdoll.active,"bones":actor.skeleton.get_bone_count(),"finite":finite})
	observation.rpc_id(1,tag,{"id":arena.session.local_id(),"actors":actors,"snapshots":arena.session.telemetry.snapshots,"hud":arena.hud.text,"events":arena.session.telemetry.events,"menu":arena.menu_open})

@rpc("any_peer","call_remote","reliable")
func observation(tag: String, payload: Dictionary) -> void:
	if role == "host": reports[tag+str(multiplayer.get_remote_sender_id())] = payload

func query(id: int, tag: String) -> Dictionary:
	inspect.rpc_id(id,tag)
	var key := tag+str(id); var until := Time.get_ticks_msec()/1000.0+(45 if tag == "initial" else 3)
	while not reports.has(key) and Time.get_ticks_msec()/1000.0 < until: await pause(.02)
	return reports.get(key,{})

@rpc("authority","call_remote","reliable")
func photo(tag: String) -> void:
	if OS.get_environment("NAOYA_NET_CAPTURE").is_empty(): return
	var old_menu: bool = arena.menu_open; arena.menu_open = false; arena.refresh_ui(); arena.set_process(false)
	arena.camera.position = Vector3(8,5,11); arena.camera.look_at(Vector3(1,1,1))
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(tag+".png"))
	print("PHOTO ",tag," players=",arena.session.actors.size()," snapshots=",arena.session.telemetry.snapshots)
	arena.set_process(true); arena.menu_open = old_menu; arena.refresh_ui()

@rpc("authority","call_remote","reliable")
func disconnect_client() -> void: arena.session.leave("QA salida voluntaria")

@rpc("authority","call_remote","reliable")
func reconnect_client() -> void: arena.session.join_game("127.0.0.1",port,role,0)

func _physics_process(delta: float) -> void:
	if arena == null or not arena.session.active or not arena.session.actors.has(arena.session.local_id()): return
	input_timer += delta
	if not drive_ack.is_empty():
		drive_remaining -= delta
		if drive_remaining <= 0:
			qa_axis = Vector2.ZERO; qa_flags = 0
			observation.rpc_id(1,drive_ack,{"accepted":true}); drive_ack = ""
	if input_timer >= 1.0/30:
		input_timer = fmod(input_timer,1.0/30)
		var now := Time.get_ticks_msec()/1000.0
		if now > drive_until and role != "host" and drive_ack.is_empty(): qa_axis = Vector2.ZERO; qa_flags = 0
		arena.session.local_input(qa_axis,qa_yaw,qa_flags)

func _process(_delta: float) -> void:
	if ended: return
	if role == "client2" and not rejoined and FileAccess.file_exists(directory.path_join("rejoin")) and not arena.session.active:
		rejoined = true; arena.session.join_game("127.0.0.1",port,role,0)
	if Time.get_ticks_msec()/1000.0-started > 220:
		print("FAIL timeout ",role); finish(1)
	if role != "host" and FileAccess.file_exists(directory.path_join("finished.json")): finish(0)

func acknowledged(id: int, token: String) -> bool:
	var key := token+str(id); var until := Time.get_ticks_msec()/1000.0+40
	while not reports.has(key) and Time.get_ticks_msec()/1000.0 < until: await pause(.02)
	return reports.has(key)

func client_action(id: int, value: String) -> void:
	command_counter += 1; var token := "action"+str(command_counter)
	action.rpc_id(id,value,token); check(await acknowledged(id,token),"cliente ejecuta "+value)

func client_choose(id: int, value: int) -> void:
	command_counter += 1; var token := "choose"+str(command_counter)
	choose.rpc_id(id,value,token); check(await acknowledged(id,token),"cliente ejecuta selector")

func run_host() -> void:
	check(await wait_players(3),"se conectan dos clientes reales")
	if arena.session.actors.size() != 3: finish(1); return
	var ready_deadline := Time.get_ticks_msec()+90000
	while arena.session.ready_peers.size()<2 and Time.get_ticks_msec()<ready_deadline: await pause(.05)
	check(arena.session.ready_peers.size()==2,"ambos clientes confirman carga del roster completo")
	if arena.session.ready_peers.size()!=2:finish(1);return
	await pause(.6)
	# UDP connection order is nondeterministic. Rejoin is performed by client2,
	# therefore fixture roles must follow nicknames, not dictionary insertion order.
	var ids: Array = [1]
	for label in ["client1","client2"]:
		for id in arena.session.roster:
			if arena.session.roster[id].nickname==label:ids.append(id)
	var first := int(ids[1]); var second := int(ids[2])
	for id in [first,second]:
		var report: Dictionary = await query(id,"initial")
		check(report.get("actors",[]).size() == 3,"cliente %d recibe tres personajes" % id)
		check(int(report.get("id",0)) == id and int(report.get("snapshots",0)) > 0,"cliente tiene identidad y snapshots propios")
	check(arena.session.actors[1].skeleton != arena.session.actors[first].skeleton,"rigs y estados independientes")
	fixture(ids); await pause(.3)
	photo.rpc_id(second,"01_tres_jugadores")
	var host_origin: Vector3 = arena.session.actors[1].player.position
	var first_origin: Vector3 = arena.session.actors[first].player.position
	var second_origin: Vector3 = arena.session.actors[second].player.position
	drive.rpc_id(first,Vector2(0,-1),0,0,.8,"forward"); drive.rpc_id(second,Vector2(1,0),0,0,.8,"right")
	check(await acknowledged(first,"forward") and await acknowledged(second,"right"),"ambos clientes completan entrada enviada")
	await pause(.15)
	print("MOVEMENT ",first_origin," -> ",arena.session.actors[first].player.position," input=",arena.session.actors[first].input_state)
	print("MOVEMENT ",second_origin," -> ",arena.session.actors[second].player.position," input=",arena.session.actors[second].input_state)
	check(arena.session.actors[first].player.position.z < first_origin.z-2,"entrada de cliente mueve su personaje hacia delante")
	check(arena.session.actors[second].player.position.x > second_origin.x+2,"segundo cliente se mueve de forma independiente")
	check(arena.session.actors[1].player.position.distance_to(host_origin) < .1,"clientes no desplazan al anfitrión")
	drive.rpc_id(first,Vector2.ZERO,0,0,1); drive.rpc_id(second,Vector2.ZERO,0,0,1)
	await pause(.5)
	var replica: Dictionary = await query(first,"movement")
	var position_match := false
	for spec in replica.get("actors",[]):
		if int(spec.id) == second:
			print("REPLICA ",spec," server=",arena.session.actors[second].player.position," sequence=",arena.session.snapshot_sequence)
			position_match = spec.position.distance_to(arena.session.actors[second].player.position) < .4
	check(position_match,"movimiento ajeno visible en la réplica del cliente")
	fixture(ids); await pause(.3)
	var origin: Vector3 = arena.session.actors[second].player.position
	drive.rpc_id(second,Vector2(1,0),0,2,.65,"walk"); check(await acknowledged(second,"walk"),"cliente completa caminata"); await pause(.15)
	var distance: float = arena.session.actors[second].player.position.distance_to(origin)
	print("WALK distance=",distance)
	check(distance > 1 and distance < 2,"Ctrl aplica velocidad de caminar validada por host")
	fixture(ids); await pause(.3)
	await client_action(second,"jump"); await pause(.22)
	check(arena.session.actors[second].player.position.y > .8,"salto real usa colisiones y gravedad")
	await pause(.9); check(arena.session.actors[second].grounded,"aterrizaje real vuelve a suelo")
	fixture(ids); await pause(.3)
	await client_action(second,"dash"); await pause(.06)
	check(arena.session.actors[second].dash_time > 0 and arena.session.actors[second].dash_cd > 1,"Q inicia dash en el servidor")
	await client_action(second,"dash"); await pause(.3)
	check(arena.session.actors[second].dash_time <= 0 and arena.session.actors[second].dash_cd < 1.1,"dash repetido no ignora cooldown")
	fixture(ids); await pause(.3)
	arena.session.local_action("attack"); await pause(.23)
	check(arena.session.actors[first].hp == 95,"M1 del anfitrión causa daño por contacto real")
	check(arena.session.actors[second].hp == 100,"M1 no daña a otro jugador fuera de alcance")
	var damage_report: Dictionary = await query(first,"damage")
	var damage_match := false
	for spec in damage_report.get("actors",[]):
		if int(spec.id) == first: damage_match = float(spec.hp) == 95
	check(damage_match,"vida dañada se replica al cliente correcto")
	fixture(ids); await pause(.3)
	await client_action(first,"attack")
	var hit_deadline := Time.get_ticks_msec()/1000.0+2
	while arena.session.actors[1].hp == 100 and Time.get_ticks_msec()/1000.0 < hit_deadline: await pause(.02)
	check(arena.session.actors[1].hp < 100 and arena.session.actors[first].hp == 100,"M1 enviado por cliente lo valida el anfitrión")
	fixture(ids); await pause(.3)
	drive.rpc_id(first,Vector2.ZERO,PI,1,1.0); await pause(.12)
	arena.session.local_action("attack"); await pause(.25)
	check(arena.session.actors[first].hp == 100 and arena.session.telemetry.blocked > 0,"F bloquea golpe frontal sin daño")
	fixture(ids); await pause(.3)
	drive.rpc_id(first,Vector2.ZERO,0,1,1.0); await pause(.12)
	arena.session.local_action("attack"); await pause(.25)
	check(arena.session.actors[first].hp == 95,"guardia no protege por la espalda")
	fixture(ids); await pause(.3)
	for index in range(4):
		# Cada contacto empuja realmente al objetivo; acercar al atacante entre
		# golpes conserva el alcance sin alterar el daño ni la física del objetivo.
		if index > 0:
			arena.session.actors[1].player.position = arena.session.actors[first].player.position+Vector3.BACK*2.0
		arena.session.local_action("attack"); await pause(.37)
	check(arena.session.actors[first].player_ragdoll and arena.session.actors[first].physical_ragdoll.active,"cuarto M1 activa física real en host")
	var rag_report: Dictionary = await query(second,"ragdoll")
	photo.rpc_id(second,"02_ragdoll_replicado")
	var streamed := false
	for spec in rag_report.get("actors",[]):
		if int(spec.id) == first: streamed = bool(spec.pose) and not bool(spec.physics) and bool(spec.finite)
	check(streamed,"cliente recibe postura física finita sin segunda simulación")
	await pause(2.4)
	check(not arena.session.actors[first].player_ragdoll and not arena.session.actors[first].physical_ragdoll.active,"ragdoll recupera control y colisiones")
	check(arena.session.actors[first].player.collision_layer == 2,"recuperación restaura collider de jugador")
	photo.rpc_id(second,"03_recuperacion")
	# Comprobar el envío del rig y de los materiales de cada robot real.
	for variant in range(4):
		var old: Dictionary = arena.session.roster[first]
		var spec: Dictionary = arena.session.make_spec(first,old.nickname,1,int(old.slot),int(old.generation)+1,int(old.variant))
		spec.variant = variant; spec.color = variant
		arena.session.upsert_player.rpc(first,spec); await pause(.25)
		var variant_report: Dictionary = await query(second,"variant"+str(variant))
		var found := false
		for item in variant_report.get("actors",[]):
			if int(item.id) == first: found = int(item.variant) == variant and int(item.kind) == 1 and bool(item.finite)
		check(found,"robot %d sincroniza chasis, rig y apariencia" % variant)
	fixture(ids); await pause(.3)
	var old_generation: int = arena.session.roster[first].generation
	var old_variant: int = arena.session.roster[first].variant
	arena.session.actors[first].hp = 5
	arena.session.local_action("attack"); await pause(.25)
	check(arena.session.actors[first].hp == 0 and arena.session.actors[first].player_ragdoll,"muerte procede de golpe real")
	await pause(3.5)
	check(int(arena.session.roster[first].generation) == old_generation+1 and arena.session.actors[first].hp == 100,"reaparición automática sincronizada")
	check(int(arena.session.roster[first].variant) != old_variant,"robot cambia chasis al reaparecer")
	var generation: int = arena.session.roster[second].generation
	await client_choose(second,1); await pause(.4)
	check(int(arena.session.roster[second].generation) == generation+1 and int(arena.session.roster[second].character) == 1,"selector de cliente cambia personaje con autoridad host")
	await client_choose(second,0); await pause(.25)
	check(int(arena.session.roster[second].character) == 1,"cambio repetido respeta espera de 10 segundos")
	var rejected: int = arena.session.telemetry.rejected_inputs
	arena.session.apply_input(first,-1,Vector2(99,99),0,0)
	check(int(arena.session.telemetry.rejected_inputs) == rejected+1,"se descarta entrada vieja")
	check(arena.session.actors[first].hp == 100,"cliente no transmite daño ni vida en entrada")
	var age: float = arena.session.elapsed
	arena.menu_open = true; await pause(.2)
	check(arena.session.elapsed > age+.15,"menú no pausa simulación online")
	disconnect_client.rpc_id(second); check(await wait_players(2,3),"salida elimina jugador y libera plaza")
	var api_peer := multiplayer.multiplayer_peer
	check(api_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED,"anfitrión sigue activo tras salida")
	# Orden de reconexión enviada por archivo: el par ya no está conectado.
	FileAccess.open(directory.path_join("rejoin"),FileAccess.WRITE).store_string("go")
	check(await wait_players(3,45),"cliente puede reconectarse tras cargar los modelos")
	await pause(.4)
	check(arena.session.actors.size() == 3,"sin duplicados tras reconexión")
	arena.session.leave("QA anfitrión cierra partida"); await pause(.5)
	check(arena.session.actors.is_empty(),"anfitrión cierra red y actores")
	var passed := 0
	for result in checks:
		if result.ok: passed += 1
	print("RESULTADO ",passed,"/",checks.size())
	FileAccess.open(directory.path_join("finished.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"reports":reports,"passed":passed,"total":checks.size()},"\t"))
	finish(0 if passed == checks.size() else 1)

var rejoined := false

func finish(code: int) -> void:
	ended = true; arena.session.leave(); arena.queue_free()
	await get_tree().process_frame; await get_tree().process_frame; get_tree().quit(code)

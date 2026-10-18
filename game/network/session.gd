extends Node
# Todos los RPC usan esta ruta estable; ningún cliente puede transmitir daño o posiciones.
signal changed
signal message(text: String)
const PROTOCOL := "punchline-district-head-spider-1"
const DEFAULT_PORT := 7777
const MAX_PLAYERS := 3
const PLAYER = preload("res://network/player.gd")
var arena: Node3D
var api: MultiplayerAPI
var active := false
var connecting := false
var closing := false
var server := false
var roster: Dictionary = {}
var actors: Dictionary = {}
var waiting: Dictionary = {}
var ready_peers: Dictionary = {}
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var connect_started := 0.0
var input_sequence := 0
var action_sequence := 0
var snapshot_sequence := 0
var last_world_sequence := 0
var partial_snapshots: Dictionary = {}
var snapshot_timer := 0.0
var nickname := "Jugador"
var character := 0
var disconnect_reason := ""
var telemetry := {"snapshots":0,"hits":0,"blocked":0,"rejected_inputs":0,"events":0}

func setup(host: Node3D) -> void:
	arena = host; api = multiplayer; rng.randomize()
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected)
	multiplayer.connection_failed.connect(failed)
	multiplayer.server_disconnected.connect(server_gone)

func is_host() -> bool: return active and server
func local_id() -> int: return multiplayer.get_unique_id() if active else 0

func host_game(name_text: String, selected: int, port: int = DEFAULT_PORT) -> Error:
	if active or connecting: return ERR_ALREADY_IN_USE
	if port < 1024 or port > 65535: return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port,MAX_PLAYERS-1,3)
	if error != OK: message.emit("No se pudo abrir UDP %d: %s" % [port,error_string(error)]); return error
	multiplayer.multiplayer_peer = peer
	active = true; server = true; elapsed = 0; snapshot_sequence = 0
	nickname = clean_name(name_text); character = clampi(selected,0,1)
	var spec := make_spec(1,nickname,character,0,0,-1)
	upsert_player(1,spec)
	message.emit("Partida creada · UDP %d · 1/3. Comparte tu IP de Radmin VPN." % port); changed.emit()
	return OK

func join_game(address: String, port: int, name_text: String, selected: int) -> Error:
	if active or connecting: return ERR_ALREADY_IN_USE
	if address.strip_edges().is_empty() or address.length() > 253 or port < 1024 or port > 65535: return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address.strip_edges(),port,3)
	if error != OK: message.emit("No se pudo iniciar la conexión: "+error_string(error)); return error
	nickname = clean_name(name_text); character = clampi(selected,0,1)
	server = false; connecting = true; connect_started = Time.get_ticks_msec()/1000.0
	multiplayer.multiplayer_peer = peer
	message.emit("Conectando a %s:%d…" % [address.strip_edges(),port]); changed.emit()
	return OK

func clean_name(value: String) -> String:
	var result := value.strip_edges().replace("\n"," ").replace("\r"," ").replace("\t"," ").left(20)
	return "Jugador" if result.is_empty() else result

func peer_connected(id: int) -> void:
	if is_host():
		waiting[id] = Time.get_ticks_msec()/1000.0
		var peer: ENetPacketPeer = (multiplayer.multiplayer_peer as ENetMultiplayerPeer).get_peer(id)
		if peer != null: peer.set_timeout(32,60000,60000)

func connected() -> void:
	if not connecting: return
	connect_started = Time.get_ticks_msec()/1000.0
	active = true; hello.rpc_id(1,PROTOCOL,nickname,character)
	var peer: ENetPacketPeer = (multiplayer.multiplayer_peer as ENetMultiplayerPeer).get_peer(1)
	if peer != null: peer.set_timeout(32,60000,60000)

@rpc("any_peer","call_remote","reliable",0)
func hello(protocol: String, name_text: String, selected: int) -> void:
	if not is_host(): return
	var id := multiplayer.get_remote_sender_id()
	if id <= 1 or roster.has(id): return
	if protocol != PROTOCOL or roster.size() >= MAX_PLAYERS:
		disconnect_reason = "Usa la misma versión de PunchLine (District500 + Rustcrawler) que el anfitrión." if protocol != PROTOCOL else "La partida está completa (3/3)."
		reject_join.rpc_id(id,disconnect_reason)
		# Permitir que el motivo fiable llegue antes de cerrar ese par.
		get_tree().create_timer(.35).timeout.connect(func() -> void:
			if is_host() and multiplayer.get_peers().has(id): multiplayer.multiplayer_peer.disconnect_peer(id))
		return
	var slot := 1
	for spec in roster.values():
		if int(spec.slot) == slot: slot += 1
	if slot >= MAX_PLAYERS:
		for candidate in range(1,MAX_PLAYERS):
			var used := false
			for spec in roster.values():
				if int(spec.slot) == candidate: used = true
			if not used: slot = candidate; break
	for existing in roster: upsert_player.rpc_id(id,int(existing),roster[existing])
	var spec := make_spec(id,clean_name(name_text),clampi(selected,0,1),slot,0,-1)
	ready_peers.clear()
	upsert_player.rpc(id,spec); waiting.erase(id)
	message.emit("%s se unió · %d/3" % [spec.nickname,roster.size()]); changed.emit()

@rpc("authority","call_remote","reliable",0)
func reject_join(reason: String) -> void:
	disconnect_reason = reason; schedule_leave(reason)

func make_spec(id: int, name_text: String, selected: int, slot: int, generation: int, previous: int) -> Dictionary:
	var variant := rng.randi_range(0,3)
	if variant == previous: variant = (variant+1+rng.randi_range(0,2))%4
	var point: Vector3 = arena.spawn_for(slot)
	return {"id":id,"nickname":name_text,"character":selected,"variant":variant,"color":rng.randi_range(0,4),"slot":slot,"generation":generation,"spawn":point,"yaw":atan2(point.x,point.z)}

@rpc("authority","call_local","reliable",0)
func upsert_player(id: int, spec: Dictionary) -> void:
	var began := Time.get_ticks_usec()
	if roster.has(id) and int(roster[id].generation) >= int(spec.generation): return
	if connecting: connect_started = Time.get_ticks_msec()/1000.0
	if actors.has(id):
		clear_target_references(id)
		actors[id].moves.end_domain()
		var old: Node = actors[id]; arena.actor_root.remove_child(old); old.queue_free()
	roster[id] = spec.duplicate(true)
	var actor := PLAYER.new(); actor.name = "Player"+str(id); actor.session = self; actor.metadata = spec.duplicate(true)
	arena.actor_root.add_child(actor); actors[id] = actor
	actor.moves.domain_center = Vector3(200+int(spec.slot)*40,0,0)
	if is_host(): actor.input_state.time = actor.clock
	if id == multiplayer.get_unique_id(): connecting = false; arena.menu_open = false
	changed.emit()
	if OS.get_environment("NAOYA_NET_QA") == "1": print("PLAYER_READY ",local_id()," ",id," ",(Time.get_ticks_usec()-began)/1000.0," ms / actors ",actors.size())
	if active and not server: acknowledge_roster.call_deferred()

func acknowledge_roster() -> void:
	if OS.get_environment("NAOYA_NET_QA") == "1": print("ACK_ATTEMPT ",local_id()," ",active," ",server," ",actors.keys()," peers ",multiplayer.get_peers())
	if not active or server or not actors.has(local_id()) or not multiplayer.get_peers().has(1): return
	var generations := {}
	for id in roster: generations[id] = int(roster[id].generation)
	roster_ready.rpc_id(1,generations)

@rpc("any_peer","call_remote","reliable",0)
func roster_ready(generations: Dictionary) -> void:
	if not is_host(): return
	var sender := multiplayer.get_remote_sender_id()
	if OS.get_environment("NAOYA_NET_QA") == "1": print("ACK_RECEIVED ",sender," ",generations," expected ",roster.keys())
	if not roster.has(sender) or generations.size() != roster.size(): return
	for id in roster:
		if not generations.has(id) or int(generations[id]) != int(roster[id].generation): return
	ready_peers[sender] = true
	if OS.get_environment("NAOYA_NET_QA") == "1": print("ROSTER_READY ",sender," / ",roster.size())

func peer_disconnected(id: int) -> void:
	if OS.get_environment("NAOYA_NET_QA") == "1": print("PEER_LEFT ",local_id()," ",id," at ",Time.get_ticks_msec()/1000.0)
	ready_peers.erase(id)
	if is_host():
		waiting.erase(id)
		if roster.has(id): remove_player.rpc(id)

@rpc("authority","call_local","reliable",0)
func remove_player(id: int) -> void:
	clear_target_references(id)
	if actors.has(id): actors[id].moves.end_domain(); arena.actor_root.remove_child(actors[id]); actors[id].queue_free(); actors.erase(id)
	roster.erase(id); changed.emit()
	if active and not server: acknowledge_roster.call_deferred()

func local_input(axis: Vector2, view_yaw: float, flags: int, view_pitch: float = -.24) -> void:
	if not active or not actors.has(local_id()): return
	input_sequence += 1
	if server: apply_input(1,input_sequence,axis,view_yaw,flags,view_pitch)
	else: submit_input.rpc_id(1,input_sequence,axis,view_yaw,flags,view_pitch)

@rpc("any_peer","call_remote","unreliable_ordered",1)
func submit_input(sequence: int, axis: Vector2, view_yaw: float, flags: int, view_pitch: float = -.24) -> void:
	if is_host(): apply_input(multiplayer.get_remote_sender_id(),sequence,axis,view_yaw,flags,view_pitch)

func apply_input(id: int, sequence: int, axis: Vector2, view_yaw: float, flags: int, view_pitch: float = -.24) -> void:
	if not actors.has(id): return
	var actor: Node3D = actors[id]
	if sequence <= int(actor.input_state.seq) or not axis.is_finite() or not is_finite(view_yaw) or not is_finite(view_pitch) or flags < 0 or flags > 31:
		telemetry.rejected_inputs += 1; return
	actor.pitch = clampf(view_pitch,-1.35,1.35) if flags & 16 != 0 else clampf(view_pitch,-1.05,.25)
	actor.input_state = {"axis":axis.limit_length(1),"yaw":wrapf(view_yaw,-PI,PI),"flags":flags,"seq":sequence,"time":actor.clock}

func local_action(action: String) -> void:
	if not active or not actors.has(local_id()): return
	action_sequence += 1
	if server: apply_action(1,action_sequence,action)
	else: request_action.rpc_id(1,action_sequence,action)

@rpc("any_peer","call_remote","reliable",0)
func request_action(sequence: int, action: String) -> void:
	if is_host(): apply_action(multiplayer.get_remote_sender_id(),sequence,action)

func apply_action(id: int, sequence: int, action: String) -> void:
	if not actors.has(id) or action not in ["interact","attack","jump","dash","ability1","ability2","ability3","ability4","transform","kogane","lock","cannon_release","emote:0","emote:1","emote:2","emote:3","emote:4","emote:5","emote:6"]: return
	var actor: Node3D = actors[id]
	if sequence <= actor.last_action_sequence: return
	actor.last_action_sequence = sequence; actor.queue_action(action)

func local_character(selected: int) -> void:
	if not active: return
	if server: change_character(1,selected)
	else: request_character.rpc_id(1,selected)

@rpc("any_peer","call_remote","reliable",0)
func request_character(selected: int) -> void:
	if is_host(): change_character(multiplayer.get_remote_sender_id(),selected)

func change_character(id: int, selected: int) -> void:
	if not actors.has(id) or selected not in [0,1]: return
	var actor: Node3D = actors[id]
	if actor.clock-actor.last_character_change < 10 or actor.clock-actor.last_damage_time < 5 or not actor.actionable():
		private_message(id,"Espera 10 s entre cambios y 5 s después de recibir daño."); return
	respawn(id,selected)

func respawn(id: int, selected: int = -1) -> void:
	if not is_host() or not roster.has(id): return
	var old: Dictionary = roster[id]
	var kind: int = int(old.character) if selected < 0 else selected
	var spec := make_spec(id,old.nickname,kind,int(old.slot),int(old.generation)+1,int(old.variant))
	var character_change: float = actors[id].last_character_change
	var damage_time: float = actors[id].last_damage_time
	var age: float = actors[id].clock
	var robot_charge: float = actors[id].charge if kind == 1 and int(old.character) == 1 and selected < 0 else 0.0
	ready_peers.clear()
	upsert_player.rpc(id,spec)
	if kind == 1: actors[id].charge = robot_charge
	actors[id].clock = age; actors[id].last_character_change = age if selected >= 0 else character_change
	actors[id].last_damage_time = damage_time

func private_message(id: int, text_value: String) -> void:
	if id == 1: message.emit(text_value)
	else: information.rpc_id(id,text_value)

@rpc("authority","call_remote","reliable",0)
func information(text_value: String) -> void: message.emit(text_value)

func resolve_m1(attacker: Node3D) -> void:
	if is_host() and attacker.hp > 0: attacker.resolve_punch_hit()

func effect(kind: String, source: int, target: int, damage: float) -> void:
	if kind == "block": telemetry.blocked += 1
	if damage > 0: telemetry.hits += 1
	var point: Vector3 = actors[target if target != 0 else source].player.position
	play_effect.rpc(kind,point,source,target,damage)

@rpc("authority","call_local","reliable",0)
func play_effect(kind: String, point: Vector3, source: int, target: int, damage: float) -> void:
	telemetry.events += 1; arena.play_sound(kind,point)
	if actors.has(source):
		actors[source].feedback.particles(point+Vector3.UP,Color("e8d8c2"),false,8)
		if damage > 0 and source == local_id(): actors[source].interface.confirm_hit(damage)
	if damage > 0: arena.show_damage(point+Vector3.UP*1.6,damage)
	if target == local_id(): arena.hit_flash = .12
	if source == local_id() and damage > 0: arena.last_hit = "+%d" % int(damage); arena.hit_notice_time = .5

func _physics_process(delta: float) -> void:
	# El transporte y la carga inicial son fases diferentes. Importar varios rigs
	# en un equipo lento no debe notificarse como fallo de IP/firewall a los 12 s.
	if connecting and Time.get_ticks_msec()/1000.0-connect_started > (60.0 if active else 30.0):
		leave("El anfitrión no terminó de enviar el estado inicial." if active else "Conexión agotada. Comprueba IP de Radmin, partida abierta y firewall UDP."); return
	if not is_host(): return
	elapsed += delta
	for id in waiting.keys():
		if Time.get_ticks_msec()/1000.0-float(waiting[id]) > 60: multiplayer.multiplayer_peer.disconnect_peer(int(id)); waiting.erase(id)
	for actor in actors.values():
		if is_instance_valid(actor) and not actor.is_queued_for_deletion(): actor.simulate(delta)
	snapshot_timer += delta
	if snapshot_timer >= .05:
		snapshot_timer = fmod(snapshot_timer,.05); snapshot_sequence += 1
		var world: Array[Dictionary] = []
		for actor in actors.values(): world.append(actor.make_snapshot())
		if roster.size() > 1:
			# Evitar fragmentación de datagramas: huesos y diccionarios van comprimidos
			# en partes de 1000 bytes, siempre por debajo del MTU de ENet.
			var payload := var_to_bytes(world).compress(FileAccess.COMPRESSION_DEFLATE)
			var count := ceili(payload.size()/1000.0)
			for peer in ready_peers:
				if not multiplayer.get_peers().has(peer): continue
				for part in range(count): world_snapshot.rpc_id(peer,snapshot_sequence,part,count,payload.slice(part*1000,mini((part+1)*1000,payload.size())))

@rpc("authority","call_remote","unreliable_ordered",2)
func world_snapshot(sequence: int, part: int, count: int, payload: PackedByteArray) -> void:
	if sequence <= last_world_sequence or count < 1 or count > 32 or part < 0 or part >= count or payload.size() > 1000: return
	if not partial_snapshots.has(sequence): partial_snapshots[sequence] = {"count":count,"parts":{}}
	var partial: Dictionary = partial_snapshots[sequence]
	if int(partial.count) != count: return
	partial.parts[part] = payload
	for old in partial_snapshots.keys():
		if int(old) < sequence-2: partial_snapshots.erase(old)
	if partial.parts.size() != count: return
	var bytes := PackedByteArray()
	for index in range(count): bytes.append_array(partial.parts[index])
	var decoded: Variant = bytes_to_var(bytes.decompress_dynamic(65536,FileAccess.COMPRESSION_DEFLATE))
	if not decoded is Array: return
	last_world_sequence = sequence; telemetry.snapshots += 1; partial_snapshots.erase(sequence)
	for state in decoded:
		if state is Dictionary and actors.has(int(state.id)): actors[int(state.id)].accept_snapshot(sequence,state)

func schedule_leave(reason: String) -> void:
	if closing or not (active or connecting): return
	closing = true; release_rpc_cache(); leave.call_deferred(reason)

func release_rpc_cache() -> void:
	# Godot 4.4.1: SceneCacheInterface::clear desconecta sin el bind(ObjectID)
	# usado al conectar tree_exited (líneas 44 y 301 del código oficial).
	# Al salir temporalmente del árbol, el callback original limpia su entrada
	# antes de que el motor borre la caché. Solo ocurre al cerrar la conexión;
	# no se quitan ni modifican huesos, modelos, mapa ni mecánicas.
	if OS.has_feature("editor") or get_parent() == null: return
	var parent := get_parent()
	parent.remove_child(self); parent.add_child(self)

func failed() -> void: schedule_leave("No se pudo conectar. Revisa IP y puerto; el anfitrión debe tener la partida abierta.")
func server_gone() -> void: schedule_leave(disconnect_reason if not disconnect_reason.is_empty() else "El anfitrión cerró la partida.")

func leave(reason: String = "Desconectado") -> void:
	active = false; connecting = false; server = false
	release_rpc_cache()
	if api.multiplayer_peer != null: api.multiplayer_peer.close()
	api.multiplayer_peer = OfflineMultiplayerPeer.new()
	for actor in actors.values(): actor.moves.end_domain(); arena.actor_root.remove_child(actor); actor.queue_free()
	actors.clear(); roster.clear(); waiting.clear(); ready_peers.clear(); partial_snapshots.clear()
	input_sequence = 0; action_sequence = 0; snapshot_sequence = 0; last_world_sequence = 0
	snapshot_timer = 0; disconnect_reason = ""; closing = false; arena.menu_open = true
	message.emit(reason); changed.emit()

func local_name(value: String) -> void:
	if not active: return
	if server: change_name(1,value)
	else: request_name.rpc_id(1,value)
func clear_target_references(id: int) -> void:
	for actor in actors.values():
		if actor.peer_id == id: continue
		if int(actor.moves.target.get("peer",0)) == id or int(actor.rush_target.get("peer",0)) == id: actor.cancel_skill()
		for entry in actor.moves.domain_targets:
			if int(entry.enemy.get("peer",0)) == id: actor.moves.end_domain(); break
		actor.proxies.erase(id)
@rpc("any_peer","call_remote","reliable",0)
func request_name(value: String) -> void:
	if is_host(): change_name(multiplayer.get_remote_sender_id(),value)
func change_name(id: int,value: String) -> void:
	if roster.has(id): player_name.rpc(id,clean_name(value))
@rpc("authority","call_local","reliable",0)
func player_name(id: int,value: String) -> void:
	if not roster.has(id): return
	roster[id].nickname = value; actors[id].metadata.nickname = value
	if id == local_id(): nickname = value
	changed.emit()
@rpc("authority","call_local","reliable",0)
func spatial_sound(id: int,kind: String,point: Vector3,volume: float) -> void:
	if actors.has(id): actors[id].feedback.play_local(kind,point,volume)

@rpc("authority","call_local","reliable",0)
func fusion_step(point: Vector3,strength: float,_step_index: int) -> void:
	if actors.has(local_id()): actors[local_id()].fusion.impulse(point,strength)
@rpc("authority","call_local","reliable",0)
func robot_skill_effect(id: int,slot: int,point: Vector3,impact: bool,token: int) -> void:
	if not actors.has(id): return
	if impact: actors[id].skill_vfx.impact_local(slot,point)
	else: actors[id].skill_vfx.cast_local(slot,token)

@rpc("authority","call_local","reliable",0)
func mecha_skill_effect(id: int,data: Dictionary) -> void:
	if actors.has(id): actors[id].skill_vfx.mega_local(data)

extends Node
var arena: Node3D
var role: String
var directory: String
var port: int
var age := 0.0
var joined := false
var started := false
var completed := false
var rejected := false
var reason := ""
func _ready() -> void:
	role = OS.get_environment("NAOYA_NET_ROLE"); directory = OS.get_environment("NAOYA_NET_OUTPUT"); port = int(OS.get_environment("NAOYA_NET_PORT"))
	arena = preload("res://network/online.tscn").instantiate(); add_child(arena)
	arena.session.message.connect(func(value: String) -> void: reason = value; print(role," ",value))
	await get_tree().create_timer(.3).timeout
	if role == "lifecycle_host":
		arena.session.host_game("Host",0,port)
	elif role in ["lifecycle_one","lifecycle_two"]: arena.session.join_game("127.0.0.1",port,role,0)
	elif role == "lifecycle_bad":
		multiplayer.connected_to_server.disconnect(arena.session.connected)
		multiplayer.connected_to_server.connect(func() -> void:
			arena.session.active = true; arena.session.hello.rpc_id(1,"no-es-esta-version","incompatible",0))
		arena.session.join_game("127.0.0.1",port,role,0)
	elif role == "lifecycle_extra": arena.session.join_game("127.0.0.1",port,role,0)
	elif role == "lifecycle_timeout": arena.session.join_game("127.0.0.1",port+1,role,0)

func flag(name: String) -> void: FileAccess.open(directory.path_join(name),FileAccess.WRITE).store_string("go")
func exists(name: String) -> bool: return FileAccess.file_exists(directory.path_join(name))

func _process(delta: float) -> void:
	if completed or arena == null: return
	age += delta
	if age > 48: done(false,"timeout de la prueba"); return
	var count: int = arena.session.roster.size()
	match role:
		"lifecycle_host":
			if count == 3 and not started: started = true; flag("three")
			if exists("lifecycle_extra.json") and not rejected:
				rejected = true
				for id in arena.session.roster.keys():
					if arena.session.roster[id].nickname == "lifecycle_two": multiplayer.multiplayer_peer.disconnect_peer(int(id)); break
			if rejected and count == 2 and not exists("bad_start"): flag("bad_start")
			if exists("lifecycle_bad.json") and exists("lifecycle_timeout.json"): done(count == 2,"capacidad y protocolo conservan dos jugadores válidos")
		"lifecycle_one":
			if arena.session.actors.has(arena.session.local_id()): joined = true
			if joined and not arena.session.active: done(arena.session.actors.is_empty(),"cierre del anfitrión limpia réplicas")
		"lifecycle_two":
			if arena.session.actors.has(arena.session.local_id()): joined = true
			if joined and not arena.session.active: done(arena.session.actors.is_empty(),"desconexión elimina réplicas")
		"lifecycle_extra":
			if age > 1 and not arena.session.active and not arena.session.connecting: done(arena.session.actors.is_empty(),"cuarto jugador no entra a partida de tres")
		"lifecycle_bad":
			if age > 1 and not arena.session.active and not arena.session.connecting: done("misma versión" in reason and arena.session.actors.is_empty(),"versión incompatible rechazada con motivo")
		"lifecycle_timeout":
			if age > 1 and not arena.session.active and not arena.session.connecting: done("agotada" in reason and arena.session.actors.is_empty(),"dirección sin servidor permite cancelar/reintentar")

func done(ok: bool, title: String) -> void:
	completed = true
	print("PASS " if ok else "FAIL ",title)
	FileAccess.open(directory.path_join(role+".json"),FileAccess.WRITE).store_string(JSON.stringify({"ok":ok,"title":title,"reason":reason,"roster":arena.session.roster.size(),"actors":arena.session.actors.size()}))
	arena.session.leave(); arena.queue_free()
	await get_tree().process_frame; await get_tree().process_frame; get_tree().quit(0 if ok else 1)

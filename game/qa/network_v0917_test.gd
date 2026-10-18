extends SceneTree
var checks := 0
var passed := 0
func _initialize() -> void: run.call_deferred()
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func check(ok: bool,title: String) -> void:
	checks += 1
	if ok: passed += 1
	print("PASS " if ok else "FAIL ",title)
func run() -> void:
	var arena: Node3D = load("res://network/online.tscn").instantiate(); root.add_child(arena); await frames(3)
	var env: WorldEnvironment = arena.get_node("ArenaEnvironment")
	check(env.environment.background_mode == Environment.BG_SKY and env.environment.sky.sky_material is PanoramaSkyMaterial,"panorama real en mundo online")
	check(env.environment.sky.sky_material.panorama == load("res://assets/environment/v098/sky/skybox-morning.png"),"mismo recurso de skybox Kenney")
	arena.session.active = true; arena.session.server = true; arena.menu_open = false
	for i in range(3): arena.session.upsert_player(i+1,{"id":i+1,"nickname":"QA"+str(i+1),"character":1,"variant":i,"color":0,"slot":i,"generation":0,"spawn":Vector3(-16+i*12,.1,0),"yaw":0.0})
	await frames(10)
	var host: Node3D = arena.session.actors[1]; var other: Node3D = arena.session.actors[2]
	for i in range(3):
		var actor: Node3D = arena.session.actors[i+1]; actor.block = true; actor.skill_vfx.update_jets()
		check(actor.skill_vfx.guard_shield.visible,"escudo online jugador "+str(i+1))
	host.camera_lock = false
	var seq: int = host.input_state.seq+1
	arena.session.apply_input(1,seq,Vector2.ZERO,1.0,16,0)
	check(host.first_person_enabled() and host.camera_aim_locked(),"primera persona llega al controlador autoritativo sin alterar lock manual")
	arena.session.apply_input(1,seq+1,Vector2.ZERO,1.0,32,0)
	check(host.input_state.seq == seq,"bits de entrada no reconocidos siguen rechazados")
	host.camera_lock = true
	arena.zoom = 0; arena._process(.016)
	check(arena.camera_view.active,"primera persona del jugador local online")
	var remote_layers: int = other.robots.current.meshes[0].layers
	check(remote_layers == 1,"primera persona local no oculta jugador remoto")
	var saved_camera: Transform3D = arena.camera.global_transform
	check(absf(arena.camera.global_position.y-host.player.global_position.y-arena.camera_view.eye_height(host))<.02,"ojos online según chasis local")
	arena.zoom = 5.5; arena._process(.016)
	check(not arena.camera_view.active and host.robots.current.meshes[0].layers == 1,"salir primera persona restaura cuerpo online")
	# Bloqueo se transmite en snapshot; el efecto también nace en la réplica.
	var snap: Dictionary = host.make_snapshot()
	var viewport := SubViewport.new(); viewport.own_world_3d = true; root.add_child(viewport)
	var remote: Node3D = load("res://network/online.tscn").instantiate(); viewport.add_child(remote); remote.session.active = true; remote.session.server = false
	remote.session.upsert_player(1,host.metadata); await frames(3)
	var copy: Node3D = remote.session.actors[1]; copy.accept_snapshot(1,snap); copy.interpolate_state(.05); copy.skill_vfx.update_jets()
	check(copy.block and is_instance_valid(copy.skill_vfx.guard_shield) and copy.skill_vfx.guard_shield.visible,"escudo de guardia replicado al cliente")
	remote.session.leave(); viewport.queue_free(); arena.session.leave(); arena.queue_free(); await frames(8)
	print("RESULTADO ",passed,"/",checks); quit(0 if passed==checks else 1)

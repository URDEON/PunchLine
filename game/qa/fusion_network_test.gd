extends SceneTree
var checks := 0
var passed := 0
var arena: Node3D
func _initialize() -> void: run.call_deferred()
func check(ok: bool,title: String) -> void:
	checks += 1
	if ok: passed += 1
	print("PASS " if ok else "FAIL ",title)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	arena = preload("res://network/online.tscn").instantiate(); root.add_child(arena)
	arena.session.active = true; arena.session.server = true
	for index in range(3): arena.session.upsert_player(index+1,{"id":index+1,"nickname":"Piloto"+str(index+1),"character":1,"variant":index,"color":index,"slot":index,"generation":0,"spawn":Vector3(index*12,.25,0),"yaw":0.0})
	await frames(10)
	var viewport := SubViewport.new(); viewport.world_3d = World3D.new(); root.add_child(viewport)
	var replica: Node3D = preload("res://network/online.tscn").instantiate(); viewport.add_child(replica)
	replica.session.active = true; replica.session.server = false
	for actor in arena.session.actors.values(): replica.session.upsert_player(actor.peer_id,actor.metadata)
	await frames(5)
	var sequence_number := 1
	for variant in range(4):
		var spec: Dictionary = arena.session.roster[1].duplicate(); spec.generation = variant+1; spec.variant = variant; spec.spawn = Vector3(0,.25,0)
		arena.session.upsert_player(1,spec); replica.session.upsert_player(1,spec); await frames(10)
		var host: Node3D = arena.session.actors[1]; var client: Node3D = replica.session.actors[1]
		host.input_state.time = host.clock
		host.charge = 100
		arena.session.local_action("transform"); await frames(2)
		check(host.fusion.cinematic,"G autoritativa inicia con "+host.robots.NAMES[variant])
		if not host.fusion.cinematic: continue
		check(host.fusion.sequence.original_names[0] == host.robots.NAMES[variant] and host.fusion.sequence.original_names.size() == 4,"reparto sin repetir chasis "+str(variant))
		var snapshot: Dictionary = host.make_snapshot(); client.accept_snapshot(sequence_number,snapshot); sequence_number += 1; client.interpolate_state(.05)
		check(client.fusion.cinematic and client.fusion.sequence.original_names[0] == host.robots.NAMES[variant],"réplica recibe chasis y fase "+str(variant))
		host.fusion.sequence.advance(11.5); await frames(2)
		check(host.fusion.fused and not is_instance_valid(host.fusion.assembly_guard),"montaje termina y limpia barrera "+str(variant))
		snapshot = host.make_snapshot(); client.accept_snapshot(sequence_number,snapshot); sequence_number += 1; client.interpolate_state(.05)
		check(client.fusion.fused and client.fusion.visual() != null and client.fusion.visual().visible,"réplica activa las 22 piezas finales "+str(variant))
		if variant == 0:
			var origin: Vector3 = host.player.position
			for i in range(55):
				arena.session.local_input(Vector2(0,-1),0,0); await physics_frame
			check(host.player.position.distance_to(origin) > 1,"forma final se desplaza con entrada real")
			check(host.fusion.step_index > 0,"desplazamiento real activa pasos pesados")
			host.moves.freeze_player(5); snapshot = host.make_snapshot(); client.accept_snapshot(sequence_number,snapshot); sequence_number += 1; client.interpolate_state(.05)
			check(not host.fusion.visual().visible and not client.fusion.visual().visible,"vidrio oculta Rust Vanguard en ambos controladores")
			host.moves.break_player_frame("hit"); snapshot = host.make_snapshot(); client.accept_snapshot(sequence_number,snapshot); sequence_number += 1; client.interpolate_state(.05)
			check(host.fusion.visual().visible and client.fusion.visual().visible,"rotura restaura las piezas finales")
		var bytes := var_to_bytes([host.make_snapshot()]).compress(FileAccess.COMPRESSION_DEFLATE)
		check(bytes.size() < 32000,"estado de fusión no excede paquete "+str(variant))
		client.fusion.reset(); host.fusion.reset()
	var pilot: Node3D = arena.session.actors[1]
	pilot.player.position = Vector3(0,.2,0); pilot.player.velocity = Vector3.ZERO; await frames(5)
	var ceiling := StaticBody3D.new(); arena.add_child(ceiling); ceiling.position = Vector3(0,3,0)
	var collider := CollisionShape3D.new(); var box := BoxShape3D.new(); box.size = Vector3(6,.5,6); collider.shape = box; ceiling.add_child(collider); await frames(3)
	pilot.charge = 100
	check(pilot.fusion.request() and pilot.fusion.origin.distance_to(Vector3.ZERO) > 5,"fusión bajo techo busca montaje al aire libre")
	pilot.fusion.reset(); ceiling.queue_free()
	replica.session.leave(); viewport.queue_free(); await process_frame
	arena.session.leave(); arena.queue_free(); await process_frame; await process_frame
	print("RESULTADO ",passed,"/",checks); quit(0 if passed == checks else 1)

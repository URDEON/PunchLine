extends SceneTree
var arena: Node3D
var checks := 0
var passed := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,title: String) -> void:
	checks += 1
	if ok: passed += 1
	print("PASS " if ok else "FAIL ",title)
func pause(seconds: float) -> void: await create_timer(seconds).timeout
func fixture() -> void:
	for index in range(3):
		var actor: Node3D = arena.session.actors[index+1]
		actor.moves.end_domain(); actor.moves.clear_player_frame(); actor.presentation.reset(); actor.cancel_skill(); actor.physical_ragdoll.cancel()
		actor.form = "BASE"; actor.moves.form_changed(); actor.presentation.show_form("BASE")
		actor.player_ragdoll = false; actor.player_ragdoll_time = 0; actor.hp = 100; actor.stun = 0; actor.held_time = 0
		actor.spawn_protection = 0; actor.player_wakeup_protection = 0; actor.attack_anim = 0; actor.attack_cd = 0; actor.attack_hit_done = true; actor.combo = 0; actor.combo_timeout = 0
		actor.skill3_cd = 0; actor.skill4_cd = 0; actor.action_queue.clear(); actor.player.velocity = Vector3.ZERO
		for key in actor.moves.cooldowns: actor.moves.cooldowns[key] = 0
		actor.player.position = [Vector3(0,.25,4),Vector3(0,.25,1.6),Vector3(6,.25,4)][index]
		actor.model.rotation.y = 0 if index == 0 else PI
		actor.input_state = {"axis":Vector2.ZERO,"yaw":actor.model.rotation.y,"flags":0,"seq":actor.input_state.seq,"time":actor.clock}
	for actor in arena.session.actors.values(): actor.refresh_targets()
func run() -> void:
	arena = preload("res://network/online.tscn").instantiate(); root.add_child(arena)
	await pause(.2)
	# Local authority harness: exercises real controllers and physics, not ENet.
	arena.session.active = true; arena.session.server = true
	for index in range(3):
		arena.session.upsert_player(index+1,{"id":index+1,"nickname":["Edu","Amigo","Robot"][index],"character":1 if index == 2 else 0,"variant":1,"color":0,"slot":index,"generation":0,"spawn":Vector3(index*5,.25,4),"yaw":0.0})
	await pause(.3)
	var host: Node3D = arena.session.actors[1]; var target: Node3D = arena.session.actors[2]
	check(host.interface.identity.is_visible_in_tree() and host.interface.cards.size() == 4,"HUD original con identidad y cuatro habilidades")
	check(not target.interface.visible,"HUD remoto oculto")
	check(arena.name_field.editable,"nombre editable estando conectado")
	arena.name_field.text = "Edu Ñ"; arena.rename_button.pressed.emit()
	check(arena.session.roster[1].nickname == "Edu Ñ","renombrar actualiza el roster")
	fixture(); await pause(.2)
	for slot in [3,4]:
		fixture(); await pause(.2); arena.session.local_action("ability"+str(slot)); await pause(.85)
		check(target.hp < 100,"habilidad "+str(slot)+" usa contacto y daño reales")
	fixture(); await pause(.2); arena.session.local_action("ability1"); await pause(1.8)
	check(target.hp < 100 and host.moves.cooldowns.b1 > 0,"Proyección guiada online con daño y cooldown")
	fixture(); await pause(.2); arena.session.local_action("ability2"); await pause(.75)
	check(host.moves.player_freeze > 4 and is_instance_valid(host.moves.player_frame),"counter fallido cristaliza al usuario")
	check(not host.rig_holder.visible,"cristalización oculta el 3D")
	target.perform_hit(target.proxies[1],6,0,Vector3.BACK,0,0,.1)
	check(host.moves.player_freeze == 0 and host.rig_holder.visible,"un golpe rompe el vidrio y restaura el rig")
	fixture(); await pause(.2); arena.session.local_action("ability2"); await pause(.2)
	target.perform_hit(target.proxies[1],6,0,Vector3.BACK,0,0,.1)
	check(target.moves.player_freeze > 4 and host.hp == 100,"counter correcto cristaliza al atacante")
	fixture(); await pause(.2); host.charge = 100; arena.session.local_action("transform"); await pause(3.2)
	check(host.form == "FORM1","G activa transformación original")
	host.moves.phase_charge = 100; arena.session.local_action("transform"); await pause(3.2)
	check(host.form == "FORM2","G activa evolución original")
	arena.session.local_action("ability4"); await pause(1.2)
	check(host.moves.domain_time > 0 and is_instance_valid(host.moves.domain_arena),"dominio original activo con geometría real")
	fixture(); await pause(.2); arena.session.local_action("kogane"); await pause(.2)
	check(host.presentation.kogane_invoked,"K invoca Kogane")
	arena.session.local_action("emote:0"); await pause(.2)
	check(host.presentation.emote_time > 0,"emote original activado")
	var robot: Node3D = arena.session.actors[3]
	fixture(); await pause(.2); robot.queue_action("ability1"); await pause(.2)
	check(robot.robots.cooldowns[0] > 0 and robot.skill_active == "robot","habilidad original de Stan")
	var snap: Dictionary = host.make_snapshot()
	check(snap.has("full") and snap.full.moves.has("cooldowns") and snap.rotations.size() == host.skeleton.get_bone_count(),"snapshot transmite habilidades, forma, emote y huesos")
	var viewport := SubViewport.new(); viewport.world_3d = World3D.new(); root.add_child(viewport)
	var replica: Node3D = preload("res://network/online.tscn").instantiate(); viewport.add_child(replica)
	replica.session.active = true; replica.session.server = false
	for actor in arena.session.actors.values(): replica.session.upsert_player(actor.peer_id,actor.metadata)
	await process_frame
	var copied: Node3D = replica.session.actors[1]
	copied.accept_snapshot(1,snap); copied.interpolate_state(.05)
	check(copied.interface.cards.size() == 4 and copied.moves.cooldowns.b1 == host.moves.cooldowns.b1,"cliente recibe HUD y cooldowns reales")
	check(copied.skeleton.get_bone_pose_rotation(4).angle_to(host.skeleton.get_bone_pose_rotation(4)) < .001,"cliente conserva la animación real del rig")
	host.start_form("FORM2",true); host.presentation.reset(); snap = host.make_snapshot()
	copied.accept_snapshot(2,snap); copied.interpolate_state(.05)
	check(copied.form == "FORM2" and copied.moves.curse.visible,"cliente muestra segunda forma")
	host.moves.begin_domain(); snap = host.make_snapshot(); copied.accept_snapshot(3,snap); copied.interpolate_state(.05)
	check(is_instance_valid(copied.moves.domain_arena),"cliente construye interior y exterior del dominio")
	host.moves.end_domain(); host.end_form(); host.moves.freeze_player(5); snap = host.make_snapshot(); copied.accept_snapshot(4,snap); copied.interpolate_state(.05)
	check(copied.moves.player_freeze > 0 and not copied.rig_holder.visible,"cliente mantiene exclusión 2D/3D al cristalizar")
	host.moves.break_player_frame("hit"); snap = host.make_snapshot(); copied.accept_snapshot(5,snap); copied.interpolate_state(.05)
	check(copied.moves.player_freeze == 0 and copied.rig_holder.visible,"cliente restaura el 3D cuando se rompe el frame")
	var world: Array[Dictionary] = []
	for actor in arena.session.actors.values(): world.append(actor.make_snapshot())
	var bytes := var_to_bytes(world).compress(FileAccess.COMPRESSION_DEFLATE)
	var count := ceili(bytes.size()/1000.0)
	for part in range(count): replica.session.world_snapshot(10,part,count,bytes.slice(part*1000,mini((part+1)*1000,bytes.size())))
	check(replica.session.last_world_sequence == 10 and copied.last_snapshot == 10,"paquete comprimido de tres jugadores se reconstruye en el cliente")
	check(count <= 32 and var_to_bytes(world).size() <= 65536,"habilidades y huesos caben dentro del límite de transferencia")
	replica.session.leave(); viewport.queue_free(); await process_frame
	fixture(); await pause(.2); host.moves.freeze_player(5); await pause(5.1)
	check(host.moves.player_freeze == 0 and host.rig_holder.visible,"vidrio desaparece por tiempo y restaura controles")
	fixture(); await pause(.2); host.set_paused(true); var age: float = target.clock; await pause(.2)
	check(target.clock > age and not host.paused,"menú online no detiene la simulación de los demás")
	host.set_paused(false)
	if not OS.get_environment("NAOYA_NET_CAPTURE").is_empty():
		arena.menu_open = false; arena.refresh_ui()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("NAOYA_NET_CAPTURE"))
	arena.session.leave(); arena.queue_free(); await process_frame; await process_frame
	print("RESULTADO ",passed,"/",checks); quit(0 if passed == checks else 1)

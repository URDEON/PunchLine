extends SceneTree
const SNAP = preload("res://scripts/mesh_pose_snapshot.gd")
var game: Node3D
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,text: String) -> void:
	checks += 1; print("PASS " if ok else "FAIL ",text)
	if not ok: failures += 1
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	game = load("res://main.tscn").instantiate(); root.add_child(game); await frames(8)
	var original: Skeleton3D = game.visual_motion.find_skeleton(game.rig_scene)
	check(game.interface.character_rows[1].text == "Robot" and not game.interface.character_rows[1].disabled,"segundo personaje habilitado")
	for index in range(4):
		game.robots.forced = index
		if not game.robots.active: game.robots.select(1)
		else: game.respawn_player()
		game.robots.forced = -1; game.set_paused(false)
		for enemy in game.enemies: game.set_dummy_mode(enemy,0); enemy.body.position = Vector3(40,0,40)
		game.player.position = Vector3(0,.1,8); game.player.velocity = Vector3.ZERO; game.model.rotation.y = 0
		await frames(40)
		var name: String = game.robots.NAMES[index]
		var sk: Skeleton3D = game.robots.current.skeleton
		check(game.robots.index == index and game.rig_holder.visible,"chasis activo: "+name)
		check(sk.get_bone_count() == [17,43,47,43][index] and game.physical_ragdoll.initialized,"rig y física propia: "+name)
		var enemy: Dictionary = game.enemies[0]
		enemy.body.position = game.player.position+game.facing_forward()*1.7
		await frames(4)
		game.punch()
		await frames(2)
		check(game.robots.attack.clip == ("Kick" if index == 0 else "Punch") and game.rig_anim.current_animation == game.rig_anim_names[game.robots.attack.clip.to_lower()],"M1 usa clip real del chasis: "+name)
		await frames(ceili(game.robots.DURATIONS[index]*60)+10)
		check(enemy.hp < 100,"M1 real registra contacto: "+name)
		check(not game.robots.press(4) and game.skill_active == "","habilidad ausente no se activa: "+name)
		game.interface.tick(.016)
		check(game.interface.cards[3].panel.unavailable and game.interface.phase_text.text.contains(name.to_upper()),"HUD según chasis: "+name)
		game.moves.freeze_player(5); await frames(4)
		check(not game.rig_holder.visible,"cristalización oculta robot: "+name)
		game.moves.clear_player_frame(); await frames(4)
		check(game.rig_holder.visible,"libera robot correcto: "+name)
		var vertices: PackedVector3Array = SNAP.vertices(game.robots.current.meshes[0],sk,0)
		var rest_positions: Array[Vector3] = []
		var rest_scales: Array[Vector3] = []
		for bone_index in range(sk.get_bone_count()):
			rest_positions.append(game.physical_ragdoll.rest_positions[bone_index]); rest_scales.append(Vector3.ONE)
		game.physical_ragdoll.start(Vector3(0,3,-5),{"kind":"horizontal","direction":Vector3.FORWARD})
		var finite := true; var speed := 0.0; var diameter := 0.0; var lengths := true
		for i in range(90):
			await physics_frame; game.physical_ragdoll.follow_actor()
			for bone in game.physical_ragdoll.bodies: finite = finite and bone.global_position.is_finite(); speed = maxf(speed,bone.linear_velocity.length())
			for bone_index in range(sk.get_bone_count()):
				if game.physical_ragdoll.dynamic_translation(bone_index): continue
				lengths = lengths and sk.get_bone_pose_position(bone_index).is_equal_approx(rest_positions[bone_index]) and sk.get_bone_pose_scale(bone_index).is_equal_approx(rest_scales[bone_index])
			if i % 15 == 0:
				var pose := SNAP.vertices(game.robots.current.meshes[0],sk,0); var bounds := AABB(pose[0],Vector3.ZERO)
				for point in pose: finite = finite and point.is_finite(); bounds = bounds.expand(point)
				diameter = maxf(diameter,bounds.size.length()*sk.global_basis.get_scale().x)
		check(finite and speed < 25 and diameter < 4,"ragdoll acotado: "+name)
		check(lengths,"ragdoll conserva longitudes y escalas del rig: "+name)
		print("ROBOT_METRICS ",name," speed=",speed," diameter=",diameter," bodies=",game.physical_ragdoll.bodies.size())
		game.physical_ragdoll.stop(true); await frames(25)
		check(not game.physical_ragdoll.active and game.player.position.y >= -.01 and game.player.is_on_floor(),"recuperación: "+name)
	var last: int = game.robots.index; var changed := true
	game.robots.rng.seed = 124
	for i in range(8):
		game.respawn_player(); changed = changed and game.robots.index != last; last = game.robots.index; await frames(2)
	check(changed,"ocho reapariciones cambian chasis")
	game.robots.select(0); await frames(30)
	check(not game.robots.active and game.rig_holder.visible and game.visual_motion.find_skeleton(game.rig_scene) == original,"restaura Naoya con rig original")
	game.feedback.stop_all(); OS.delay_msec(150); game.queue_free(); await process_frame; await process_frame
	print("RESULTADO %d/%d" % [checks-failures,checks]); quit(1 if failures else 0)

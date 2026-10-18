extends SceneTree
var game: Node3D
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func verify(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+description)
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func release_inputs() -> void:
	for name in ["left","right","forward","back","block","attack","jump","dash"]: Input.action_release(name)
func reset() -> void:
	release_inputs()
	game.set_paused(false)
	game.reset_lab()
	game.preferences.values.hold_attack = false
	game.yaw = 0
	game.camera_lock = false
	for i in range(game.enemies.size()):
		game.enemies[i].kind = 0
		game.enemies[i].body.position = Vector3(30+i*4,0.05,30)
	await frames(12)
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await reset()
	var sk: Skeleton3D = game.visual_motion.skeleton
	var calf := sk.find_bone("B_R_Calf")
	var arm := sk.find_bone("B_R_UpperArm")
	Input.action_press("block")
	Input.action_press("forward")
	await frames(35)
	verify(game.block and game.player.velocity.length() > 2,"guardia conserva desplazamiento real")
	var before := sk.get_bone_pose_rotation(calf)
	await frames(15)
	verify(before.angle_to(sk.get_bone_pose_rotation(calf)) > 0.02,"piernas siguen animándose al caminar con guardia")
	verify(float(game.locomotion_tree.get("parameters/Cadence/scale")) < 0.5,"cadencia acompaña velocidad lenta de guardia")
	for action in ["back","left","right"]:
		Input.action_release("forward"); Input.action_release("back"); Input.action_release("left"); Input.action_release("right")
		Input.action_press(action)
		await frames(25)
		verify(game.block and game.locomotion_tree.active,"guardia camina hacia "+action)
	Input.action_release("block")
	before = sk.get_bone_pose_rotation(arm)
	await frames(1)
	verify(before.angle_to(sk.get_bone_pose_rotation(arm)) < 0.55,"salir de guardia no corta la pose del brazo")
	await reset()
	for name in ["Melee_Hook","Melee_Hook_Rec","Idle_FoldArms_Loop","Yes"]:
		var clip: Animation = game.rig_anim.get_animation("ual2/"+name)
		verify(clip != null and clip.get_track_count() == 54,"clip UAL2 adaptado: "+name)
		var finite := true
		for track in range(clip.get_track_count()):
			if clip.track_get_type(track) != Animation.TYPE_ROTATION_3D: continue
			for key in range(clip.track_get_key_count(track)):
				var q: Quaternion = clip.track_get_key_value(track,key)
				finite = finite and q.is_finite() and absf(q.length()-1) < 0.001
		verify(finite,"rotaciones válidas sin escala ni deformación de reposo: "+name)
	var lengths := {"RightJab":0.32,"LeftJab":0.32,"Hook":0.32,"Finisher":0.38,"Uppercut":0.38,"Downslam":0.38,"Kick":0.59}
	for name in lengths:
		verify(is_equal_approx(game.rig_anim.get_animation("combat/"+name).length,lengths[name]),"ventana visual conservada: "+name)
	game.combo = 2
	game.combo_timeout = 0.9
	game.punch()
	await frames(2)
	verify(game.rig_current_anim == &"combat/Hook","tercer M1 utiliza el hook nuevo en combate real")
	await reset()
	game.start_form("FORM2",true)
	await frames(120)
	var model: Node3D = game.presentation.form_models[1]
	verify((-model.global_basis.z).normalized().dot(Vector3.UP) > 0.99,"fase2 en reposo vertical, cabeza arriba")
	verify(model.global_basis.x.normalized().dot(game.facing_forward()) > 0.99,"cara de fase2 hacia delante en reposo")
	Input.action_press("forward")
	await frames(50)
	verify(absf(model.global_basis.z.normalized().dot(Vector3.UP)) < 0.03,"fase2 se vuelve horizontal al desplazarse")
	verify((-model.global_basis.z).normalized().dot(game.facing_forward()) > 0.99,"cabeza, no cola, sigue avance al moverse")
	Input.action_release("forward")
	await frames(50)
	verify((-model.global_basis.z).normalized().dot(Vector3.UP) > .98,"detenerse recupera reposo vertical solicitado en0.9.6")
	await reset()
	var enemy: Dictionary = game.enemies[0]
	enemy.body.position = game.player.position+Vector3(0,0,-2)
	await frames(2)
	game.moves.freeze_enemy(enemy,5.0)
	var pane: Node3D = enemy.projection_frame
	verify(enemy.projection_freeze == 5.0,"fotograma conserva inmovilización de cinco segundos")
	verify(pane.capture_requested and pane.capture_viewport.own_world_3d,"captura de pose en World3D independiente")
	verify(pane.portrait.mesh is QuadMesh and not enemy.rig_holder.visible,"representación sustituida por un plano y el actor 3D oculto")
	verify(pane.pane.get_child_count() == 1,"panel original sin marcos ni fragmentos añadidos")
	var glass: MeshInstance3D = pane.pane.get_child(0)
	verify(glass.material_override is ShaderMaterial,"Material Override aplicado al MeshInstance3D importado")
	verify(is_equal_approx(glass.material_override.get_shader_parameter("transparency"),0.04),"centro del vidrio con transparencia solicitada")
	var origin: Vector3 = enemy.body.position
	await frames(295)
	verify(enemy.projection_freeze > 0 and enemy.body.position.is_equal_approx(origin),"NPC inmóvil hasta la parte final de los cinco segundos")
	await frames(10)
	verify(enemy.projection_freeze == 0 and enemy.rig_holder.visible and enemy.rig_anim.active,"liberación restaura modelo y animación del NPC")
	verify(not is_instance_valid(pane),"captura, viewport y panel eliminados al finalizar")
	await reset()
	enemy = game.enemies[0]
	game.moves.freeze_enemy(enemy,5)
	pane = enemy.projection_frame
	await frames(10)
	var prior_remaining: float = enemy.projection_freeze
	game.moves.freeze_enemy(enemy,1)
	await frames(2)
	verify(not is_instance_valid(pane) and enemy.projection_freeze > prior_remaining-0.1,"repetir fotograma libera captura anterior y conserva duración mayor")
	game.reset_enemy(enemy)
	await frames(2)
	verify(enemy.projection_frame == null and enemy.rig_holder.visible and enemy.rig_anim.active,"reiniciar NPC atrapado restaura representación y animación")
	game.moves.freeze_enemy(enemy,5)
	enemy.hp = 0
	await frames(2)
	verify(enemy.projection_frame == null and enemy.projection_freeze == 0 and enemy.rig_holder.visible,"muerte de NPC atrapado limpia su fotograma")
	await reset()
	game.moves.freeze_player(5.0)
	pane = game.moves.player_frame
	verify(game.moves.player_freeze == 5.0 and not game.can_start_action(),"fotograma del jugador impide iniciar acciones")
	origin = game.player.position
	Input.action_press("forward")
	Input.action_press("jump")
	game.start_dash(); game.punch(); game.moves.press(4)
	await frames(120)
	verify(game.player.position.is_equal_approx(origin) and game.dash_time <= 0 and game.skill_active == "","moverse, saltar, dash y habilidad bloqueados durante captura")
	var remaining: float = game.moves.player_freeze
	game.set_paused(true)
	await frames(10)
	verify(is_equal_approx(game.moves.player_freeze,remaining),"pausa conserva el tiempo restante del fotograma")
	game.set_paused(false)
	verify(not game.rig_anim.active,"reanudar no libera la pose antes de tiempo")
	await frames(190)
	verify(game.moves.player_freeze == 0 and game.rig_holder.visible and game.player.position.distance_to(origin) > 0.1,"al liberar el jugador recupera 3D y movimiento")
	verify(not is_instance_valid(pane),"fotograma del jugador no deja recursos residuales")
	await reset()
	game.moves.freeze_player(5)
	game.reset_lab()
	await frames(3)
	verify(game.moves.player_freeze == 0 and game.rig_holder.visible,"reinicio del laboratorio limpia un fotograma activo")
	game.start_form("FORM2",true)
	await frames(120)
	game.moves.freeze_player(5)
	pane = game.moves.player_frame
	verify(pane.photo_size.y >= pane.PHOTO_SIZE.y and not game.moves.curse.visible,"fotograma encuadra fase2 horizontal y oculta 3D")
	await frames(10)
	game.moves.clear_player_frame()
	verify(game.moves.curse.visible,"liberar fase2 recupera representación 3D")
	await reset()
	game.presentation.toggle_kogane()
	verify(game.presentation.companion.get_node_or_null("SkullWisp") != null,"Skull Wisp sustituye a Kogane")
	game.charge = 100
	await frames(2)
	verify(game.presentation.companion_message.contains("Transformación lista"),"Kogane avisa de transformación disponible")
	game.charge = 0; game.hp = 25
	await frames(2)
	verify(game.presentation.companion_message == "Vida baja","Kogane reacciona a vida real baja")
	game.hp = 100
	game.moves.freeze_player(5)
	await frames(2)
	verify(game.presentation.companion_message.contains("Fotograma"),"Kogane muestra el tiempo de inmovilización real")
	game.moves.clear_player_frame()
	await reset()
	game.start_form("FORM2",true)
	await frames(120)
	game.moves.begin_domain()
	verify(is_instance_valid(game.moves.domain_exterior),"dominio despliega barrera en el mundo exterior")
	var floor_body: StaticBody3D = game.moves.domain_arena.get_node("CircularDomainFloor")
	verify(floor_body.get_child(0).mesh is CylinderMesh and floor_body.get_child(1).shape is CylinderShape3D,"suelo circular coincide con su colisión")
	verify(is_instance_valid(game.moves.domain_arena.get_node("CircularDomainBoundary")),"límite circular con colisiones reales")
	game.player.position = game.moves.domain_center+Vector3(6.3,0.1,6.3)
	game.player.reset_physics_interpolation()
	await frames(15)
	verify(game.player.is_on_floor(),"suelo sostiene al jugador cerca del borde diagonal")
	verify(game.presentation.companion_message.contains("Dominio"),"Kogane cuenta el tiempo del dominio activo")
	game.start_form("FORM1",true)
	await frames(2)
	verify(game.moves.domain_time == 0 and game.moves.domain_arena == null and game.moves.domain_exterior == null,"salir de fase2 limpia interior y barrera exterior")
	await reset()
	game.moves.freeze_player(5)
	pane = game.moves.player_frame
	if DisplayServer.get_name() == "headless":
		print("SKIP imagen y transparencia: renderer Dummy no genera píxeles")
	else:
		await frames(5)
		verify(pane.image_ready,"captura 2D renderizada")
		if pane.image_ready:
			var image: Image = pane.portrait.material_override.albedo_texture.get_image()
			var solid := 0; var clear := 0
			for y in range(0,image.get_height(),4):
				for x in range(0,image.get_width(),4):
					var pixel := image.get_pixel(x,y)
					if pixel.a < 0.05: clear += 1
					if pixel.a > 0.5 and pixel.r+pixel.g+pixel.b > 0.1: solid += 1
			verify(clear > 50 and solid > 50,"textura contiene pose visible y fondo transparente")
			image.save_png("res://qa/captura_pose_v094.png")
	game.moves.clear_player_frame()
	game.feedback.stop_all()
	release_inputs()
	print("RESULTADO %d/%d" % [checks-failures,checks])
	OS.delay_msec(100) # Dejar que el mezclador de audio libere sus voces detenidas.
	game.queue_free()
	await process_frame; await process_frame
	quit(1 if failures else 0)

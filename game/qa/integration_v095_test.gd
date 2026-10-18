extends SceneTree
var game: Node3D
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func verify(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",description)
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func isolate() -> void:
	game.reset_lab()
	for i in range(game.enemies.size()):
		game.set_dummy_mode(game.enemies[i],0)
		game.enemies[i].body.position = Vector3(35+i*4,.05,35)
	await frames(45)
func run() -> void:
	game = load("res://main.tscn").instantiate(); root.add_child(game)
	await isolate()
	verify(game.rig_anim.has_animation("mixamo/idle"),"standing real: idle.fbx importado y adaptado")
	var tree: AnimationNodeBlendTree = game.locomotion_tree.tree_root
	verify(tree.get_node("Idle").animation == &"mixamo/idle","reposo utiliza idle del paquete del usuario")
	verify(tree.has_node("Gait") and tree.has_node("Walk"),"mezcla direccional caminar/correr conserva guardia")
	verify(game.physical_ragdoll.initialized,"ragdoll preparado en jugador sin rehacer pesos")
	verify(game.physical_ragdoll.bodies[0].collision_layer == 0,"física desactivada no bloquea rayos de habilidades")
	var sk: Skeleton3D = game.visual_motion.skeleton
	for name in ["mixamo/idle","mixamo/running","mixamo/walking","mixamo/jump","mixamo/Falling","combat/MixamoCross","combat/MixamoElbow"]:
		game.locomotion_tree.active = false; game.rig_anim.play(name); game.rig_anim.seek(.25,true)
		sk.force_update_all_bone_transforms()
		var finite := true
		for i in range(sk.get_bone_count()): finite = finite and sk.get_bone_global_pose(i).origin.is_finite()
		verify(finite,"pose finita: "+name)
	await isolate()
	game.player.position.y = 500; game.player.velocity = Vector3(0,-1,0)
	await frames(235)
	verify(game.descending_time < 4 and game.rig_current_anim != &"mixamo/Falling","Falling no se activa antes de cuatro segundos")
	await frames(10)
	verify(game.descending_time >= 4 and game.rig_current_anim == &"mixamo/Falling","Falling activa tras caída continua real de cuatro segundos")
	var play_time: float = game.rig_anim.current_animation_position
	await frames(12)
	verify(game.rig_anim.current_animation_position > play_time,"Falling avanza sin reiniciar cada fotograma")
	game.player.position = Vector3(0,.05,5); game.player.velocity = Vector3.ZERO
	await frames(20)
	verify(game.descending_time == 0 and game.rig_current_anim != &"mixamo/Falling","aterrizar reinicia contador y recuperación")
	await isolate()
	var npc: Dictionary = game.enemies[0]
	npc.body.position = game.player.position+Vector3(0,0,-1.2)
	game.combo = 1; game.combo_timeout = .8; game.punch()
	verify(game.punch_visual == "combat/MixamoCross","segundo M1 selecciona Cross sin cambiar daño")
	game.attack_cd = 0; game.attack_anim = 0; game.punch()
	verify(game.punch_visual == "combat/MixamoElbow","tercer M1 usa codo sólo a corta distancia")
	game.cancel_skill(); game.attack_anim = 0; game.start_skill4()
	verify(game.kick_visual == "mixamo/Kick_To_The_Groin","patada cercana usa FBX nuevo con duración compatible")
	await isolate()
	npc.body.position = Vector3(0,.05,-5)
	game.perform_hit(npc,12,0,Vector3.FORWARD,3,2,.6,1.2)
	await frames(6)
	verify(npc.physics.active and npc.physics.simulator.is_simulating_physics(),"impacto activa ragdoll físico del bandido")
	verify(not npc.rig_anim.active,"animador no compite con física")
	await frames(110)
	verify(not npc.physics.active and npc.rig_anim.active and npc.hp > 0,"bandido recupera control tras derribo")
	game.player_ragdoll = true; game.player_ragdoll_time = .8; game.player.velocity = Vector3(2,2,0)
	await frames(4)
	verify(game.physical_ragdoll.active and not game.rig_anim.active,"jugador activa física y suspende animaciones")
	game.set_paused(true)
	var paused_positions: Array[Vector3] = []
	for bone in game.physical_ragdoll.bodies: paused_positions.append(bone.global_position)
	await frames(30)
	var stable := true
	for i in range(paused_positions.size()): stable = stable and game.physical_ragdoll.bodies[i].global_position.distance_to(paused_positions[i]) < .001
	verify(stable,"menú pausa posiciones físicas del ragdoll")
	game.set_paused(false)
	verify(not game.rig_anim.active,"reanudar menú no reactiva animador durante ragdoll")
	await frames(70)
	verify(not game.physical_ragdoll.active and game.rig_anim.active,"jugador recupera controlador y animaciones")
	await isolate()
	game.presentation.toggle_kogane()
	var wing: int = game.presentation.kogane_skeleton.find_bone("WingL")
	var before: Quaternion = game.presentation.kogane_skeleton.get_bone_pose_rotation(wing)
	await frames(8)
	verify(not before.is_equal_approx(game.presentation.kogane_skeleton.get_bone_pose_rotation(wing)),"aleteo modifica hueso real con pesos de ala")
	game.toggle_enemy_gallery()
	verify(game.gallery.records.size() == 6,"seis variantes simultáneas del mismo modelo")
	var meshes: Array = []
	for record in game.gallery.records:
		var mesh: MeshInstance3D = game.appearance.meshes(record.scene)[0]
		meshes.append(mesh)
		verify(record.palette == meshes.size()-1,"apariencia forzada reproducible "+str(record.palette))
	verify(meshes[0].mesh == meshes[5].mesh,"geometría compartida entre variantes")
	verify(meshes[0].material_override != meshes[1].material_override,"materiales independientes por enemigo")
	var second: Color = meshes[1].material_override.get_shader_parameter("jacket")
	meshes[0].material_override.set_shader_parameter("jacket",Color.YELLOW)
	verify(meshes[1].material_override.get_shader_parameter("jacket") == second,"recolorar uno no modifica a los demás")
	var skins := []
	for mesh in meshes: skins.append(mesh.material_override.get_shader_parameter("skin"))
	verify(skins[0] != skins[1] or skins[1] != skins[2],"piel independiente con tonos naturales")
	var sk_enemy: Skeleton3D = game.visual_motion.find_skeleton(npc.rig_scene)
	verify(sk_enemy.get_bone_count() == 53 and npc.rig_anim.get_animation_list().size() >= 60,"bandido rig compatible y animaciones existentes conservadas")
	var id: String = npc.appearance.id
	game.randomize_enemy_appearances(game.appearance_seed)
	verify(npc.appearance.id == id,"semilla reproduce identidad de aparición inicial")
	npc.hp = 0; game.reset_enemy(npc)
	verify(npc.appearance_generation == 1 and npc.appearance.id != id,"reaparición asigna otra combinación reproducible")
	verify(npc.appearance.palette != game.enemies[1].appearance.palette and npc.appearance.palette != game.enemies[2].appearance.palette,"reaparición evita duplicar paleta existente en el grupo")
	var mask: Image = load("res://assets/enemies/y2k/textures/regions_a.png").get_image()
	var regions: Array[int] = [0,0,0,0]
	for y in range(0,mask.get_height(),8):
		for x in range(0,mask.get_width(),8):
			var pixel := mask.get_pixel(x,y)
			for i in range(4):
				if pixel[i] > .8: regions[i] += 1
	verify(regions.min() > 15,"máscara RGBA importada conserva canales de ropa sin premultiplicar")
	var details: Image = load("res://assets/enemies/y2k/textures/regions_b.png").get_image()
	var detail_counts: Array[int] = [0,0,0]
	for y in range(0,details.get_height(),8):
		for x in range(0,details.get_width(),8):
			var pixel := details.get_pixel(x,y)
			for i in range(3):
				if pixel[i] > .8: detail_counts[i] += 1
	verify(detail_counts.min() > 15,"máscara de zapatillas, pelo y piel conserva tres regiones")
	await isolate()
	game.start_form("FORM2",true); game.presentation.transition_time = 0; game.moves.begin_domain()
	verify(game.domain_inspector.toggle(),"inspector exterior se activa con dominio real")
	game.domain_inspector.elevation = 1.4; game.domain_inspector.update(0)
	verify(game.domain_inspector.camera.global_position.y > 20,"vista superior distingue volumen")
	var exterior: SphereMesh = game.moves.domain_exterior.get_child(0).mesh
	verify(is_equal_approx(exterior.height,exterior.radius*2),"barrera es esfera con diámetro consistente")
	game.domain_inspector.toggle()
	verify(game.camera.current and not game.domain_inspector.active and game.moves.domain_time > 0,"salir del inspector conserva dominio y cámara normal")
	print("RESULTADO %d/%d" % [checks-failures,checks])
	game.feedback.stop_all(); OS.delay_msec(100)
	game.queue_free(); await process_frame; await process_frame; quit(1 if failures else 0)

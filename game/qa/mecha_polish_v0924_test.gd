extends SceneTree
## Physical joints, paused debris, first-person cannon and imported phase-2 axes.
var game: Node3D
var checks := 0
var passed := 0
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func check(ok: bool, title: String) -> void:
	checks += 1
	if ok: passed += 1
	print("PASS " if ok else "FAIL ",title)
func run() -> void:
	game = load("res://main.tscn").instantiate();root.add_child(game);await frames(20)
	for enemy in game.enemies: game.set_dummy_mode(enemy,0)
	game.set_physics_process(false)
	game.form = "FORM2"
	for i in range(100): game.presentation.animate_phase2(.016,0)
	var basis: Basis = game.presentation.form_models[1].basis.orthonormalized()
	check((basis*Vector3.FORWARD).dot(Vector3.UP)>.99,"fase 2 en reposo: cabeza hacia arriba")
	check((basis*Vector3.RIGHT).dot(Vector3.FORWARD)>.99,"fase 2 en reposo: cara hacia delante")
	for i in range(100): game.presentation.animate_phase2(.016,5)
	basis = game.presentation.form_models[1].basis.orthonormalized()
	check((basis*Vector3.FORWARD).dot(Vector3.FORWARD)>.99,"fase 2 en movimiento: cabeza hacia avance")
	check((basis*Vector3.RIGHT).dot(Vector3.DOWN)>.99,"fase 2 en movimiento: cara hacia el suelo")
	game.form = "BASE";game.set_physics_process(true)
	game.robots.select(1);game.player.position=Vector3(0,.1,0);game.player.velocity=Vector3.ZERO;await frames(20)
	game.charge=100;check(game.fusion.request(),"fusión de producción inicia")
	game.fusion.sequence.advance(11.5);await frames(35)
	game.zoom=0;game.camera_lock=true;game.yaw=game.model.rotation.y;game.pitch=-.18
	game.update_camera(.016)
	var eye_before: Vector3=game.camera.global_position
	check(game.fusion.combat.press(1),"cañón se mantiene en primera persona")
	await frames(65)
	var rig: Node3D=game.fusion.sequence.articulation
	check(game.camera_view.cannon_view_weight>.9,"cámara acompaña despliegue completo")
	check(game.camera.global_position.distance_to(eye_before)>.2,"encuadre de cañón difiere del reposo")
	var visible_points := 0
	for mesh in rig.pivots.BrazoSuperior_Der.find_children("*","MeshInstance3D",true,false):
		if not mesh.is_visible_in_tree():continue
		var box: AABB=mesh.get_aabb()
		for corner in range(8):
			if game.camera.is_position_in_frustum(mesh.global_transform*box.get_endpoint(corner)):visible_points+=1
	check(visible_points>0,"geometría del brazo del cañón entra en frustum real")
	var outside := true
	for region in ["Torso_Pecho","Torso_Abdomen","Pelvis"]:
		for mesh in rig.groups.get(region,[]):
			if mesh.is_visible_in_tree() and (mesh.global_transform*mesh.get_aabb()).has_point(game.camera.global_position):outside=false
	check(outside,"ojo del piloto permanece fuera del torso")
	game.fusion.combat.interrupted();await frames(8)
	var damage: Node3D=game.fusion.damage
	damage.detach(0);await frames(2)
	check(damage.bodies.has(0) and damage.forearms.has(0) and damage.hinges.has(0),"brazo desprendido conserva dos segmentos articulados")
	var upper: RigidBody3D=damage.bodies[0];var lower: RigidBody3D=damage.forearms[0];var joint: HingeJoint3D=damage.hinges[0]
	var anchor: Vector3=joint.global_position
	var a: Vector3=upper.to_local(anchor);var b: Vector3=lower.to_local(anchor);var worst := 0.0
	for i in range(180):
		await frames(1);worst=maxf(worst,upper.to_global(a).distance_to(lower.to_global(b)))
	check(worst<.20,"codo físico mantiene unión durante caída (%.3f m)"%worst)
	check(upper.global_position.y>-.5 and lower.global_position.y>-.5,"ambos segmentos descansan sobre suelo")
	check(upper.get_collision_exceptions().has(game.player) and lower.get_collision_exceptions().has(game.player),"restos no chocan con el controlador")
	game.set_paused(true);var at: Transform3D=upper.global_transform;var bt: Transform3D=lower.global_transform;await frames(30)
	check(upper.freeze and lower.freeze and upper.global_transform.is_equal_approx(at) and lower.global_transform.is_equal_approx(bt),"pausa congela ambos cuerpos del brazo")
	game.set_paused(false);await frames(2)
	check(not upper.freeze and not lower.freeze,"reanudar devuelve simulación física")
	var sparks: Node=damage.sockets[0].find_child("LiveSparks",true,false)
	check(sparks is CPUParticles3D and sparks.emitting and sparks.speed_scale>0,"muñón emite chispas en renderizador Compatibility")
	game.queue_free();await frames(12)
	print("RESULTADO ",passed,"/",checks);quit(0 if passed==checks else 1)

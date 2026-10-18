extends SceneTree
var game: Node3D
var rig: Node3D
var checks := 0
var passed := 0
var samples: Array = []
var worst_error := 0.0
var stance_error := 0.0
var max_queries := 0
var feet_contacts := 0
var worst_length_error := 0.0
var errors: Dictionary = {}
func _initialize() -> void: run.call_deferred()
func check(ok: bool,title: String) -> void:
	checks += 1
	if ok: passed += 1
	print("PASS " if ok else "FAIL ",title)
func frames(n: int, label: String = "") -> void:
	for i in range(n):
		await physics_frame
		if not is_instance_valid(rig) or not rig.gait.initialized: continue
		max_queries = maxi(max_queries,rig.gait.queries_frame)
		for side in ["Der","Izq"]:
			var f: Dictionary = rig.gait.feet[side]
			var length_scale: float = rig.global_basis.y.length()
			var upper: float = rig.pivots["Muslo_"+side].global_position.distance_to(rig.pivots["Rodilla_"+side].global_position)
			var lower: float = rig.pivots["Rodilla_"+side].global_position.distance_to(rig.pivots["Pie_"+side].global_position)
			worst_length_error = maxf(worst_length_error,absf(upper-rig.rest_positions["Rodilla_"+side].length()*length_scale))
			worst_length_error = maxf(worst_length_error,absf(lower-(rig.rest_positions["Pantorrilla_"+side]+rig.rest_positions["Pie_"+side]).length()*length_scale))
			var error: float = rig.pivots["Pie_"+side].global_position.distance_to(f.point)
			if f.valid and rig.procedural_blend>.99:
				worst_error=maxf(worst_error,error)
				if not f.swing: stance_error=maxf(stance_error,error)
			if not label.is_empty() and i%5==0: samples.append({"case":label,"time":game.clock,"side":side,"swing":f.swing,"x":f.point.x,"y":f.point.y,"z":f.point.z,"error":error,"queries":rig.gait.queries_frame,"speed":game.player.velocity.length(),"body_y":game.player.position.y,"hip":rig.pivots["Muslo_"+side].global_position,"root":rig.procedural_root,"progress":f.t})
func floor_box(at: Vector3, size: Vector3, angle: float = 0.0) -> StaticBody3D:
	var body:=StaticBody3D.new();game.add_child(body);body.position=at;body.rotation.x=angle;body.collision_layer=1;body.collision_mask=0
	var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;col.shape=shape;body.add_child(col);return body
func release() -> void:
	for action in ["forward","back","left","right","walk","ability1"]:Input.action_release(action)
func relocate(point: Vector3) -> void:
	release();game.player.position=point;game.player.velocity=Vector3.ZERO;game.yaw=0;game.model.rotation.y=0;game.camera_lock=true;rig.gait.clear();await frames(20)
func run() -> void:
	game=load("res://main.tscn").instantiate();root.add_child(game)
	for i in range(12):await physics_frame
	for e in game.enemies:game.set_dummy_mode(e,0)
	game.robots.select(1);game.charge=100;game.player.position=Vector3(-16,.1,0)
	for i in range(12):await physics_frame
	check(game.fusion.request(),"fusión original inicia para probar locomoción")
	game.fusion.sequence.advance(11.5);rig=game.fusion.sequence.articulation
	floor_box(Vector3(200,-.1,0),Vector3(40,.2,50))
	await relocate(Vector3(200,.03,5));await frames(45,"idle")
	check(rig.gait.initialized and rig.gait.feet.Der.valid and rig.gait.feet.Izq.valid,"ambos pies encuentran suelo real")
	var fixed:Vector3=rig.gait.feet.Der.point;var initial_steps:int=rig.gait.steps
	await frames(60,"idle")
	check(rig.gait.feet.Der.point.distance_to(fixed)<.001 and rig.gait.steps==initial_steps,"reposo conserva apoyo sin pasos falsos")
	Input.action_press("walk");Input.action_press("forward");var origin:Vector3=game.player.position
	await frames(240,"walk");release()
	check(game.player.position.distance_to(origin)>3.3,"caminar conserva desplazamiento real del controlador")
	check(rig.gait.steps-initial_steps>=4,"caminar genera contactos alternos reales")
	var walk_steps:int=rig.gait.steps;await frames(65,"stop")
	var stop_steps:int=rig.gait.steps;await frames(60,"stop_idle")
	check(rig.gait.steps==stop_steps,"frenada se asienta y deja de producir pasos")
	await relocate(Vector3(200,.03,8));initial_steps=rig.gait.steps;Input.action_press("forward");origin=game.player.position
	await frames(240,"run");release()
	check(game.player.position.distance_to(origin)>7.5 and rig.state=="run","correr usa la velocidad y no modifica estadísticas")
	check(rig.gait.steps-initial_steps>=6,"correr conserva alternancia y frecuencia mayor")
	await frames(90)
	for action in ["left","right","back"]:
		Input.action_press(action);await frames(90,action);Input.action_release(action);await frames(45)
		check(rig.gait.initialized and rig.gait.feet.Der.valid and rig.gait.feet.Izq.valid,"apoyos en dirección "+action)
	var old_queries:int=rig.gait.queries_total
	game.fusion.combat.cooldowns[0]=0;Input.action_press("ability1");game.fusion.combat.press(1);Input.action_press("forward")
	await frames(100,"cannon_walk")
	check(rig.gait.initialized and rig.deployment>.99 and game.fusion.combat.cannon_phase=="hold","caminar procedural no impide apuntar el cañón")
	release();game.fusion.combat.release_cannon();await frames(85)
	game.fusion.combat.interrupted();game.fusion.combat.cooldowns=[0.,0.,0.,0.]
	game.fusion.combat.press(3);await frames(10)
	check(not rig.gait.initialized,"pisotón conserva pose especial y libera los apoyos")
	game.fusion.combat.interrupted();await frames(60)
	check(rig.gait.initialized,"recupera apoyos al terminar la habilidad")
	floor_box(Vector3(250,-.15,0),Vector3(14,.3,22),deg_to_rad(8))
	await relocate(Vector3(250,.3,0));Input.action_press("walk");Input.action_press("forward");await frames(180,"slope");release()
	check(rig.gait.feet.Der.normal.y<.999 and rig.gait.feet.Der.normal.y>.95,"pies detectan normal de pendiente real")
	check(rig.pivots.Pie_Der.global_basis.y.normalized().dot(rig.gait.feet.Der.normal)>.995,"pie se nivela con la pendiente")
	floor_box(Vector3(300,-.1,0),Vector3(16,.2,38))
	floor_box(Vector3(300,.1,-7),Vector3(12,.2,8))
	floor_box(Vector3(300,.3,-14),Vector3(12,.2,6))
	await relocate(Vector3(300,.03,1));Input.action_press("forward");await frames(420,"steps");release()
	check(game.player.position.z < -10 and game.player.position.y>.18,"locomoción conserva subida de escalones del controlador")
	await relocate(Vector3(200,.03,5));game.player.position+=Vector3(8,0,0);await frames(20)
	check(rig.gait.feet.Der.point.distance_to(game.player.global_position)<2.2,"teletransporte reinicia apoyos sin estirar piernas")
	game.preferences.values.procedural_gait = false; await frames(4)
	check(not rig.gait.initialized,"opción A/B recupera locomoción anterior")
	game.preferences.values.procedural_gait = true; await frames(15)
	check(rig.gait.initialized,"opción A/B reactiva los apoyos")
	# Plataforma real: el CharacterBody recibe su velocidad de suelo.
	var platform:=AnimatableBody3D.new();platform.sync_to_physics=false;game.add_child(platform);platform.position=Vector3(350,1,0);platform.collision_layer=1
	var platform_col:=CollisionShape3D.new();var platform_shape:=BoxShape3D.new();platform_shape.size=Vector3(12,.4,12);platform_col.shape=platform_shape;platform.add_child(platform_col)
	await relocate(Vector3(350,1.25,0));await frames(30)
	print("PLATFORM_DIAG ",platform.global_position," ",game.player.position," floor=",game.player.is_on_floor()," gait=",rig.gait.initialized)
	check(rig.gait.initialized,"se establece apoyo sobre plataforma física")
	if not rig.gait.initialized: game.queue_free(); await process_frame; print("RESULTADO ",passed,"/",checks); quit(1); return
	var relative:Vector3=rig.gait.feet.Der.point-platform.global_position
	for i in range(60):
		platform.position.y += .003
		await frames(1,"platform")
	check((rig.gait.feet.Der.point-platform.global_position).distance_to(relative)<.01,"apoyo acompaña plataforma móvil sin patinar")
	check(game.player.position.y>1.32,"controlador sube con la plataforma física")
	await relocate(Vector3(200,.03,5))
	var wall:=floor_box(Vector3(200,2,0),Vector3(10,4,.3))
	Input.action_press("forward");await frames(180);var quiet_steps:int=rig.gait.steps;await frames(90);release()
	check(rig.gait.steps==quiet_steps,"contra una pared no continúa caminando en el sitio")
	wall.queue_free();await frames(10)
	game.dash_cd=0;game.fusion.start_boost();await frames(12)
	check(not rig.gait.initialized,"despegue libera la IK del suelo")
	await frames(150)
	check(rig.gait.initialized and game.player.is_on_floor(),"aterrizaje recupera apoyos y control")
	await relocate(Vector3(200,.03,5))
	var turn_contacts: int = game.fusion.step_index
	game.yaw=PI*.5;await frames(100,"turn")
	check(game.fusion.step_index>turn_contacts,"giro en reposo recoloca pies y reproduce contactos reales")
	var boot_angle:float=absf(rig.global_basis.z.signed_angle_to(rig.pivots.Pie_Der.global_basis.z,Vector3.UP))
	check(boot_angle<.62,"tobillos mantienen límite de giro visual")
	check(worst_length_error<.002,"huesos mecánicos conservan longitud, sin separación ni estiramiento")
	check(rig.joint_caps.multimesh.instance_count==6 and rig.joint_caps.multimesh.mesh.get_surface_count()==1,"seis juntas interiores comparten una superficie")
	print("JOINT_TRIANGLES ",rig.joint_caps.multimesh.mesh.get_faces().size()/3*6)
	game.zoom=0;game.update_camera(.016)
	check(rig.joint_caps.layers & game.camera.cull_mask != 0,"juntas y cuerpo conservados en primera persona")
	game.zoom=5.5;game.update_camera(.016)
	check(rig.joint_caps.layers == 1,"juntas restauradas en tercera persona")
	check(max_queries<=2,"presupuesto máximo de dos rayos por actualización")
	print("LOCOMOTION_METRICS ",JSON.stringify({"worst_error_m":worst_error,"stance_error_m":stance_error,"queries_max_frame":max_queries,"steps":rig.gait.steps,"samples":samples.size()}))
	check(stance_error<.055,"pies plantados mantienen error menor de 5,5 cm")
	var dir:=OS.get_environment("NAOYA_QA_OUTPUT")
	if not dir.is_empty():
		DirAccess.make_dir_recursive_absolute(dir)
		var file:=FileAccess.open(dir.path_join("locomotion_trace.json"),FileAccess.WRITE);file.store_string(JSON.stringify(samples))
	game.fusion.reset();game.queue_free();await frames(8);await process_frame
	print("RESULTADO ",passed,"/",checks);quit(0 if passed==checks else 1)

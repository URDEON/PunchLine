extends SceneTree
var game: Node3D
var passed := 0
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,text: String) -> void:
	checks += 1
	if ok: passed += 1
	print("PASS " if ok else "FAIL ",text)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func box(point: Vector3,size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new(); game.add_child(body);body.position = point;body.collision_layer = 1
	var shape := CollisionShape3D.new();var resource := BoxShape3D.new();resource.size = size;shape.shape = resource;body.add_child(shape)
	return body
func run() -> void:
	game = load("res://main.tscn").instantiate();root.add_child(game); await frames(15)
	for e in game.enemies: game.set_dummy_mode(e,0)
	box(Vector3(400,-.1,0),Vector3(100,.2,100))
	game.robots.select(1)
	for variant in range(4):
		game.robots.forced = variant;game.robots.spawn();game.player.position = Vector3(400,.025,0);game.player.velocity = Vector3.ZERO
		await frames(25)
		var title: String = game.robots.NAMES[variant]
		var col: CollisionShape3D = game.robots.naoya.collision
		var radius: float = col.shape.radius
		var roof := box(Vector3(400,1.65,0),Vector3(7,.2,7))
		await frames(35)
		check(col.shape.height < 1.55 and game.robot_clearance.blend > .5,"cápsula se agacha: "+title)
		check(is_equal_approx(radius,col.shape.radius),"agachado conserva ancho: "+title)
		check(absf(col.position.y-col.shape.height*.5)<.001 and game.player.position.y > -.03,"base no se hunde: "+title)
		var rig: Skeleton3D = game.robots.current.skeleton
		var finite := true
		for i in range(rig.get_bone_count()): finite = finite and rig.get_bone_global_pose(i).is_finite()
		check(finite and not game.robots.current.procedural.pose_cache.is_empty(),"postura procedural finita y replicable: "+title)
		var height: float = col.shape.height
		game.player.velocity = Vector3.ZERO; await frames(25)
		check(col.shape.height <= height+.02,"no se levanta bajo techo: "+title)
		roof.queue_free();await frames(40)
		check(col.shape.height > 1.98,"recupera postura: "+title)
		# Force a respawn with the SAME chassis and collider radius.
		game.robots.spawn();game.player.position = Vector3(400,.025,0);await frames(15)
		roof = box(Vector3(400,1.65,0),Vector3(7,.2,7));await frames(35)
		check(game.robots.naoya.collision.shape.height < 1.55,"nueva cápsula tras respawn: "+title)
		roof.queue_free();await frames(40)
	game.dash_cd = 0;game.start_dash();var cooldown: float = game.dash_cd
	for i in range(10): game.start_dash()
	check(game.dash_cd == cooldown,"repetir Q no reinicia el dash activo")
	await frames(20);check(game.dash_time <= 0 and game.dash_cd > 0,"dash termina y mantiene cooldown")
	game.player.position = Vector3(400,.025,0);game.player.velocity = Vector3.ZERO;game.charge = 100; await frames(30)
	check(game.fusion.request(),"fusión real comienza")
	game.fusion.sequence.advance(11.5);await frames(25)
	var mech: Node3D = game.fusion.sequence.articulation
	var head_before: float = mech.pivots.Cabeza.global_position.y
	var roof := box(Vector3(400,3.05,0),Vector3(9,.2,9));await frames(45)
	print("FUSED_CLEARANCE ",{"position":game.player.position,"height":game.robot_clearance.current_height,"target":game.robot_clearance.target_height,"available":game.robot_clearance.available_height(),"blend":mech.crouch_weight,"floor":game.player.is_on_floor(),"head":mech.pivots.Cabeza.global_position,"before":head_before,"ragdoll":game.physical_ragdoll.active,"paused":game.paused})
	check(game.robots.naoya.collision.shape.height < 2.96 and mech.crouch_weight > .7,"mecha reduce su volumen físico bajo techo")
	check(mech.pivots.Cabeza.global_position.y < head_before-.65,"agachado baja cabeza y torso del mecha")
	var max_error := 0.0
	for side in ["Der","Izq"]: max_error = maxf(max_error,float(mech.ik_error.get(side,0)))
	check(max_error < .12,"pies del mecha permanecen al alcance de la IK")
	check(absf(game.fusion.hurt_area.get_child(0).shape.size.y-game.robot_clearance.current_height)<.01,"volumen de daño acompaña postura")
	await frames(35);check(game.robot_clearance.current_height < 2.96,"mecha detenido no se levanta bajo cubierta")
	roof.queue_free();await frames(60)
	check(game.robot_clearance.current_height > 3.98,"mecha se incorpora al salir")
	game.queue_free();await frames(8)
	print("RESULTADO ",passed,"/",checks);quit(0 if passed == checks else 1)

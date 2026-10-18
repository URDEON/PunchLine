extends SceneTree
var game: Node3D
var checks := 0
var failures := 0
var data: Dictionary
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label)
func building(b: Dictionary) -> Node3D:
	return game.arena.punchline.housing.get_node("GeneratedBuildings/"+b.lot+"/"+b.id)
func place(b: Dictionary,local: Vector3) -> void:
	Input.action_release("forward")
	game.player.global_position=building(b).to_global(local)
	game.player.velocity=Vector3.ZERO
	var inward: Vector3=-building(b).global_basis.z
	game.yaw=atan2(-inward.x,-inward.z);game.model.rotation.y=game.yaw
	game.camera_lock=true;game.player.reset_physics_interpolation()
func run() -> void:
	Engine.set_meta("punchline_world",preload("res://scripts/world_config.gd").DEFAULTS.duplicate())
	data=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/generated_plan.json"))
	game=load("res://main.tscn").instantiate();root.add_child(game);await frames(25)
	for enemy in game.enemies: game.set_dummy_mode(enemy,0)
	game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
	check(game.fusion.request(),"actual robot can fuse in the unchanged parking spawn")
	if not game.fusion.cinematic: quit(1);return
	game.fusion.sequence.advance(11.5);await frames(45)
	var yellow: Dictionary={};var blue: Dictionary={}
	var blocked: Array=[]
	var cylinder:=CylinderShape3D.new();cylinder.radius=data.profile.width/2;cylinder.height=data.profile.crouched_height
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=cylinder;query.collision_mask=1
	query.exclude=[game.player.get_rid()]
	for b in data.buildings:
		var house: Node3D=building(b)
		if b.access=="player_only":
			if int(b.style.palette)==0 and yellow.is_empty():yellow=b
			if int(b.style.palette)==6 and blue.is_empty():blue=b
		# Probe the full conservative mesh width, not only the narrow capsule.
		for z in [house.get_node("Doors/Threshold").position.z+.06,0.0,-1.25]:
			query.transform.origin=house.to_global(Vector3(0,cylinder.height/2+.025,z))
			if not game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():blocked.append(b.lot+"/"+b.id)
	check(blocked.is_empty(),"all 71 front passages, partitions and rooms fit measured crouched mecha width: "+str(blocked))
	var yp: Dictionary=building(yellow).get_meta("robot_passage")
	var bp: Dictionary=building(blue).get_meta("robot_passage")
	check(yp.width>bp.width+.3 and yp.height>bp.height+.15,"yellow houses provide more clearance than compact blue houses")
	var heights: Array=[]
	for b in [yellow,blue]:
		var house: Node3D=building(b)
		var name_color: String="yellow" if b==yellow else "blue"
		place(b,Vector3(0,.015,b.depth/2+2.5));await frames(15)
		Input.action_press("forward")
		var lowest:=4.0;var felt:=0.0
		for i in range(340):
			await physics_frame
			lowest=minf(lowest,game.robot_clearance.current_height)
			felt=maxf(felt,game.robot_clearance.pressure)
			if house.to_local(game.player.global_position).z<-.8:break
		Input.action_release("forward");await frames(50)
		heights.append(lowest)
		var local: Vector3=house.to_local(game.player.global_position)
		print("HOUSE ",name_color," local=",local," min_height=",lowest," pressure=",felt," contacts=",game.robot_clearance.contacts," hands=",game.fusion.sequence.articulation.confinement.hand_errors)
		check(local.z<-.5 and local.z>-b.depth/2+1,"real fused controller enters "+name_color+" house and crosses its partition")
		check(game.player.is_on_floor() and local.y>-.04 and local.y+game.robot_clearance.current_height<b.height+.05,"real "+name_color+" posture stays above floor and below ceiling")
		check(lowest<3.3 and felt>.4,"real "+name_color+" approach automatically compresses body and reduces pace")
		var art: Node3D=game.fusion.sequence.articulation
		print("ARM ",name_color," shoulder=",art.pivots.BrazoSuperior_Izq.global_position," elbow=",art.pivots.Antebrazo_Izq.global_position," hand=",art.pivots.Mano_Izq.global_position," upper_rest=",art.rest_positions.Antebrazo_Izq," lower_rest=",art.rest_positions.Mano_Izq," scale=",art.global_basis.get_scale())
		check(art.confinement.hand_goals.has("Izq") and art.confinement.hand_errors.get("Izq",99)<.22,"free hand reaches actual "+name_color+" ceiling using arm IK")
		game.yaw+=PI;game.model.rotation.y=game.yaw;Input.action_press("forward")
		await frames(340);Input.action_release("forward");await frames(70)
		check(house.to_local(game.player.global_position).z>b.depth/2+2 and game.robot_clearance.current_height>3.98,"real "+name_color+" exit restores full mecha height")
	check(float(heights[1])<float(heights[0])-.12,"blue entrance requires a visibly deeper crouch than yellow entrance")
	# Test a real generated wall, including its collision and articulated hand.
	var house: Node3D=building(blue)
	var front: float=house.get_node("Doors/Threshold").position.z+.06
	place(blue,Vector3(blue.width/2-.4-1.05-.06,.025,front*.5));await frames(100)
	var art: Node3D=game.fusion.sequence.articulation
	var wall_seen:=false;var reached:=false
	for side in game.robot_clearance.contacts:
		if game.robot_clearance.contacts[side].kind=="wall":
			wall_seen=true;reached=reached or float(art.confinement.hand_errors.get(side,99))<.22
	print("WALL contacts=",game.robot_clearance.contacts," hands=",art.confinement.hand_errors)
	check(wall_seen and reached,"mecha braces a hand against the actual nearby house wall")
	var ik_error:=0.0
	for side in ["Der","Izq"]:ik_error=maxf(ik_error,float(art.ik_error.get(side,0)))
	check(ik_error<.12,"wall and ceiling hand contacts preserve planted procedural feet")
	game.fusion.combat.interrupted();await frames(3)
	check(game.fusion.combat.press(1),"cannon still activates in a confined house")
	await frames(40)
	check(art.confinement.hand_errors.is_empty() and art.deployment>.1,"contact IK yields both arms to combat and cannon deployment")
	game.fusion.combat.interrupted();await frames(10)
	place(blue,Vector3(0,.025,blue.depth/2+6));await frames(100)
	check(game.robot_clearance.pressure<.02 and art.confinement.hand_goals.is_empty(),"open air releases contact poses and pressure smoothly")
	check(game.robots.naoya.collision.shape.radius>1.04,"squeezing never shrinks the physical mecha width")
	print("RESULT ",checks-failures,"/",checks," real house confinement checks")
	game.queue_free();await frames(8);quit(1 if failures else 0)

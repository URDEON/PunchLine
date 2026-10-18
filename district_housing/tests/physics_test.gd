extends SceneTree
var failures := 0
var checks := 0
var generator: Node3D
var body: CharacterBody3D

func check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS ", label)
	else:
		failures += 1
		push_error("FAIL " + label)

func _initialize() -> void:
	call_deferred("run")

func tick(count: int, speed := Vector3.ZERO) -> void:
	for i in range(count):
		await physics_frame
		body.move_authoritative(speed, 1.0/60)

func run() -> void:
	generator = load("res://scripts/DistrictHousingGenerator.gd").new()
	root.add_child(generator)
	var b := {"width":10.0,"depth":10.0,"height":3.4,"door_width":2.2,"door_height":2.3,"access":"mecha_crouch","archetype":"workshop_crouch"}
	var building := Node3D.new()
	root.add_child(building)
	generator.build(building,b)
	body = load("res://scripts/ClearanceBody.gd").new()
	body.standing_height = 4.0
	body.crouched_height = 2.0
	body.body_width = 1.5
	body.position = Vector3(0,0.01,8)
	root.add_child(body)
	await tick(100, Vector3(0,0,-4))
	check(body.position.z > 5.0, "standing body blocked by workshop lintel")
	body.crouch_requested = true
	await tick(70)
	check(absf(body.current_height-2.0)<0.01, "capsule smoothly reaches crouch height")
	await tick(100, Vector3(0,0,-4))
	check(body.position.z < 0.0, "crouched body passes doorway and connected partition")
	body.crouch_requested = false
	await tick(100)
	check(body.current_height < 2.1, "standing up prohibited under roof")
	var fused := BoxShape3D.new()
	fused.size = Vector3(3,5,3)
	check(not body.can_fuse(fused, Transform3D(Basis.IDENTITY,Vector3(0,2.5,0))), "fusion blocked where large body overlaps ceiling")
	generator.set_roof_visible(building,false)
	check(not body.fits(4.0), "hidden roof retains physical collision")
	await tick(140, Vector3(0,0,4))
	await tick(100)
	check(body.position.z>6.0 and absf(body.current_height-4.0)<0.01, "exits and regains standing posture after hysteresis")
	# Too narrow opening in an independent wall: no capsule shrinking by width.
	generator.part(generator,"NarrowLeft",Vector3(5,5,0.3),Vector3(-3,2.5,14),null)
	generator.part(generator,"NarrowRight",Vector3(5,5,0.3),Vector3(3,2.5,14),null)
	body.position = Vector3(0,0.01,11)
	body.crouch_requested = true
	await tick(100, Vector3(0,0,4))
	check(body.position.z<14, "one metre opening rejects 1.5 metre body even crouched")
	# Separate collision probes exercise the remaining prototype archetypes.
	for index in range(3):
		var n := Node3D.new()
		n.position.x = 30.0 + index*20.0
		root.add_child(n)
		var access: String = ["mecha_standing","player_only","inaccessible"][index]
		generator.build(n,{"width":10.0,"depth":10.0,"height":4.9 if index==0 else 3.4,"door_width":2.2 if index==0 else 1.3,"door_height":4.3 if index==0 else 2.3,"access":access,"archetype":access})
	await physics_frame
	for index in range(3):
		var shape := CapsuleShape3D.new()
		shape.radius = 0.75 if index==0 else 0.3
		shape.height = 4.0 if index==0 else 1.8
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = Transform3D(Basis.IDENTITY,Vector3(30+index*20,shape.height/2+0.02,4.85))
		var overlaps := not body.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
		check(overlaps if index==2 else not overlaps,["warehouse permits standing body","house permits player at entrance","inaccessible facade has solid collider"][index])
	print("RESULT checks=",checks," failed=",failures," SYNTHETIC body; real rig untested")
	quit(1 if failures else 0)

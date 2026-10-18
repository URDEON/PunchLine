extends SceneTree
var game:Node3D
var failures:=0
var checks:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func frames(n:int)->void:
	for i in range(n):await physics_frame
func run()->void:
	game=load("res://main.tscn").instantiate();root.add_child(game);await frames(20)
	for e in game.enemies:game.set_dummy_mode(e,0)
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/generated_plan.json"))
	var selected:Dictionary={}
	for b in data.buildings:
		if not selected.has(b.archetype):selected[b.archetype]=b
	var b:Dictionary=selected.small_residential
	var building:Node3D=game.arena.punchline.housing.get_node("GeneratedBuildings/"+b.lot+"/"+b.id)
	var inward:Vector3=-building.global_basis.z
	game.player.global_position=building.to_global(Vector3(0,.015,b.depth/2+2))
	game.player.velocity=Vector3.ZERO;game.yaw=atan2(-inward.x,-inward.z);game.model.rotation.y=game.yaw;game.camera_lock=true
	Input.action_press("forward");await frames(120);Input.action_release("forward");await frames(10)
	var local:Vector3=building.to_local(game.player.global_position)
	check(local.z<0 and local.z>-b.depth/2,"real player walks through house doorway into second room")
	game.yaw+=PI;Input.action_press("forward");await frames(140);Input.action_release("forward");await frames(5)
	check(building.to_local(game.player.global_position).z>b.depth/2,"real player can leave house")
	for archetype in ["warehouse_standing"]:
		b=selected[archetype];building=game.arena.punchline.housing.get_node("GeneratedBuildings/"+b.lot+"/"+b.id)
		var shape:=CapsuleShape3D.new();shape.radius=1.05;shape.height=4.0
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1
		query.transform=Transform3D(Basis.IDENTITY,building.to_global(Vector3(0,2.02,b.depth/2-.15)))
		var occupied:=not game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
		check(not occupied if archetype=="warehouse_standing" else occupied,"actual mecha capsule at "+archetype+" entrance")
		if archetype=="warehouse_standing":
			for point in [Vector3(0,2.02,1),Vector3(0,2.02,0),Vector3(0,2.02,-1)]:
				query.transform.origin=building.to_global(point)
				check(game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(),"standing warehouse room/partition clearance "+str(point.z))
	var all_open:=true
	for entry in data.buildings:all_open=all_open and entry.access!="inaccessible"
	check(all_open,"all production houses have real entrances")
	var factory:Node3D=load("res://housing/scripts/DistrictHousingGenerator.gd").new();game.add_child(factory)
	factory.part(factory,"NarrowLeft",Vector3(5,5,.3),Vector3(396.6,2.5,0),null)
	factory.part(factory,"NarrowRight",Vector3(5,5,.3),Vector3(403.4,2.5,0),null)
	var cast:=ShapeCast3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=1.05;capsule.height=2.90
	cast.shape=capsule;factory.add_child(cast);cast.global_position=Vector3(400,1.47,4);cast.target_position=Vector3(0,0,-8);cast.collision_mask=1
	cast.force_shapecast_update()
	check(cast.is_colliding(),"ShapeCast blocks real mecha width at 1.8 metre opening even crouched")
	print("RESULT ",checks-failures,"/",checks," actual player and measured physical mecha dimensions")
	game.queue_free();await frames(6);quit(1 if failures else 0)

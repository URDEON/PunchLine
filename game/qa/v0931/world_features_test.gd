extends SceneTree
var game:Node3D
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func frames(count:int)->void:
	for i in range(count):await physics_frame
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func run()->void:
	game=load("res://main.tscn").instantiate();root.add_child(game)
	while game.loading:await process_frame
	await frames(25)
	for enemy in game.enemies:game.set_dummy_mode(enemy,0)
	var map:Node3D=game.arena.punchline
	var facilities:Dictionary={};var towers:=0
	for lot in map.housing.get_node("GeneratedBuildings").get_children():
		for building in lot.get_children():
			if int(building.get_meta("storeys",1))<=1:continue
			towers+=1
			for kind in building.get_meta("facilities",{}):facilities[kind]=true
	var complete:=true
	for kind in ["reception_desk","ergonomic_chair","waiting_sofa","coffee_table","mailboxes","security_mirror","waste_bin","recycling_bin","cctv","control_monitor","pedestrian_turnstile","extinguisher_cabinet","washbasin","soap_dispenser","paper_towel_dispenser","hand_dryer","bathroom_mirror","staff_lockers","rest_bench","wall_luminaire","entrance_mat","decorative_planter"]:
		complete=complete and facilities.has(kind)
	check(complete and towers>=20,"multistorey buildings include the complete requested reception, security, bathroom and corridor equipment")
	check(map.scene.get_node("Sidewalks").get_child(0).material_override is ShaderMaterial,"editable baked sidewalks use world-sized antialiased paving slabs")
	check(map.ambience.environment.sky.sky_material is PhysicalSkyMaterial,"day sky is generated analytically rather than upscaling a panorama")
	var cargo:Node3D=map.cargo;cargo.set_process(false)
	check(cargo.containers.size()>=20 and cargo.get_node("YardPerimeter").get_child_count()>100,"large concrete polygon contains a fenced cargo yard and many colored containers")
	var open:AnimatableBody3D
	for body in cargo.containers:
		if body.get_meta("open",false):open=body;break
	var space:PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
	var shape:=CylinderShape3D.new();shape.radius=.32;shape.height=1.8
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1
	query.transform.origin=open.global_position+Vector3(0,1.05,0)
	check(space.intersect_shape(query,1).is_empty(),"container interior has usable hollow collision volume")
	var roof:=PhysicsRayQueryParameters3D.create(open.global_position+Vector3(0,4,0),open.global_position+Vector3(0,2.2,0),1)
	check(not space.intersect_ray(roof).is_empty(),"container roof has actual collision")
	var entrance:=PhysicsRayQueryParameters3D.create(open.global_position+Vector3(0,1.2,open.get_meta("length")/2+1.0),open.global_position+Vector3(0,1.2,0),1)
	check(space.intersect_ray(entrance).is_empty(),"open container doors leave the entrance physically passable")
	game.player.global_position=cargo.console+Vector3(0,.1,2);game.player.velocity=Vector3.ZERO
	var event:=InputEventKey.new();event.keycode=KEY_H;event.physical_keycode=KEY_H;event.pressed=true
	cargo._unhandled_input(event);cargo.update_panel()
	check(cargo.operator==1 and cargo.captured and cargo.crane_camera.current,"H at the actual console enters the operable crane with its own camera")
	check(not cargo.command(999,"grab"),"a different operator cannot manipulate the cargo")
	check(cargo.command(1,"grab") and cargo.load_index>=0,"spreader attaches to a real container under the gantry")
	var load_index:int=cargo.load_index;var start:Vector3=cargo.containers[load_index].global_position
	for i in range(70):cargo.input_control(1,Vector3(1,1,0));await physics_frame
	var moved:Vector3=cargo.containers[load_index].global_position
	check(moved.y>start.y+1.5 and moved.x>start.x+1.5,"crane raises and translates the entire hollow container with its collisions")
	check(not cargo.command(1,"grab"),"suspended loads cannot be released in mid-air")
	for i in range(90):cargo.input_control(1,Vector3(0,-1,0));await physics_frame
	check(cargo.command(1,"grab") and cargo.load_index<0 and cargo.containers[load_index].position.y<.08,"lowering the hoist releases the moved container onto the ground")
	check(cargo.state().containers.size()==cargo.containers.size(),"network crane state includes every persistent container position")
	cargo._unhandled_input(event);cargo.update_panel()
	check(cargo.operator==0 and not cargo.captured and game.camera.current,"H leaves the console and restores the player's camera")
	cargo.reset_world();await frames(3)
	check(cargo.operator==0 and cargo.load_index<0 and cargo.containers[load_index].position.is_equal_approx(cargo.initial_positions[load_index]),"restarting the world restores a moved container and releases the crane operator")
	var d:Node3D=map.destruction;var roof_id:=""
	for id in d.parts:
		if d.parts[id].category=="Roof" and d.parts[id].collision.shape is ConcavePolygonShape3D:roof_id=id;break
	check(not roof_id.is_empty() and d.parts[roof_id].collision.shape.backface_collision,"pitched roofs collide from both sides")
	var p:Dictionary=d.parts[roof_id]
	d.damage_area(p.box.get_center(),.4,500,Vector3.DOWN)
	await frames(560)
	var solid:bool=not d.settled_nodes.is_empty()
	for body in d.settled_nodes.values():solid=solid and body is StaticBody3D and body.collision_layer&1!=0 and body.find_children("*","CollisionShape3D",true,false).size()>0
	check(solid,"fallen structural roofs settle as solid collision bodies, rather than decorative floating meshes")
	check(d.state().settled.size()==d.settled_nodes.size(),"late-join destruction state includes the host-selected settled roof poses")
	var support_clear:=true
	for building in d.buildings.values():
		for entry in building.decor:
			if entry.get("support","")==roof_id:support_clear=support_clear and entry.hidden
	check(support_clear,"trim and ridge geometry disappear when their roof support is destroyed")
	d.reset_world();await frames(4)
	check(d.settled_nodes.is_empty() and d.settled_structures.is_empty() and not d.parts[roof_id].broken,"world restart removes settled roof fragments and restores the roof")
	# Pool eviction may send a reliable resting pose before the damage packet.
	d.accept_settled({"id":roof_id,"pose":p.pose})
	d.damage_area(p.box.get_center(),.4,500,Vector3.DOWN);await frames(4)
	var duplicate:=false
	for moving in d.debris:
		if is_instance_valid(moving) and moving.get_meta("structural_source","")==roof_id:duplicate=true
	check(not duplicate and d.settled_nodes.has(roof_id),"settling received before damage cannot spawn a duplicate moving roof")
	d.reset_world();await frames(4)
	var total_buildings:=0
	for lot in map.housing.get_node("GeneratedBuildings").get_children():total_buildings+=lot.get_child_count()
	print("WORLD_COUNTS buildings=",total_buildings," multistorey=",towers," containers=",cargo.containers.size()," facilities=",facilities.keys())
	print("RESULT ",checks-failures,"/",checks," buildings, cargo, rendering and solid roofs")
	game.queue_free();await frames(8);quit(1 if failures else 0)

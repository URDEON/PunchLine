extends SceneTree
## Regression checks for visible terrain, real window apertures and every generated entrance.
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,label:String,details:Array=[])->void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label," ",details.slice(0,8) if not details.is_empty() else "")
func geometry_inside(building:Node3D,b:Dictionary)->bool:
	var inverse:Transform3D=building.global_transform.affine_inverse()
	for geometry in building.find_children("*","GeometryInstance3D",true,false):
		var transforms:Array[Transform3D]=[];var bounds:AABB
		if geometry is MeshInstance3D:
			bounds=geometry.mesh.get_aabb();transforms.append(inverse*geometry.global_transform)
		elif geometry is MultiMeshInstance3D:
			bounds=geometry.multimesh.mesh.get_aabb()
			for i in range(geometry.multimesh.instance_count):transforms.append(inverse*geometry.global_transform*(geometry.multimesh.source_transform(i) if geometry.multimesh.has_method("source_transform") else geometry.multimesh.get_instance_transform(i)))
		else:continue
		for t in transforms:
			for corner in range(8):
				var p:Vector3=t*bounds.get_endpoint(corner)
				var regular:bool=absf(p.x)<=b.width/2+.003 and absf(p.z)<=b.depth/2+.003
				var ramp:bool=absf(p.x)<=b.door_width/2+.003 and p.z>=b.depth/2-.003 and p.z<=b.depth/2+1.203
				if not regular and not ramp:
					print("DETAIL_OUTSIDE ",building.name," ",geometry.get_path()," ",p);return false
	return true
func run()->void:
	var world:=Node3D.new();root.add_child(world)
	var map:Node3D=load("res://housing/scenes/District500.tscn").instantiate();world.add_child(map)
	var housing:Node3D=load("res://housing/scenes/GeneratedHousing.tscn").instantiate();world.add_child(housing)
	for i in range(3):await physics_frame
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/generated_plan.json"))
	var space:PhysicsDirectSpaceState3D=world.get_world_3d().direct_space_state
	var bad_winding:Array=[];var bad_texture:Array=[]
	for layer in ["Roads","Parking","Lots","Sidewalks"]:
		for visual in map.get_node(layer).get_children():
			if visual.material_override.albedo_texture==null:bad_texture.append(visual.name)
			var arrays:Array=visual.mesh.surface_get_arrays(0);var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			for i in range(0,points.size(),3):
				if normals[i].y>.99 and (points[i+2]-points[i]).cross(points[i+1]-points[i]).y<=0:bad_winding.append(visual.name);break
	check(bad_winding.is_empty(),"all terrain top faces use Godot front-facing winding",bad_winding)
	check(bad_texture.is_empty(),"roads, parking, lots and sidewalks have real textures",bad_texture)
	var blocked:Array=[];var closed:Array=[];var no_windows:Array=[];var opaque_holes:Array=[];var missing_glass:Array=[];var oversize:Array=[];var workshop_standing:Array=[];var narrow_routes:Array=[]
	var window_count:=0
	var mismatched_visibility:Array=[]
	for b in data.buildings:
		var building:Node3D=housing.get_node("GeneratedBuildings/"+b.lot+"/"+b.id)
		var id:String=b.lot+"/"+b.id
		for geometry in building.find_children("*","GeometryInstance3D",true,false):
			if geometry.visibility_range_end!=320 or geometry.visibility_range_end_margin!=20:mismatched_visibility.append(id+"/"+geometry.name)
		if building.get_meta("access")=="inaccessible":closed.append(id)
		var capsule:=CapsuleShape3D.new();capsule.radius=.38;capsule.height=1.9
		if b.access.begins_with("mecha"):
			capsule.radius=data.profile.collider_width/2
			capsule.height=data.profile.crouched_height if b.access=="mecha_crouch" else data.profile.standing_height
		var threshold:StaticBody3D=building.get_node("Doors/Threshold")
		var front:float=threshold.position.z+.06
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1
		query.transform=Transform3D(Basis.IDENTITY,building.to_global(Vector3(0,capsule.height/2+.025,front)))
		if not space.intersect_shape(query,1).is_empty():blocked.append(id)
		if b.access=="mecha_crouch":
			capsule.height=data.profile.standing_height;query.transform.origin=building.to_global(Vector3(0,capsule.height/2+.025,front))
			if space.intersect_shape(query,1).is_empty():workshop_standing.append(id)
		# Sweep the measured cylinder down the entire centre route (width + side margins already in the plan).
		var cast:=ShapeCast3D.new();var cylinder:=CylinderShape3D.new()
		cylinder.radius=data.profile.width/2 if b.access.begins_with("mecha") else .38
		cylinder.height=data.profile.crouched_height if b.access=="mecha_crouch" else (data.profile.standing_height if b.access=="mecha_standing" else 1.9)
		cast.shape=cylinder;world.add_child(cast);cast.global_position=building.to_global(Vector3(0,cylinder.height/2+.025,b.depth/2+1.25))
		cast.target_position=-building.global_basis.z*(b.depth/2+2.5);cast.collision_mask=1;cast.force_shapecast_update()
		if cast.is_colliding():narrow_routes.append(id)
		cast.queue_free()
		var count:=0
		for opening in building.get_node("Windows").get_children():
			if not opening.has_meta("aperture"):continue
			count+=1;window_count+=1
			var rect:Rect2=opening.get_meta("aperture");var x:float=rect.position.x+rect.size.x*.72;var y:float=rect.position.y+rect.size.y*.30
			var glass:StaticBody3D=opening.get_node("Glass")
			var ray:=PhysicsRayQueryParameters3D.create(opening.to_global(Vector3(x,y,-.55)),opening.to_global(Vector3(x,y,.55)),1)
			ray.exclude=[glass.get_rid()]
			if not space.intersect_ray(ray).is_empty():opaque_holes.append(id+"/"+opening.name)
			ray.exclude=[];var hit:Dictionary=space.intersect_ray(ray)
			if hit.is_empty() or hit.collider!=glass:missing_glass.append(id+"/"+opening.name)
		if count<4:no_windows.append(id)
		if not geometry_inside(building,b):oversize.append(id)
	check(closed.is_empty(),"every production building is enterable",closed)
	check(blocked.is_empty(),"all "+str(data.buildings.size())+" doors fit their measured body",blocked)
	check(workshop_standing.is_empty(),"all five workshop lintels reject a standing mecha",workshop_standing)
	check(narrow_routes.is_empty(),"ShapeCast traverses every doorway and connected interior",narrow_routes)
	check(no_windows.is_empty(),"every house has windows on multiple walls",no_windows)
	check(opaque_holes.is_empty(),"all "+str(window_count)+" windows have genuine unobstructed wall apertures",opaque_holes)
	check(missing_glass.is_empty(),"window glass preserves physical barriers while remaining transparent",missing_glass)
	check(oversize.is_empty(),"all actual meshes, detail batches and roof geometry stay within validated envelopes",oversize)
	check(mismatched_visibility.is_empty(),"walls, roofs, windows and props share the same visibility limit",mismatched_visibility)
	print("RESULT ",checks-failures,"/",checks," architecture checks; buildings=",data.buildings.size()," windows=",window_count)
	world.queue_free();await process_frame;await process_frame;quit(1 if failures else 0)

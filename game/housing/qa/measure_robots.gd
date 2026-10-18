extends SceneTree
const SNAP = preload("res://scripts/mesh_pose_snapshot.gd")
var game: Node3D
var report := {"source":"PunchLine 0.9.24 editable from user Drive", "godot":"4.4.1", "robots":[], "mecha":{}, "notes":["Visual bounds are conservative transformed per-mesh AABBs for the rigid fused mecha.","Base robot visual bounds are CPU-skinned vertices in world space.","Dimensions measured in laboratory at x=400; District500 scene absent from source archives."]}
func _initialize() -> void: run.call_deferred()
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func box(point: Vector3,size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new(); game.add_child(body); body.position=point
	var col := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size=size; col.shape=shape; body.add_child(col)
	return body
func serial_bounds(bounds: AABB) -> Dictionary:
	var relative: Vector3 = bounds.position-game.player.global_position
	return {"min_relative":[relative.x,relative.y,relative.z],"size":[bounds.size.x,bounds.size.y,bounds.size.z],"top_above_feet":relative.y+bounds.size.y,"horizontal_diameter":sqrt(bounds.size.x*bounds.size.x+bounds.size.z*bounds.size.z)}
func robot_bounds() -> AABB:
	var skeleton: Skeleton3D=game.robots.current.skeleton
	# SkeletonModifier3D restores input poses after evaluation. Apply its cached final
	# pose temporarily for CPU skinning, then restore the original bones.
	var saved: Array[Transform3D]=[]
	var cache: Dictionary=game.robots.current.procedural.pose_cache
	for i in range(skeleton.get_bone_count()):
		saved.append(skeleton.get_bone_pose(i))
		if cache.has(i):
			skeleton.set_bone_pose_position(i,cache[i].position)
			skeleton.set_bone_pose_rotation(i,cache[i].rotation)
	skeleton.force_update_all_bone_transforms()
	var first := true; var bounds := AABB()
	for mesh in game.robots.current.meshes:
		for surface in range(mesh.mesh.get_surface_count()):
			for p in SNAP.vertices(mesh,skeleton,surface):
				var point: Vector3=skeleton.global_transform*p
				if first: bounds=AABB(point,Vector3.ZERO); first=false
				else: bounds=bounds.expand(point)
	for i in range(saved.size()):skeleton.set_bone_pose(i,saved[i])
	skeleton.force_update_all_bone_transforms()
	return bounds
func fused_bounds() -> AABB:
	var first := true; var bounds := AABB()
	for mesh in game.fusion.sequence.articulation.pieces.values():
		var b: AABB=mesh.global_transform*mesh.get_aabb()
		bounds=b if first else bounds.merge(b);first=false
	return bounds
func run() -> void:
	game=load("res://main.tscn").instantiate(); root.add_child(game); await frames(15)
	for e in game.enemies: game.set_dummy_mode(e,0)
	var original: CollisionShape3D
	for child in game.player.get_children():
		if child is CollisionShape3D: original=child;break
	report["player"]={"height":original.shape.height,"width":original.shape.radius*2,"scale":[original.global_basis.get_scale().x,original.global_basis.get_scale().y,original.global_basis.get_scale().z]}
	box(Vector3(400,-.1,0),Vector3(100,.2,100))
	game.robots.select(1)
	for variant in range(4):
		game.robots.forced=variant;game.robots.spawn();game.player.position=Vector3(400,.025,0);game.player.velocity=Vector3.ZERO;await frames(30)
		var col: CollisionShape3D=game.robots.naoya.collision
		var row := {"name":game.robots.NAMES[variant],"standing_capsule_height":col.shape.height,"capsule_width":col.shape.radius*2,"scale":[col.global_basis.get_scale().x,col.global_basis.get_scale().y,col.global_basis.get_scale().z],"standing_visual":serial_bounds(robot_bounds())}
		var roof := box(Vector3(400,1.65,0),Vector3(8,.2,8));await frames(55)
		row["crouched_capsule_height"]=col.shape.height;row["crouched_visual"]=serial_bounds(robot_bounds());row["posture_blend"]=game.robot_clearance.blend
		report.robots.append(row);roof.queue_free();await frames(45)
	game.player.position=Vector3(400,.025,0);game.player.velocity=Vector3.ZERO;game.charge=100;await frames(20)
	if not game.fusion.request():push_error("Fusion failed during measurement");quit(1);return
	game.fusion.sequence.advance(11.5);await frames(45)
	var col: CollisionShape3D=game.robots.naoya.collision
	report.mecha={"standing_capsule_height":col.shape.height,"capsule_width":col.shape.radius*2,"configured_minimum":game.robot_clearance.minimum,"standing_visual":serial_bounds(fused_bounds()),"rig":"ArticulacionMecanica: rigid modules, procedural hip/knee/ankle chain"}
	var roof := box(Vector3(400,3.15,0),Vector3(12,.3,12));await frames(90)
	report.mecha["crouched_capsule_height"]=col.shape.height;report.mecha["crouched_visual"]=serial_bounds(fused_bounds());report.mecha["roof_underside"]=3.0;report.mecha["posture_blend"]=game.robot_clearance.blend
	var max_ik := 0.0
	for side in ["Der","Izq"]:max_ik=maxf(max_ik,float(game.fusion.sequence.articulation.ik_error.get(side,0)))
	report.mecha["max_ik_error"]=max_ik
	var output:=FileAccess.open("res://housing/data/robot_measurements.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"\t")+"\n");output.close()
	print("MEASUREMENTS ",JSON.stringify(report))
	roof.queue_free();game.queue_free();await frames(6);quit(0)

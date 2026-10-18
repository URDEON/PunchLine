extends Node3D
## Rebuilds the supplied mesh's unusable skin into six two-bone legs.
## Original geometry, UVs, textures and proportions are preserved.
const FEET=[Vector3(-.284,.044,-.435),Vector3(-.442,.052,.004),Vector3(-.269,.043,.445),Vector3(.269,.044,-.444),Vector3(.442,.051,-.005),Vector3(.284,.042,.437)]
var skeleton:Skeleton3D
var mesh:MeshInstance3D
var hips:Array[Vector3]=[]
var knees:Array[Vector3]=[]
var feet_world:Array[Vector3]=[]
var starts:Array[Vector3]=[]
var targets:Array[Vector3]=[]
var progress:Array[float]=[]
var initialized:=false
var phase:=0
var faded:=false
var material:StandardMaterial3D

func _ready()->void:
	build()

func build()->void:
	var original:Node3D=preload("res://assets/characters/rustcrawler/Rustcrawler.glb").instantiate()
	var source:MeshInstance3D=original.find_children("*","MeshInstance3D",true,false)[0]
	skeleton=Skeleton3D.new();skeleton.name="SixLegSkeleton";add_child(skeleton)
	skeleton.add_bone("Body");skeleton.set_bone_rest(0,Transform3D.IDENTITY)
	for i in range(6):
		var end:Vector3=FEET[i];var hip:=Vector3(signf(end.x)*.12,.275,end.z*.29)
		var knee:=Vector3(end.x*.83,.275,end.z*.83)
		hips.append(hip);knees.append(knee)
		skeleton.add_bone("Hip"+str(i));skeleton.set_bone_parent(1+i*2,0);skeleton.set_bone_rest(1+i*2,Transform3D(Basis.IDENTITY,hip))
		skeleton.add_bone("Knee"+str(i));skeleton.set_bone_parent(2+i*2,1+i*2);skeleton.set_bone_rest(2+i*2,Transform3D(Basis.IDENTITY,knee-hip))
		feet_world.append(Vector3.ZERO);starts.append(Vector3.ZERO);targets.append(Vector3.ZERO);progress.append(1.0)
	var arrays:Array=source.mesh.surface_get_arrays(0);var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var bones:=PackedInt32Array();var weights:=PackedFloat32Array()
	for vertex in vertices:
		var radial:=Vector2(vertex.x,vertex.z).length();var index:=0;var nearest:=INF
		for i in range(6):
			var direction:=Vector2(FEET[i].x,FEET[i].z).normalized()
			var point:=Vector2(vertex.x,vertex.z)
			var distance:float=point.distance_to(direction*maxf(.12,point.dot(direction)))
			if distance<nearest:nearest=distance;index=i
		var limb_weight:float=smoothstep(.17,.245,radial)*(1-smoothstep(.37,.43,vertex.y))
		var thigh_point:=Geometry3D.get_closest_point_to_segment(vertex,hips[index],knees[index])
		var shin_point:=Geometry3D.get_closest_point_to_segment(vertex,knees[index],FEET[index])
		var shin_weight:float=1.0 if vertex.distance_squared_to(shin_point)<vertex.distance_squared_to(thigh_point) else 0.0
		# Blend a narrow band around the mechanical knee to avoid a tearing seam.
		if vertex.distance_to(knees[index])<.055:shin_weight=clampf(.5+(vertex.y-knees[index].y)*-8,0,1)
		bones.append_array(PackedInt32Array([0,1+index*2,2+index*2,0]))
		weights.append_array(PackedFloat32Array([1-limb_weight,limb_weight*(1-shin_weight),limb_weight*shin_weight,0]))
	arrays[Mesh.ARRAY_BONES]=bones;arrays[Mesh.ARRAY_WEIGHTS]=weights
	var rebuilt:=ArrayMesh.new();rebuilt.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	material=source.get_active_material(0).duplicate();rebuilt.surface_set_material(0,material)
	mesh=MeshInstance3D.new();mesh.name="RustcrawlerMesh";mesh.mesh=rebuilt;skeleton.add_child(mesh);mesh.skeleton=NodePath("..")
	var skin:=Skin.new()
	for i in range(skeleton.get_bone_count()):skin.add_bind(i,skeleton.get_bone_global_rest(i).affine_inverse())
	mesh.skin=skin
	original.free()

func solve_leg(index:int,end:Vector3)->void:
	var hip:Vector3=hips[index];var knee:Vector3=knees[index]
	var upper:Vector3=knee-hip;var lower:Vector3=FEET[index]-knee
	var a:float=upper.length();var b:float=lower.length()
	var reach:Vector3=end-hip;var distance:float=clampf(reach.length(),absf(a-b)+.002,a+b-.002)
	var direction:Vector3=reach.normalized() if reach.length()>.001 else Vector3.DOWN
	var along:float=(a*a-b*b+distance*distance)/(2*distance)
	var pole:Vector3=(Vector3.UP-direction*direction.dot(Vector3.UP)).normalized()
	if pole.length()<.01:pole=Vector3.RIGHT
	var wanted_knee:Vector3=hip+direction*along+pole*sqrt(maxf(0,a*a-along*along))
	var q:=Quaternion(upper.normalized(),(wanted_knee-hip).normalized()).normalized()
	var q_lower:=Quaternion(lower.normalized(),(end-wanted_knee).normalized()).normalized()
	skeleton.set_bone_pose_rotation(1+index*2,q)
	skeleton.set_bone_pose_rotation(2+index*2,(q.inverse()*q_lower).normalized())

func tick(delta:float,body:CharacterBody3D,normal:Vector3,moving:bool,unfold:=1.0)->void:
	if skeleton==null:return
	var stepping:=false
	for p in progress:
		if p<1:stepping=true
	for i in range(6):
		var ideal:Vector3=contact(i,body,normal)
		if not initialized:feet_world[i]=ideal;targets[i]=ideal
		if progress[i]>=1 and (feet_world[i].distance_to(ideal)>.24 or feet_world[i].distance_to(global_position)>1.2) and (i%2==phase or not moving) and not stepping:
			# Start one tripod together, then allow it to finish before the other.
			for j in range(6):
				if j%2==i%2:starts[j]=feet_world[j];targets[j]=contact(j,body,normal);progress[j]=0
			phase=1-i%2;stepping=true
		if progress[i]<1:
			progress[i]=minf(1,progress[i]+delta/.18)
			feet_world[i]=starts[i].lerp(targets[i],smoothstep(0,1,progress[i]))+normal*sin(progress[i]*PI)*.13
		var local:Vector3=to_local(feet_world[i])
		local=Vector3(local.x*.28,.23,local.z*.28).lerp(local,unfold)
		solve_leg(i,local)
	initialized=true

func contact(index:int,body:CharacterBody3D,normal:Vector3)->Vector3:
	var ideal:Vector3=to_global(FEET[index])
	var query:=PhysicsRayQueryParameters3D.create(ideal+normal*.65,ideal-normal*.8,1);query.exclude=[body.get_rid()]
	var hit:Dictionary=body.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position+hit.normal*.075 if not hit.is_empty() else ideal

func camouflage(enabled:bool)->void:
	if faded==enabled:return
	faded=enabled
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA if enabled else BaseMaterial3D.TRANSPARENCY_DISABLED
	material.albedo_color=Color(.38,.65,.66,.16) if enabled else Color.WHITE
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_ON

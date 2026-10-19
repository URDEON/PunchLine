extends Node3D
## Preserve the supplied Rustcrawler armour and UVs as thirteen rigid sections.
## The core is fitted to the measured installed head; only the leg joints rotate.
var source_head:Node3D
var skeleton:Skeleton3D
var mesh:MeshInstance3D
var material:StandardMaterial3D
var head_body:Node3D
var head_bounds:=AABB()
var visual_height:=.7
var body_radius:=.25
var hips:Array[Vector3]=[]
var knees:Array[Vector3]=[]
var feet_rest:Array[Vector3]=[]
var feet_world:Array[Vector3]=[]
var previous_feet_world:Array[Vector3]=[]
var starts:Array[Vector3]=[]
var targets:Array[Vector3]=[]
var progress:Array[float]=[]
var upper_parts:Array[MeshInstance3D]=[]
var lower_parts:Array[MeshInstance3D]=[]
var knee_parts:Array[MeshInstance3D]=[]
var foot_parts:Array[MeshInstance3D]=[]
var render_meshes:Array[MeshInstance3D]=[]
var materials:Array=[]
var physics_pose:=Transform3D.IDENTITY
var folded:Array[Vector3]=[]
var initialized:=false
var phase:=0
var faded:=false
var previous_origin:=Vector3.ZERO
var previous_normal:=Vector3.UP
var step_count:=0
var max_target_error:=0.0
var max_reach_error:=0.0

func _ready()->void:build()
func metal(color:Color,roughness:=.45)->StandardMaterial3D:
 var result:=StandardMaterial3D.new();result.albedo_color=color;result.metallic=.72;result.roughness=roughness;return result
func visual(parent:Node3D,label:String,shape:Mesh,mat:Material)->MeshInstance3D:
 var result:=MeshInstance3D.new();result.name=label;result.mesh=shape;result.material_override=mat
 parent.add_child(result);render_meshes.append(result);return result
func build()->void:
 var target:=Vector3(.62,.619,.777)
 if is_instance_valid(source_head):
  var measured:=AABB();var first:=true
  var root_scale:=Transform3D(Basis.from_scale(source_head.global_basis.get_scale()),Vector3.ZERO)
  for original in source_head.find_children("*","MeshInstance3D",true,false):
   if not original.visible or original.mesh==null:continue
   var box:AABB=(root_scale*source_head.global_transform.affine_inverse()*original.global_transform)*original.get_aabb()
   measured=box if first else measured.merge(box);first=false
  if not first:target=measured.size
 var original:Node3D=preload("res://assets/characters/rustcrawler/Rustcrawler.glb").instantiate()
 var source:MeshInstance3D=original.find_children("*","MeshInstance3D",true,false)[0]
 material=source.get_active_material(0).duplicate()
 var arrays:Array=source.mesh.surface_get_arrays(0)
 var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
 var groups:Array=[]
 for i in range(13):groups.append([])
 # A rigid central box includes the sensor housing, pelvis and both aerials.
 # Classification is per triangle: armour cannot stretch under blended skin weights.
 var core:=AABB(Vector3(-.205,.185,-.205),Vector3(.410,.477,.410))
 var fit:float=minf(target.x/core.size.x,minf(target.y/core.size.y,target.z/core.size.z))
 var ends:Array=[Vector3(-.284,.044,-.435),Vector3(-.442,.052,.004),Vector3(-.269,.043,.445),Vector3(.269,.044,-.444),Vector3(.442,.051,-.005),Vector3(.284,.042,.437)]
 skeleton=Skeleton3D.new();skeleton.name="SixLegIK";add_child(skeleton);skeleton.add_bone("Body");skeleton.set_bone_rest(0,Transform3D.IDENTITY)
 for i in range(6):
  var end:Vector3=ends[i];var hip:=Vector3(signf(end.x)*.12,.275,end.z*.29);var knee:=Vector3(end.x*.83,.275,end.z*.83)
  hips.append(hip*fit);knees.append(knee*fit);feet_rest.append(end*fit)
  skeleton.add_bone("Hip"+str(i));skeleton.set_bone_parent(1+i*2,0);skeleton.set_bone_rest(1+i*2,Transform3D(Basis.IDENTITY,hips[i]))
  skeleton.add_bone("Knee"+str(i));skeleton.set_bone_parent(2+i*2,1+i*2);skeleton.set_bone_rest(2+i*2,Transform3D(Basis.IDENTITY,knees[i]-hips[i]))
  feet_world.append(Vector3.ZERO);previous_feet_world.append(Vector3.ZERO);starts.append(Vector3.ZERO);targets.append(Vector3.ZERO);progress.append(1.0)
 for t in range(0,indices.size(),3):
  var centroid:Vector3=(vertices[indices[t]]+vertices[indices[t+1]]+vertices[indices[t+2]])/3
  var section:=0
  if not ((absf(centroid.x)<.205 and absf(centroid.z)<.205) or centroid.y>.405):
   var best:=INF;var leg:=0
   for i in range(6):
    var dir:=Vector2(ends[i].x,ends[i].z).normalized();var point:=Vector2(centroid.x,centroid.z)
    var distance:float=point.distance_to(dir*maxf(.12,point.dot(dir)))
    if distance<best:best=distance;leg=i
   var h:Vector3=hips[leg]/fit;var k:Vector3=knees[leg]/fit
   var thigh:Vector3=Geometry3D.get_closest_point_to_segment(centroid,h,k)
   var shin:Vector3=Geometry3D.get_closest_point_to_segment(centroid,k,ends[leg])
   section=1+leg*2+(1 if centroid.distance_squared_to(shin)<centroid.distance_squared_to(thigh) else 0)
  for j in range(3):groups[section].append(indices[t+j])
 var measured_core:=AABB(vertices[groups[0][0]],Vector3.ZERO)
 for index in groups[0]:measured_core=measured_core.expand(vertices[index])
 fit=minf(target.x/measured_core.size.x,minf(target.y/measured_core.size.y,target.z/measured_core.size.z))
 for i in range(6):
  hips[i]=Vector3(signf(ends[i].x)*.12,.275,ends[i].z*.29)*fit
  knees[i]=Vector3(ends[i].x*.83,.275,ends[i].z*.83)*fit;feet_rest[i]=ends[i]*fit
  skeleton.set_bone_rest(1+i*2,Transform3D(Basis.IDENTITY,hips[i]));skeleton.set_bone_rest(2+i*2,Transform3D(Basis.IDENTITY,knees[i]-hips[i]))
 for section in range(13):
  var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  var origin:Vector3=Vector3.ZERO if section==0 else (hips[(section-1)/2] if section%2==1 else knees[(section-1)/2])
  for index in groups[section]:
   surface.set_normal(arrays[Mesh.ARRAY_NORMAL][index]);surface.set_uv(arrays[Mesh.ARRAY_TEX_UV][index]);surface.add_vertex(vertices[index]*fit-origin)
  surface.generate_tangents();surface.index()
  var piece:=surface.commit();var render:MeshInstance3D
  if section==0:
   head_body=Node3D.new();head_body.name="RigidRustcrawlerCore";add_child(head_body)
   render=visual(head_body,"SensorArmour",piece,material);mesh=render;head_bounds=measured_core;head_bounds.position*=fit;head_bounds.size*=fit
  else:
   render=visual(self,"UpperArmour" if section%2==1 else "LowerArmour",piece,material);render.position=origin
   if section%2==1:upper_parts.append(render)
   else:lower_parts.append(render)
 var bearing:=metal(Color("283337"),.38)
 for i in range(6):
  var shape:=SphereMesh.new();shape.radius=.036*fit;shape.height=shape.radius*2;shape.radial_segments=12;shape.rings=6
  visual(self,"HipJoint"+str(i),shape,bearing).position=hips[i]
  var joint:MeshInstance3D=visual(self,"KneeJoint"+str(i),shape,bearing);joint.position=knees[i];knee_parts.append(joint)
 visual_height=.66211*fit;body_radius=maxf(.22,Vector2(head_bounds.size.x,head_bounds.size.z).length()*.5+.025)
 for render in render_meshes:
  var base:StandardMaterial3D=render.material_override
  materials.append({"mesh":render,"surface":-1,"base":base,"camo":camo_material(base)})
 original.free()
func camo_material(base:StandardMaterial3D)->StandardMaterial3D:
 var copy:StandardMaterial3D=base.duplicate();copy.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 copy.albedo_color=Color(copy.albedo_color.r*.55,copy.albedo_color.g*.8,copy.albedo_color.b*.85,.14);return copy
func segment(part:MeshInstance3D,a:Vector3,b:Vector3)->void:
 var offset:Vector3=b-a
 part.position=(a+b)*.5
 part.quaternion=Quaternion(Vector3.UP,offset.normalized()).normalized()
 part.scale=Vector3(1,offset.length(),1)
func solve_leg(index:int,wanted:Vector3)->void:
 var hip:Vector3=hips[index];var knee:Vector3=knees[index]
 var upper:Vector3=knee-hip;var lower:Vector3=feet_rest[index]-knee
 var a:float=upper.length();var b:float=lower.length();var reach:Vector3=wanted-hip
 var distance:float=clampf(reach.length(),absf(a-b)+.002,a+b-.002)
 var direction:Vector3=reach.normalized() if reach.length()>.001 else Vector3.DOWN
 var end:Vector3=hip+direction*distance
 var along:float=(a*a-b*b+distance*distance)/(2*distance)
 var pole:Vector3=Vector3.UP.slide(direction).normalized()
 if pole.length()<.01:pole=Vector3.RIGHT
 var bend:Vector3=hip+direction*along+pole*sqrt(maxf(0,a*a-along*along))
 var q:=Quaternion(upper.normalized(),(bend-hip).normalized()).normalized()
 var q_lower:=Quaternion(lower.normalized(),(end-bend).normalized()).normalized()
 skeleton.set_bone_pose_rotation(1+index*2,q);skeleton.set_bone_pose_rotation(2+index*2,(q.inverse()*q_lower).normalized())
 upper_parts[index].transform=Transform3D(Basis(q),hip)
 lower_parts[index].transform=Transform3D(Basis(q_lower),bend)
 knee_parts[index].position=bend
 max_reach_error=maxf(max_reach_error,absf(hip.distance_to(bend)-a)+absf(bend.distance_to(end)-b))
func contact(index:int,body:CharacterBody3D,normal:Vector3,lead:=Vector3.ZERO)->Vector3:
 var ideal:Vector3=physics_pose*feet_rest[index]+lead
 var query:=PhysicsRayQueryParameters3D.create(ideal+normal*.5,ideal-normal*.65,1|512);query.exclude=[body.get_rid()]
 var hit:Dictionary=body.get_world_3d().direct_space_state.intersect_ray(query)
 var target:Vector3=hit.position+hit.normal*.035 if not hit.is_empty() and hit.normal.dot(normal)>.5 else ideal
 # Retract a foot at wall junctions: a support ray alone can see through a corner.
 var hip:Vector3=physics_pose*hips[index]
 var obstruction:=PhysicsRayQueryParameters3D.create(hip,target,1);obstruction.exclude=[body.get_rid()]
 var barrier:Dictionary=body.get_world_3d().direct_space_state.intersect_ray(obstruction)
 return barrier.position+barrier.normal*.045 if not barrier.is_empty() and barrier.position.distance_to(target)>.055 else target
func tick(delta:float,body:CharacterBody3D,normal:Vector3,moving:bool,unfold:=1.0,airborne:=false)->void:
 if skeleton==null:return
 physics_pose=Transform3D(body.global_basis*Basis(Vector3.UP,PI),body.global_position)
 max_reach_error=0;previous_feet_world.assign(feet_world)
 if airborne or unfold<.98:
  folded.clear()
  for i in range(6):
   folded.append(Vector3(hips[i].x*.95,.18,hips[i].z).lerp(feet_rest[i],unfold if not airborne else .60))
   progress[i]=1.0
  initialized=false;return
 var reset_contacts:bool=not initialized or physics_pose.origin.distance_to(previous_origin)>.8 or normal.dot(previous_normal)<.8
 var lead:Vector3=body.velocity.slide(normal).limit_length(2.4)*.085
 var ideals:Array[Vector3]=[]
 var stepping:=false
 for i in range(6):
  ideals.append(contact(i,body,normal,lead))
  if reset_contacts:feet_world[i]=ideals[i];previous_feet_world[i]=ideals[i];starts[i]=ideals[i];targets[i]=ideals[i];progress[i]=1.0
  if progress[i]<1:stepping=true
 if not stepping:
  var need_step:=false
  for i in range(6):
   if i%2==phase and feet_world[i].distance_to(ideals[i])>.145:need_step=true
  if need_step:
   for i in range(6):
    if i%2==phase:starts[i]=feet_world[i];targets[i]=ideals[i];progress[i]=0
   phase=1-phase;step_count+=1
 var duration:float=clampf(.42/maxf(1.5,body.velocity.slide(normal).length()),.175,.26)
 for i in range(6):
  if progress[i]<1:
   # Follow the predicted touchdown while swinging, before solving the current body pose.
   targets[i]=targets[i].lerp(ideals[i],minf(1,delta*18))
   progress[i]=minf(1,progress[i]+delta/duration)
   feet_world[i]=starts[i].lerp(targets[i],smoothstep(0,1,progress[i]))+normal*sin(progress[i]*PI)*.095
 initialized=true;previous_origin=physics_pose.origin;previous_normal=normal
func camouflage(enabled:bool)->void:
 if faded==enabled:return
 faded=enabled
 for entry in materials:
  if entry.surface<0:entry.mesh.material_override=entry.camo if enabled else entry.base
  else:entry.mesh.set_surface_override_material(entry.surface,entry.camo if enabled else entry.base)
 for render in render_meshes:render.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_ON

func render_contacts(fraction:float)->void:
 if not initialized:
  for i in range(folded.size()):solve_leg(i,folded[i])
  return
 for i in range(6):solve_leg(i,to_local(previous_feet_world[i].lerp(feet_world[i],fraction)))

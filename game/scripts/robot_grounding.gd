extends SkeletonModifier3D
## Ajuste posterior a Walk/Run originales. Usa la cadena mecánica real,
## de dos o tres tramos; Foot.L/R son controles independientes, no rodillas.
var game:Node3D
var rig:Skeleton3D
var data:Dictionary
var feet:Dictionary={}
var pose_cache:Dictionary={}
var queries_frame:=0
var contacts:=0
var timer:=0.0
var blend:=0.0
var active_profile:=false
func setup(host:Node3D,source:Dictionary)->void:
 game=host;data=source;rig=data.skeleton;process_priority=161
 for side in ["L","R"]:
  var bones:Array[int]=[]
  for prefix in ["UpperLeg.","MidLeg.","LowerLeg."]:
   var bone:=rig.find_bone(prefix+side)
   if bone>=0:bones.append(bone)
  var control:=rig.find_bone("Foot."+side)
  if bones.size()<2 or control<0:continue
  var last:Transform3D=rig.get_bone_global_rest(bones[-1]);var end:Transform3D=rig.get_bone_global_rest(control)
  var tip:Vector3=last.affine_inverse()*end.origin
  var world:Vector3=rig.global_transform*end.origin
  var sole:=clampf(world.y-game.player.global_position.y,.018,.09)
  feet[side]={"bones":bones,"tip":tip,"sole":sole,"ground":world,"normal":Vector3.UP,"valid":false,"contact":false,"planting":false,"error":0.0,"correction":0.0,"point":world,"control":control,"end":rig.find_bone("FootBack."+side),"bind":Transform3D.IDENTITY}
  if feet[side].end>=0:feet[side].bind=rig.get_bone_global_rest(feet[side].end).affine_inverse()*rig.get_bone_global_rest(control)
func permitted()->bool:
 if not is_instance_valid(game) or not is_instance_valid(rig) or not game.is_inside_tree() or not rig.is_inside_tree():return false
 var session:Node=game.online_session()
 if session!=null and not session.is_host():return false
 return bool(game.preferences.values.get("robot_grounding",true)) and game.robots.active and game.robots.current.get("skeleton") == rig and data.locomotion.tree.active and game.rig_holder.is_visible_in_tree() and not game.fusion.busy() and game.hp>0 and game.player.is_on_floor() and not game.physical_ragdoll.active and game.physical_ragdoll.recovering<=0 and not game.player_ragdoll and game.dash_time<=0 and game.attack_anim<=0 and game.robots.attack.is_empty() and game.presentation.emote_time<=0 and game.moves.player_freeze<=0
func foot_point(foot:Dictionary)->Vector3:
 return rig.global_transform*rig.get_bone_global_pose(foot.bones[-1])*foot.tip
func _physics_process(delta:float)->void:
 queries_frame=0;active_profile=permitted();active=active_profile
 if not active_profile:
  blend=0;pose_cache.clear()
  for foot in feet.values():foot.contact=false;foot.planting=false
  return
 blend=minf(1,blend+delta*8);timer+=delta
 if timer<.05:return
 timer=fmod(timer,.05)
 for foot in feet.values():
  var point:=foot_point(foot);var origin:Vector3=game.player.global_position
  var query:=PhysicsRayQueryParameters3D.create(Vector3(point.x,origin.y+.6,point.z),Vector3(point.x,origin.y-.5,point.z),1);query.exclude=[game.player.get_rid()]
  var hit:=game.get_world_3d().direct_space_state.intersect_ray(query);queries_frame+=1
  foot.valid=not hit.is_empty() and hit.normal.y>.65
  if foot.valid:
   var sample_point:Vector3=hit.position+hit.normal*foot.sole
   # Suavizar pequeñas variaciones de los rayos antes de corregir la zancada.
   foot.ground=foot.ground.lerp(sample_point,.55) if foot.contact else sample_point
   foot.normal=hit.normal
func _process_modification()->void:
 if not permitted():return
 pose_cache.clear()
 for foot in feet.values():
  var point:=foot_point(foot);foot.point=point;foot.correction=0
  if not foot.valid:foot.contact=false;foot.planting=false;continue
  var height:float=point.y-foot.ground.y
  # Histéresis: evita que la IK se conecte y desconecte en cada fotograma.
  var planted:bool=height<(.105 if foot.planting else .055) and height>-.15
  foot.planting=planted
  var target:=point
  if planted:target.y=lerpf(point.y,foot.ground.y,blend)
  if planted:
   solve_chain(foot,target);foot.point=foot_point(foot);foot.error=foot.point.distance_to(target)
  var contacting:bool=planted and foot.error<.035
  if contacting and not foot.contact:contacts+=1
  foot.contact=contacting
  for index in foot.bones:pose_cache[index]={"position":rig.get_bone_pose_position(index),"rotation":rig.get_bone_pose_rotation(index)}
 # Leela/George deforman los pies mediante controles IK independientes.
 # Deben seguir el extremo CORREGIDO antes de actualizar el skin.
 for foot in feet.values():
  if foot.end<0:continue
  var pose:Transform3D=rig.get_bone_global_pose(foot.end)*foot.bind
  rig.set_bone_pose_position(foot.control,pose.origin)
  pose_cache[foot.control]={"position":rig.get_bone_pose_position(foot.control),"rotation":rig.get_bone_pose_rotation(foot.control)}
func solve_chain(foot:Dictionary,target:Vector3,max_angle:float=.24)->void:
 var points:Array[Vector3]=[];var lengths:Array[float]=[]
 for index in foot.bones:points.append(rig.global_transform*rig.get_bone_global_pose(index).origin)
 points.append(foot_point(foot))
 var base:Vector3=points[0];var total:=0.0
 for i in range(points.size()-1):
  var length_value:float=points[i].distance_to(points[i+1]);lengths.append(length_value);total+=length_value
 if base.distance_to(target)>total-.001:target=base+(target-base).normalized()*(total-.001)
 for iteration in range(5):
  points[-1]=target
  for i in range(points.size()-2,-1,-1):points[i]=points[i+1]+(points[i]-points[i+1]).normalized()*lengths[i]
  points[0]=base
  for i in range(points.size()-1):points[i+1]=points[i]+(points[i+1]-points[i]).normalized()*lengths[i]
 for i in range(foot.bones.size()):
  var index:int=foot.bones[i];var pose:Transform3D=rig.global_transform*rig.get_bone_global_pose(index)
  var next:Vector3=rig.global_transform*rig.get_bone_global_pose(foot.bones[i+1]).origin if i<foot.bones.size()-1 else foot_point(foot)
  var from:Vector3=(next-pose.origin).normalized();var to:Vector3=(points[i+1]-pose.origin).normalized()
  if from.length_squared()<.5 or to.length_squared()<.5:continue
  var rotation:=Quaternion(from,to);var angle:float=rotation.get_angle()
  if angle>max_angle:rotation=Quaternion.IDENTITY.slerp(rotation,max_angle/angle)
  foot.correction=maxf(foot.correction,minf(angle,max_angle))
  pose.basis=Basis(rotation)*pose.basis
  rig.set_bone_global_pose(index,rig.global_transform.affine_inverse()*pose)

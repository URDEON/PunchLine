extends SkeletonModifier3D
## The Proyected: corrección posterior a sus clips, sin sustituir rig o pesos.
## Consultas en física; modificación ósea después del AnimationTree.
var game:Node3D
var rig:Skeleton3D
var feet:Dictionary={}
var phase:=0.0
var timer:=0.0
var previous:=Vector3.ZERO
var velocity:=Vector3.ZERO
var pose_cache:Dictionary={}
var queries_frame:=0
var pelvis:=-1
var spine:=-1
var arms:Array[int]=[]
var influence_weight:=0.0
var contacts:=0
var walk_period:=1.0
var run_period:=1.0
var modified_frame:=-1
func setup(host:Node3D,source:Skeleton3D)->void:
 game=host;rig=source;previous=game.player.global_position;process_priority=160
 rig.modifier_callback_mode_process=Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_PHYSICS
 game.locomotion_tree.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
 pelvis=rig.find_bone("B_Pelvis");spine=rig.find_bone("B_Spine")
 # El reloj de apoyo debe avanzar a la misma cadencia que el AnimationTree.
 var walk_clip:StringName=game.resolve_rig_animation("UnarmedStrafeForward")
 var run_clip:StringName=game.resolve_rig_animation("UnarmedRunForward")
 if game.rig_anim.has_animation(walk_clip):walk_period=maxf(.1,game.rig_anim.get_animation(walk_clip).length)
 if game.rig_anim.has_animation(run_clip):run_period=maxf(.1,game.rig_anim.get_animation(run_clip).length)
 for side in ["L","R"]:
  var bones:Array[int]=[]
  for part in ["Thigh","Calf","Foot"]:bones.append(rig.find_bone("B_"+side+"_"+part))
  if bones.min()<0:continue
  var rest:Transform3D=rig.global_transform*rig.get_bone_global_rest(bones[2])
  feet[side]={"bones":bones,"anchor":rest.origin,"normal":Vector3.UP,"ground":rest.origin,"valid":false,"stance":false,"sole":clampf(rest.origin.y-game.player.global_position.y,.035,.16),"basis":game.model.global_basis.orthonormalized().inverse()*rest.basis.orthonormalized(),"platform":null,"local":Vector3.ZERO,"last_height":0.0,"weight":0.0,"age":0.0}
  arms.append(rig.find_bone("B_"+side+"_UpperArm"))
func permitted()->bool:
 if not is_instance_valid(game) or not is_instance_valid(rig):return false
 if not game.is_inside_tree() or not rig.is_inside_tree() or game.is_queued_for_deletion() or not game.player.is_inside_tree():return false
 var session:Node=game.online_session()
 if session!=null and not session.is_host():return false
 return not game.paused and bool(game.preferences.values.human_grounding) and not game.robots.active and game.form=="BASE" and game.player.is_on_floor() and game.hp>0 and game.locomotion_tree.active and not game.player_ragdoll and game.physical_ragdoll.recovering<=0 and game.dash_time<=0 and game.skill_active=="" and game.attack_anim<=0 and game.presentation.emote_time<=0 and game.moves.player_freeze<=0
func _physics_process(delta:float)->void:
 queries_frame=0
 if not is_instance_valid(game) or not game.is_inside_tree() or not game.player.is_inside_tree():return
 var now:Vector3=game.player.global_position;var delta_position:=now-previous;previous=now
 var enabled:=permitted()
 active=enabled
 if not enabled:
  influence_weight=0;pose_cache.clear()
  for f in feet.values():f.stance=false
  return
 if delta_position.length()>2:delta_position=Vector3.ZERO
 delta_position.y=0
 velocity=velocity.lerp(delta_position/maxf(delta,.001),1-exp(-delta*12))
 influence_weight=minf(1,influence_weight+delta*7)
 var speed:=Vector2(game.player.velocity.x,game.player.velocity.z).length()
 var running:=smoothstep(2.4,4.8,speed)
 # Igualar WalkCadence y Cadence de visual_motion.gd; antes el reloj de
 # apoyos avanzaba ~2 veces más rápido que los clips y producía saltos.
 if speed>.12:
  var walk_rate:=clampf(speed/2.2,.12,1.65)/walk_period
  var run_rate:=clampf(speed/5.5,.12,1.6)/run_period
  phase=fposmod(phase+delta*lerpf(walk_rate,run_rate,running),1.0)
 timer+=delta
 if timer<.05:return
 timer=fmod(timer,.05)
 for f in feet.values():
  var foot:Vector3=rig.global_transform*rig.get_bone_global_pose(f.bones[2]).origin
  var query:=PhysicsRayQueryParameters3D.create(Vector3(foot.x,now.y+.65,foot.z),Vector3(foot.x,now.y-.6,foot.z),1);query.exclude=[game.player.get_rid()]
  var hit:=game.get_world_3d().direct_space_state.intersect_ray(query);queries_frame+=1
  f.valid=not hit.is_empty() and hit.normal.y>.65
  if f.valid:
   var measured:Vector3=hit.position+hit.normal*f.sole
   f.ground=f.ground.lerp(measured,.55) if f.stance else measured
   f.normal=hit.normal
   f.platform=hit.collider
func bone_world(index:int)->Transform3D:return rig.global_transform*rig.get_bone_global_pose(index)
func write_world(index:int,world:Transform3D)->void:rig.set_bone_global_pose(index,rig.global_transform.affine_inverse()*world)
func _process_modification()->void:
 if not is_instance_valid(rig) or not permitted():return
 var frame:=Engine.get_physics_frames()
 if modified_frame==frame:return
 modified_frame=frame;pose_cache.clear()
 var delta:=get_physics_process_delta_time()
 for side in feet:
  var f:Dictionary=feet[side];var current:=bone_world(f.bones[2])
  if not f.valid:f.stance=false;f.weight=0;continue
  var height:float=current.origin.y-f.ground.y
  var rising:float=(height-f.last_height)/maxf(delta,.001)
  f.last_height=height;f.age+=delta
  var hip:=bone_world(f.bones[0]);var knee:=bone_world(f.bones[1])
  var reach:float=hip.origin.distance_to(knee.origin)+knee.origin.distance_to(current.origin)
  if f.stance and (height>.11 or rising>.55 or f.anchor.distance_to(hip.origin)>reach*.97):
   f.stance=false;f.age=0
  elif not f.stance and f.age>.10 and height<.045 and rising<.12 and height>-.16:
   f.stance=true;f.anchor=f.ground;f.age=0;contacts+=1
   if is_instance_valid(f.platform) and f.platform is Node3D:f.local=f.platform.to_local(f.anchor)
  if f.stance and is_instance_valid(f.platform) and f.platform is Node3D:f.anchor=f.platform.to_global(f.local)
  f.weight=move_toward(float(f.weight),1.0 if f.stance else 0.0,delta*8)
  if f.weight<=0:continue
  var correction:Vector3=f.anchor-current.origin
  var flat:=Vector3(correction.x,0,correction.z).limit_length(.085)
  correction=flat+Vector3.UP*clampf(correction.y,-.10,.10)
  solve_leg(f,current.origin+correction*float(f.weight)*influence_weight,f.normal)
 for f in feet.values():
  for i in f.bones:pose_cache[i]={"position":rig.get_bone_pose_position(i),"rotation":rig.get_bone_pose_rotation(i)}
func solve_leg(f:Dictionary,target:Vector3,normal:Vector3)->void:
 var upper:int=f.bones[0];var lower:int=f.bones[1];var end:int=f.bones[2]
 var hip:=bone_world(upper);var knee:=bone_world(lower);var foot:=bone_world(end)
 var a:=hip.origin.distance_to(knee.origin);var b:=knee.origin.distance_to(foot.origin)
 var offset:=target-hip.origin;var length_value:=clampf(offset.length(),absf(a-b)+.002,a+b-.002);var direction:=offset.normalized()
 var bend:Vector3=knee.origin-hip.origin
 if bend.cross(direction).length_squared()<.00001:bend=Vector3.FORWARD.rotated(Vector3.UP,game.model.rotation.y)
 bend=(bend-direction*bend.dot(direction)).normalized()
 if bend.length()<.1:bend=game.player.global_basis.y
 var cosine:=clampf((a*a+length_value*length_value-b*b)/(2*a*length_value),-1,1)
 var goal:=hip.origin+direction*a*cosine+bend*a*sqrt(maxf(0,1-cosine*cosine))
 hip.basis=Basis(Quaternion((knee.origin-hip.origin).normalized(),(goal-hip.origin).normalized()))*hip.basis;write_world(upper,hip)
 knee=bone_world(lower);foot=bone_world(end)
 var actual_target:=hip.origin+direction*length_value
 knee.basis=Basis(Quaternion((foot.origin-knee.origin).normalized(),(actual_target-knee.origin).normalized()))*knee.basis;write_world(lower,knee)
 foot=bone_world(end)
 var level:Basis=Basis(Quaternion(Vector3.UP,normal))*game.model.global_basis.orthonormalized()*f.basis
 foot.basis=Basis(foot.basis.orthonormalized().get_rotation_quaternion().slerp(level.get_rotation_quaternion(),.35*influence_weight*float(f.weight))).scaled(foot.basis.get_scale())
 write_world(end,foot)

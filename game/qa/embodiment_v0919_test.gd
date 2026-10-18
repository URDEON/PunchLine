extends SceneTree
var game:Node3D
var rig:Node3D
var checks:=0
var passed:=0
var profile:Dictionary={}
func _initialize()->void:run.call_deferred()
func check(ok:bool,title:String)->void:
 checks+=1
 if ok:passed+=1
 print("PASS " if ok else "FAIL ",title)
func frames(n:int)->void:
 for i in range(n):await physics_frame
func clip_moves(key:StringName)->bool:
 # AnimationPlayer avanza en process, no en physics_frame. Una CPU cargada
 # puede ejecutar varios pasos físicos antes del siguiente frame visual.
 var before:float=game.rig_anim.current_animation_position
 var until:=Time.get_ticks_msec()+1000
 while Time.get_ticks_msec()<until:
  await process_frame
  if not game.rig_anim.active or game.rig_anim.current_animation!=String(key):return false
  if absf(game.rig_anim.current_animation_position-before)>.025:return true
 return false
func dance_moves(skeleton:Skeleton3D)->bool:
 var snapshot:Array=[]
 for bone in range(skeleton.get_bone_count()):snapshot.append(skeleton.get_bone_pose_rotation(bone))
 var until:=Time.get_ticks_msec()+1000
 while Time.get_ticks_msec()<until:
  await process_frame
  for bone in range(skeleton.get_bone_count()):
   if snapshot[bone].angle_to(skeleton.get_bone_pose_rotation(bone))>.02:return true
 return false
func release()->void:
 for action in ["forward","back","left","right","walk","attack","block","ability1"]:Input.action_release(action)
func relocate()->void:
 release();game.player.position=Vector3(200,.03,5);game.player.velocity=Vector3.ZERO;game.yaw=0;game.pitch=0;game.model.rotation.y=0
 if is_instance_valid(rig):rig.gait.clear()
 await frames(30)
func visibility(node:Node)->bool:
 for mesh in node.find_children("*","GeometryInstance3D",true,false):
  if mesh.is_visible_in_tree() and mesh.layers & game.camera.cull_mask != 0:return true
 return false
func run()->void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await frames(12)
 for enemy in game.enemies:game.set_dummy_mode(enemy,0)
 var floor_body:=StaticBody3D.new();floor_body.collision_layer=1;game.add_child(floor_body);floor_body.position=Vector3(200,-.1,0)
 var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(80,.2,80);col.shape=shape;floor_body.add_child(col)
 game.robots.select(1);await relocate()
 for variant in range(4):
  game.robots.forced=variant;game.robots.spawn();await relocate()
  for index in range(4):
   game.presentation.cancel_emote();await frames(2)
   var accepted:bool=game.presentation.start_emote(index)
   check(accepted,"emote "+str(index)+" aceptado para "+game.robots.NAMES[variant])
   await frames(5)
   var key:StringName=game.resolve_rig_animation(game.robots.EMOTES[index].clip)
   check(await clip_moves(key),"clip original avanza: "+game.robots.NAMES[variant]+" / "+str(index))
   if index==0:
    check(await dance_moves(game.robots.current.skeleton),"Dance deforma realmente huesos de "+game.robots.NAMES[variant])
  game.presentation.cancel_emote()
 game.charge=100;await relocate();check(game.fusion.request(),"fusión para cámara y marcha")
 game.fusion.sequence.advance(11.5);rig=game.fusion.sequence.articulation;await frames(80)
 game.zoom=0;game.update_camera(.016)
 check(not visibility(rig.pivots.Cabeza),"cabeza excluida solo de la cámara local")
 for id in ["Torso_Pecho","Pelvis","BrazoSuperior_Der","BrazoSuperior_Izq","Muslo_Der","Muslo_Izq","Pie_Der","Pie_Izq"]:
  check(visibility(rig.pivots[id]),"cuerpo visible en primera persona: "+id)
 check(rig.joint_caps.layers & game.camera.cull_mask != 0,"juntas mecánicas visibles junto al cuerpo")
 var torso:Node3D=rig.pivots.Torso_Pecho
 var eye_offset:Vector3=game.camera.global_position-rig.pivots.Cabeza.global_position
 check(eye_offset.length()<.9 and eye_offset.dot(rig.global_basis.z.normalized())>.58,"ojos siguen cabeza delante de la placa del pecho, dentro del volumen del controlador")
 game.camera_lock=true;game.yaw=.55;game.pitch=.28;var body_yaw:float=game.model.rotation.y;await frames(55)
 var desired:=Vector3.FORWARD.rotated(Vector3.RIGHT,game.pitch).rotated(Vector3.UP,game.yaw)
 check(absf(wrapf(game.model.rotation.y-body_yaw,-PI,PI))<.03,"giro corto de mirada deja caderas estables")
 check(rig.pivots.Cabeza.global_basis.z.normalized().dot(desired)>.97,"cabeza sigue yaw y pitch de la vista")
 game.yaw=2.0;await frames(75)
 check(absf(wrapf(game.yaw-game.model.rotation.y,-PI,PI))<.88,"cuerpo acompaña giros que exceden el cuello")
 check(absf(rig.head_yaw)<1.14 and absf(rig.head_pitch)<.71,"límites del cuello sin torsiones extremas")
 game.pitch=-1.2;game.update_camera(.016)
 var foot_dir:Vector3=(rig.pivots.Pie_Der.global_position-game.camera.global_position).normalized()
 check((-game.camera.global_basis.z).dot(foot_dir)>.5 and visibility(rig.pivots.Pie_Der),"al mirar abajo la cámara apunta al cuerpo visible")
 game.zoom=5.5;game.update_camera(.016)
 check(visibility(rig.pivots.Cabeza) and game.camera_view.masked.is_empty(),"tercera persona restaura cabeza y capas originales")
 game.zoom=0;await relocate()
 for action in ["forward","right","left","back"]:
  await relocate();var low:=INF;var high:=-INF;var swing_direction:=0.0;var swings:=0;var separation:=INF;var stretch:=0.0
  Input.action_press(action)
  for frame in range(160):
   await frames(1)
   if frame<30:continue
   low=minf(low,rig.pivots.BrazoSuperior_Der.rotation.z);high=maxf(high,rig.pivots.BrazoSuperior_Der.rotation.z)
   var inverse:Basis=rig.global_basis.orthonormalized().inverse()
   var span:Vector3=inverse*(rig.pivots.Pie_Der.global_position-rig.pivots.Pie_Izq.global_position);separation=minf(separation,span.x)
   for side in ["Der","Izq"]:
    var f:Dictionary=rig.gait.feet[side]
    if f.swing and f.t<.12:
     var travel:Vector3=f.to-f.from;travel.y=0
     if travel.length()>.1:swing_direction+=travel.normalized().dot(game.movement().normalized());swings+=1
    var upper:float=rig.pivots["Muslo_"+side].global_position.distance_to(rig.pivots["Rodilla_"+side].global_position)
    stretch=maxf(stretch,absf(upper-rig.rest_positions["Rodilla_"+side].length()*rig.global_basis.y.length()))
  release();profile[action]={"arm_z_range":high-low,"stride_alignment":swing_direction/maxi(1,swings),"ankle_separation":separation,"segment_error":stretch}
  check(swings>1 and swing_direction/maxi(1,swings)>.65,"pasos siguen desplazamiento real: "+action)
  check(separation>.20 and stretch<.002,"sin cruce de pies ni estiramiento: "+action)
  check(absf(wrapf(game.model.rotation.y,-PI,PI))<.03,"strafe conserva cuerpo frente a mira: "+action)
 check(profile.right.arm_z_range>profile.forward.arm_z_range+.04,"balanceo lateral se distingue de marcha frontal")
 print("DIRECTIONAL_METRICS ",JSON.stringify(profile))
 await relocate();game.presentation.cancel_emote()
 check(game.presentation.start_emote(0),"Sentinel inicia baile propio sin AnimationPlayer ficticio")
 await frames(18);var chest_before:float=rig.pivots.Torso_Pecho.rotation.y;var origin:Vector3=game.player.position
 await frames(35)
 check(rig.state=="emote" and absf(chest_before-rig.pivots.Torso_Pecho.rotation.y)>.035,"baile mueve pecho, pelvis y brazos del Sentinel")
 check(game.player.position.distance_to(origin)<.03 and rig.gait.initialized,"baile mantiene apoyo y controlador quietos")
 Input.action_press("right");await frames(5);release()
 check(game.presentation.emote_time<=0 and rig.state!="emote","mover cancela el baile y recupera locomoción")
 await relocate()
 for index in [1,2,3]:
  game.presentation.cancel_emote();await frames(3);check(game.presentation.start_emote(index),"gesto Sentinel "+str(index))
  await frames(45)
  check(rig.state=="emote" and rig.deployment<.001,"gesto no despliega cañón: "+str(index))
  await frames(180)
  check(game.presentation.emote_time<=0,"gesto termina automáticamente: "+str(index))
 check(game.presentation.start_emote(0),"baile puede reiniciarse")
 check(game.fusion.combat.punch(),"M1 permite interrumpir emote")
 check(game.presentation.emote_time<=0,"ataque cancela el emote sin bloquear combate")
 game.fusion.combat.interrupted();await frames(90);game.presentation.start_emote(0);game.stun=.3;await frames(3)
 check(game.presentation.emote_time<=0,"aturdimiento cancela el emote")
 release();game.fusion.reset();game.queue_free();await frames(8)
 print("RESULTADO ",passed,"/",checks);quit(0 if passed==checks else 1)

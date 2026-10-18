extends SceneTree
var checks:=0
var passed:=0
var game:Node3D
var modifier:SkeletonModifier3D
var max_length_error:=0.0
var max_correction:=0.0
var samples:=0
var finite:=true
var foot_connection_error:=0.0
func _initialize()->void:run.call_deferred()
func check(ok:bool,title:String)->void:
 checks+=1
 if ok:passed+=1
 print("PASS " if ok else "FAIL ",title)
func frames(n:int)->void:
 for i in range(n):await physics_frame
func release()->void:
 for name in ["forward","back","left","right","walk"]:Input.action_release(name)
func inspect()->void:
 if modifier==null or not modifier.active_profile:return
 var rig:Skeleton3D=modifier.rig
 for f in modifier.feet.values():
  max_correction=maxf(max_correction,f.correction)
  if f.end>=0:
   var actual:Vector3=rig.get_bone_global_pose(f.control).origin;var expected:Vector3=(rig.get_bone_global_pose(f.end)*f.bind).origin
   foot_connection_error=maxf(foot_connection_error,(rig.global_basis*(actual-expected)).length())
  if f.valid:samples+=1
  for i in range(f.bones.size()-1):
   var a:Transform3D=rig.global_transform*rig.get_bone_global_pose(f.bones[i]);var b:Transform3D=rig.global_transform*rig.get_bone_global_pose(f.bones[i+1])
   var ra:Transform3D=rig.global_transform*rig.get_bone_global_rest(f.bones[i]);var rb:Transform3D=rig.global_transform*rig.get_bone_global_rest(f.bones[i+1])
   max_length_error=maxf(max_length_error,absf(a.origin.distance_to(b.origin)-ra.origin.distance_to(rb.origin)));finite=finite and a.is_finite() and b.is_finite()
func run()->void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await frames(12)
 for enemy in game.enemies:game.set_dummy_mode(enemy,0)
 var floor_body:=StaticBody3D.new();floor_body.collision_layer=1;game.add_child(floor_body);floor_body.position=Vector3(200,-.1,0)
 var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(80,.2,80);col.shape=shape;floor_body.add_child(col)
 var ramp:=StaticBody3D.new();ramp.collision_layer=1;game.add_child(ramp);ramp.position=Vector3(300,.1,0);ramp.rotation.x=.10
 var ramp_col:=CollisionShape3D.new();var ramp_shape:=BoxShape3D.new();ramp_shape.size=Vector3(30,.3,30);ramp_col.shape=ramp_shape;ramp.add_child(ramp_col)
 game.robots.select(1)
 for variant in range(4):
  release();game.robots.forced=variant;game.robots.spawn();game.player.position=Vector3(200,.03,5);game.player.velocity=Vector3.ZERO;game.yaw=0;game.model.rotation.y=0;game.camera_lock=true;await frames(25)
  modifier=game.robots.current.grounding;modifier.modification_processed.connect(inspect)
  max_length_error=0;max_correction=0;samples=0;finite=true;foot_connection_error=0
  var title:String=game.robots.NAMES[variant];var expected:=3 if variant in [0,2] else 2
  check(modifier.feet.size()==2 and modifier.feet.L.bones.size()==expected,"cadena real de "+title+": "+str(expected)+" tramos")
  var position:Vector3=game.player.position;var max_rays:=0
  Input.action_press("walk");Input.action_press("forward")
  for i in range(100):await frames(1);max_rays=maxi(max_rays,modifier.queries_frame)
  release();check(game.player.position.distance_to(position)>1 and modifier.contacts>2,"caminar mantiene control y contactos: "+title)
  Input.action_press("forward");await frames(90);release();await frames(15)
  Input.action_press("right");await frames(60);release();await frames(10)
  check(max_rays<=2 and samples>20 and not modifier.pose_cache.is_empty(),"consultas acotadas y pose corregida disponible: "+title)
  check(foot_connection_error<.001,"pies visuales unidos al extremo corregido: "+title)
  check(finite and max_length_error<.0015,"articulaciones sin estiramiento ni NaN: "+title)
  check(max_correction>.001 and max_correction<=.241,"corrección real con límite de giro: "+title)
  game.player.position=Vector3(300,.8,0);game.player.velocity=Vector3.ZERO;await frames(50)
  Input.action_press("walk");Input.action_press("forward");await frames(90);release()
  check(game.player.is_on_floor() and modifier.active_profile and modifier.feet.L.valid and modifier.feet.R.valid,"apoyos sobre pendiente real: "+title)
  check(modifier.feet.L.normal.y<.999 and modifier.feet.L.normal.y>.98 and max_length_error<.0015,"normal del terreno y longitudes conservadas en pendiente: "+title)
  game.presentation.start_emote(0);await frames(3);check(not modifier.active_profile,"emote conserva clip original sin IK: "+title);game.presentation.cancel_emote();await frames(12)
  game.physical_ragdoll.start(Vector3(1,2,0),{"kind":"heavy","direction":Vector3.RIGHT});await frames(3)
  check(not modifier.active_profile,"ragdoll recibe control exclusivo del esqueleto: "+title);game.physical_ragdoll.cancel();game.player_ragdoll=false;await frames(20)
  game.preferences.values.robot_grounding=false;await frames(2);check(not modifier.active_profile,"opción permite restaurar locomoción original: "+title);game.preferences.values.robot_grounding=true
  print("ROBOT_GROUNDING ",title," ",{"samples":samples,"length_error":max_length_error,"correction":max_correction,"contacts":modifier.contacts})
  modifier.modification_processed.disconnect(inspect)
 game.robots.select(0);await frames(60);check(game.human_motion.active and not modifier.active_profile,"volver a The Proyected restaura su modificador propio")
 release();game.queue_free();await frames(8);print("RESULTADO ",passed,"/",checks);quit(0 if passed==checks else 1)

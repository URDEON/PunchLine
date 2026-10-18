extends SceneTree
var checks:=0
var passed:=0
func _initialize() -> void:run.call_deferred()
func check(ok:bool,title:String)->void:
 checks+=1
 if ok:passed+=1
 print("PASS " if ok else "FAIL ",title)
func box(parent:Node3D,position:Vector3,size:Vector3)->void:
 var body:=StaticBody3D.new();parent.add_child(body);body.position=position
 var shape:=CollisionShape3D.new();var cube:=BoxShape3D.new();cube.size=size;shape.shape=cube;body.add_child(shape)
func attempt(height:float,roof:bool=false, actor_height:float=2.0)->Dictionary:
 var world:=Node3D.new();root.add_child(world)
 box(world,Vector3(0,-.1,0),Vector3(20,.2,20))
 box(world,Vector3(0,height/2,-2),Vector3(4,height,2))
 if roof:box(world,Vector3(0,2.18,-1.2),Vector3(4,.2,2))
 var body:=CharacterBody3D.new();world.add_child(body);body.position=Vector3(0,.1,.5);body.collision_layer=2;body.collision_mask=1;body.floor_snap_length=.35
 var col:=CollisionShape3D.new();var cap:=CapsuleShape3D.new();cap.radius=1.05 if actor_height>3 else .32;cap.height=actor_height;col.shape=cap;col.position.y=actor_height*.5;body.add_child(col)
 var peak:=0.0;var stepped:=false
 for i in range(180):
  await physics_frame
  body.velocity=Vector3(0,body.velocity.y-9.8/60,-2)
  stepped=preload("res://scripts/terrain_steps.gd").prepare(body,1.0/60,.42) or stepped
  body.move_and_slide();peak=maxf(peak,body.position.y)
 var result:={"z":body.position.z,"peak":peak,"stepped":stepped}
 world.queue_free();await physics_frame;return result
func run()->void:
 for height in [.14,.3,.4]:
  var result:Dictionary=await attempt(height)
  print("STEP_DIAG ",height," ",result)
  check(result.z < -3.5,"cruza escalón de "+str(height)+" m")
  check(result.peak < height+.08,"no salta más alto que el desnivel "+str(height))
 var mega:Dictionary=await attempt(.4,false,4.0)
 check(mega.z < -3.5 and mega.peak<.48,"mega de 4 m también cruza bordillo sin saltar")
 var high:Dictionary=await attempt(.9)
 check(high.z > -1 and high.peak<.15,"no trepa paredes de altura excesiva")
 var roof:Dictionary=await attempt(.3,true)
 check(roof.z > -1 and roof.peak<.15,"no atraviesa techo al subir escalón")
 print("RESULTADO ",passed,"/",checks);quit.call_deferred(0 if passed==checks else 1)

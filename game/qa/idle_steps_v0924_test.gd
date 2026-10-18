extends SceneTree
func _initialize()->void:run.call_deferred()
func frames(n:int)->void:
 for i in range(n):await physics_frame
func run()->void:
 var game:Node3D=load("res://main.tscn").instantiate();root.add_child(game);await frames(20)
 for e in game.enemies:game.set_dummy_mode(e,0)
 game.robots.select(1);game.player.position=Vector3(0,.1,0);await frames(20);game.charge=100;game.fusion.request();game.fusion.sequence.advance(11.5);await frames(30)
 Input.action_press("forward");await frames(102);Input.action_release("forward")
 var settled:=0
 for i in range(240):
  await frames(1)
  if i==120:settled=game.fusion.step_index
  if i%30==0:
   var g=game.fusion.sequence.articulation.gait
   print("STOP_TRACE ",i," steps ",game.fusion.step_index," velocity ",game.player.velocity," gait ",g.velocity," feet ",g.feet.Der.swing," ",g.feet.Izq.swing)
 var ok:bool=settled==game.fusion.step_index
 print("PASS " if ok else "FAIL ","sin nuevos pasos después de completar apoyo")
 game.queue_free();await frames(12);print("RESULTADO ",1 if ok else 0,"/1");quit(0 if ok else 1)

extends SceneTree
var checks:=0
var passed:=0
func _initialize()->void:run.call_deferred()
func frames(n:int)->void:
 for i in range(n):await physics_frame
func check(ok:bool,title:String)->void:
 checks+=1
 if ok:passed+=1
 print("PASS " if ok else "FAIL ",title)
func wait_scene(path:String)->void:
 var until:=Time.get_ticks_msec()+15000
 while current_scene==null or current_scene.scene_file_path!=path:
  if Time.get_ticks_msec()>until:check(false,"tiempo de carga "+path);quit(1);return
  await process_frame
 for i in range(3):await process_frame
func open_scene(path:String)->void:
 change_scene_to_file(path);await wait_scene(path)
func run()->void:
 await open_scene("res://main.tscn");await frames(8)
 current_scene.interface.open_menu("test");current_scene.leave_to_main_menu();await wait_scene("res://launcher.tscn")
 check(current_scene.scene_file_path=="res://launcher.tscn","salida individual vuelve al menú principal")
 await open_scene("res://network/online.tscn")
 var arena:Node3D=current_scene;arena.session.active=true;arena.session.server=true
 arena.session.upsert_player(1,{"id":1,"nickname":"QA","character":1,"variant":1,"color":0,"slot":0,"generation":0,"spawn":Vector3(-16,.1,0),"yaw":0.0});await frames(5)
 arena.session.actors[1].leave_to_main_menu();await wait_scene("res://launcher.tscn")
 check(current_scene.scene_file_path=="res://launcher.tscn","salida online funciona aunque la sesión retire al actor del árbol")
 await open_scene("res://FusionDemo.tscn")
 var demo:Node3D=current_scene;demo.advance(11.5)
 check(demo.articulation.all_parts.size()==112,"demo G completa el ensamblaje nuevo")
 demo.play_fusion();demo.advance(11.5)
 check(demo.articulation.all_parts.size()==112,"demo G reinicia sin perder piezas originales")
 demo._return_to_menu();await wait_scene("res://launcher.tscn")
 check(current_scene.scene_file_path=="res://launcher.tscn","demo G vuelve al menú sin softlock")
 await open_scene("res://CannonDemo.tscn")
 check(current_scene.diagnostic.body==112 and current_scene.diagnostic.gun==31,"taller V8 carga ambas fuentes originales")
 var key:=InputEventKey.new();key.keycode=KEY_ESCAPE;key.pressed=true;current_scene._input(key);await wait_scene("res://launcher.tscn")
 check(current_scene.scene_file_path=="res://launcher.tscn","taller V8 permite volver con Esc")
 current_scene.queue_free();await frames(6)
 print("RESULTADO ",passed,"/",checks);quit.call_deferred(0 if passed==checks else 1)

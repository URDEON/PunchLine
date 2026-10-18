extends SceneTree
var checks:=0
var passed:=0
var game:Node3D
func _initialize()->void:run.call_deferred()
func check(ok:bool,title:String)->void:
 checks+=1
 if ok:passed+=1
 print("PASS " if ok else "FAIL ",title)
func frames(n:int)->void:
 for i in range(n):await physics_frame
func fused()->void:
 if is_instance_valid(game):game.fusion.reset();game.queue_free();await frames(3)
 game=load("res://main.tscn").instantiate();root.add_child(game);await frames(12)
 for e in game.enemies:game.set_dummy_mode(e,0)
 var floor_body:=StaticBody3D.new();floor_body.collision_layer=1;game.add_child(floor_body);floor_body.position=Vector3(200,-.1,0)
 var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(80,.2,80);col.shape=shape;floor_body.add_child(col)
 game.robots.select(1);game.player.velocity=Vector3.ZERO;game.player.position=Vector3(200,.03,0);game.charge=100;await frames(20)
 if not game.fusion.request():check(false,"preparación de fusión");quit(1);return
 game.fusion.sequence.advance(11.5);await frames(25)
func run()->void:
 await fused()
 var combat:Node3D=game.fusion.combat;check(combat.punch(),"M1 comienza con brazo derecho")
 game.fusion.damage.detach(0);combat.tick(.016)
 check(combat.current.is_empty(),"perder brazo ejecutor cancela M1 antes del contacto")
 await fused();combat=game.fusion.combat;combat.m1_next_stomp=true;check(combat.punch(),"M1 pisotón comienza")
 game.fusion.damage.detach(2);combat.tick(.016)
 check(combat.current.is_empty(),"perder pierna ejecutora cancela pisotón")
 await fused();combat=game.fusion.combat;combat.punch();game.fusion.damage.detach(1);combat.tick(.016)
 check(combat.current.get("id","")=="m1_hammer","perder brazo opuesto no cancela el puño intacto")
 await fused();game.fusion.damage.detach(2);combat=game.fusion.combat
 check(combat.press(3) and combat.current.get("limb","")=="Izq","sísmico elige pierna izquierda si falta la derecha")
 combat.interrupted();var before:int=game.fusion.step_index;game.player.velocity.x=.5;game.fusion.on_foot_contact("Der",game.player.global_position)
 check(game.fusion.step_index==before,"no hay pasos de una pierna destruida")
 var rig:Node3D=game.fusion.sequence.articulation;rig.update_joint_caps();var hidden:=true
 for i in range(rig.CAP_JOINTS.size()):
  if rig.CAP_JOINTS[i][0]=="Pie_Der":hidden=hidden and rig.joint_cap_transforms[i].basis.x.length()<.001
 check(hidden,"junta de tobillo no flota tras perder tren inferior")
 game.hp=0;game.on_player_death();var wreck:Node3D=game.fusion.wreck
 game.fusion.reset();await frames(3);check(not is_instance_valid(wreck),"reiniciar transformación libera despiece exterior al actor")
 game.queue_free();await frames(8)
 print("RESULTADO ",passed,"/",checks);quit(0 if passed==checks else 1)

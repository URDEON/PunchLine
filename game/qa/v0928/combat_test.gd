extends SceneTree
var game:Node3D
var checks:=0
var failures:=0
func _initialize():run.call_deferred()
func frames(n:int):
 for i in range(n):await physics_frame
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print('PASS ' if ok else 'FAIL ',label)
func run():
 Engine.set_meta('punchline_world',load('res://scripts/world_config.gd').DEFAULTS.duplicate())
 game=load('res://main.tscn').instantiate();root.add_child(game);await frames(30)
 for enemy in game.enemies:game.set_dummy_mode(enemy,0)
 game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
 check(game.fusion.request(),'production fusion enters combat state');game.fusion.sequence.advance(11.5);await frames(40)
 var d:Node3D=game.arena.punchline.destruction
 var wall:Dictionary={}
 for p in d.parts.values():
  if '/Walls/' in str(p.body.get_path()) and p.collision.shape is BoxShape3D and p.collision.shape.size.y>2 and p.collision.shape.size.x>1.2:wall=p;break
 var normal:Vector3=wall.body.global_basis.z.normalized()
 var point:Vector3=wall.box.get_center();point.y=.15
 game.player.global_position=point+normal*2.7;game.player.velocity=Vector3.ZERO
 game.yaw=atan2(normal.x,normal.z);game.camera_lock=true;await frames(12)
 var before:int=d.revision
 check(game.fusion.combat.press(2),'real hammer input starts against generated wall')
 await frames(135)
 check(d.revision>before and wall.broken and wall.collision.disabled,'hammer animation contact destroys physical house wall')
 d.reset_world();await frames(3)
 game.player.global_position=point+normal*7;game.player.velocity=Vector3.ZERO;game.yaw=atan2(normal.x,normal.z);game.pitch=0;await frames(15)
 before=d.revision
 check(game.fusion.combat.press(1),'real cannon deployment starts')
 game.fusion.combat.cannon_aim=wall.box.get_center()
 await frames(75);game.fusion.combat.cannon_aim=wall.box.get_center();game.fusion.combat.release_cannon();await frames(100)
 check(d.revision>before and d.damaged.size()>0,'released physical cannon projectile damages generated building')
 print('RESULT ',checks-failures,'/',checks,' real combat-to-building checks')
 game.queue_free();await frames(8);quit(1 if failures else 0)

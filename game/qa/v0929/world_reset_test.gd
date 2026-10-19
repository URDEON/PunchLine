extends SceneTree
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
 var game=load('res://main.tscn').instantiate();root.add_child(game);while game.loading:await process_frame
 await frames(25)
 for enemy in game.enemies:game.set_dummy_mode(enemy,0)
 var map:Node3D=game.arena.punchline;var d:Node3D=map.destruction
 var key:String=d.parts.keys()[0];d.damage_area(d.parts[key].box.get_center(),.1,80,Vector3.UP);await frames(2)
 check(d.parts[key].broken,'fixture destroys a real generated part')
 var options:Dictionary=map.world_settings.duplicate();options.night=not options.night
 map.rebuild_world(options);await frames(3);d=map.destruction
 var p:Dictionary=d.parts[key]
 check(not p.broken and not p.collision.disabled and p.body.collision_layer>0 and p.batch.multimesh.source_transform(p.index).basis.determinant()>0,'same geometry regenerated with new night setting restores visual and physical state')
 options.destructible=false;map.rebuild_world(options);await frames(2)
 check(not map.destruction.enabled and map.destruction.revision==0,'new destructibility setting starts a pristine world')
 print('RESULT ',checks-failures,'/',checks,' world restart checks');game.queue_free();await frames(8);quit(1 if failures else 0)

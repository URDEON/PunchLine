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
func drive(house:Node3D,target:Vector3)->bool:
 var destination:Vector3=house.to_global(target)
 for i in range(350):
  var offset:Vector3=destination-game.player.global_position;offset.y=0
  if offset.length()<.18:Input.action_release('forward');await frames(4);return true
  game.yaw=atan2(-offset.x,-offset.z);Input.action_press('forward');await physics_frame
 Input.action_release('forward')
 print('BLOCKED ',house.name,' position=',house.to_local(game.player.global_position),' target=',target)
 return false
func run():
 Engine.set_meta('punchline_world',load('res://scripts/world_config.gd').DEFAULTS.duplicate())
 game=load('res://main.tscn').instantiate();game.preferences.values.grass_quality=0;root.add_child(game)
 while game.loading:await process_frame
 for enemy in game.enemies:game.set_dummy_mode(enemy,0)
 var plan:Dictionary=load('res://scripts/world_config.gd').make_plan(load('res://scripts/world_config.gd').DEFAULTS)
 for b in plan.buildings:
  if b.access!='human_only':continue
  var house:Node3D=game.arena.punchline.housing.get_node('GeneratedBuildings/'+b.lot+'/'+b.id)
  game.player.global_position=house.to_global(Vector3(0,.025,b.depth/2+1.8));game.player.velocity=Vector3.ZERO;game.player.reset_physics_interpolation();await frames(12)
  var entered:bool=await drive(house,Vector3(0,.025,b.depth/2-1.7))
  var bedroom:bool=await drive(house,Vector3(0,.025,-b.depth/2+1.3)) if entered else false
  var exited:bool=await drive(house,Vector3(0,.025,b.depth/2+1.8)) if bedroom else false
  check(entered and bedroom and exited,'real human controller enters, crosses rooms and exits '+b.lot+'/'+b.id)
 check(not game.robots.active,'access checked with the original human character')
 print('RESULT ',checks-failures,'/',checks,' real human door and furnished-route checks')
 game.queue_free();await frames(8);quit(1 if failures else 0)

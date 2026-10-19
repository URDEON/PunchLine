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
func g(pressed:bool):
 var event:=InputEventKey.new();event.keycode=KEY_G;event.physical_keycode=KEY_G;event.pressed=pressed;Input.parse_input_event(event)
func run():
 Engine.set_meta('punchline_world',load('res://scripts/world_config.gd').DEFAULTS.duplicate())
 game=load('res://main.tscn').instantiate();game.preferences.values.grass_quality=0;root.add_child(game)
 while game.loading:await process_frame
 for enemy in game.enemies:game.set_dummy_mode(enemy,0)
 game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100;game.fusion.request();game.fusion.sequence.advance(11.5);await frames(40)
 var factory:Node3D=game.arena.punchline.housing
 factory.part(game,'CriticalTestFloor',Vector3(100,.4,100),Vector3(600,-.2,0),null)
 game.player.global_position=Vector3(600,.025,0);game.player.velocity=Vector3.ZERO;await frames(12)
 g(true);await frames(190);g(false);await frames(2)
 check(not game.self_destruct.armed and game.self_destruct.charge==0 and game.hp==300,'holding G at healthy HP cannot arm autodestruction')
 game.hp=60;await frames(3)
 check(game.self_destruct.eligible() and game.ult_msg.contains('AUTODESTRUCCIÓN DESBLOQUEADA') and game.ult_msg.contains('3 segundos'),'20 percent HP unlocks the explicit G / 3-second HUD prompt')
 g(true);await frames(110);g(false);await frames(4)
 check(not game.self_destruct.armed and game.self_destruct.charge==0,'releasing G before three seconds cancels arming')
 var victim:Dictionary=game.enemies[0];var outside:Dictionary=game.enemies[1]
 victim.body.global_position=game.player.global_position+Vector3(8,0,0);outside.body.global_position=game.player.global_position+Vector3(32,0,0)
 victim.hp=100;victim.ragdoll=false;victim.wakeup_protection=0;outside.hp=100
 g(true);await frames(181);g(false)
 check(game.self_destruct.armed and game.self_destruct.remaining>2.9,'a complete three-second hold starts the separate three-second fuse')
 check(game.self_destruct.alarm.playing and game.self_destruct.alarm.global_position.distance_to(game.player.global_position)<2 and not game.fusion.sequence.engine_voice.playing,'activation positions the audible alarm on the robot and stops the engine')
 check(not game.fusion.spider.eject(),'shutdown prevents ejecting the head to bypass autodestruction')
 await frames(80)
 check(game.hp>0 and game.self_destruct.armed and game.player.velocity.slide(Vector3.UP).length()<.01,'robot remains powered down while the fuse counts down')
 check(game.fusion.sequence.articulation.pivots.Rodilla_Der.rotation.x>.8,'shutdown visibly bends the mecha knees')
 await frames(102)
 check(game.self_destruct.detonations==1 and game.hp==0 and game.fusion.death_broken,'one detonation destroys the actor through its normal death path')
 check(victim.hp==0 and victim.ragdoll and victim.ragdoll_time>0,'super-explosion applies lethal nearby damage and ragdoll')
 check(outside.hp==100,'blast does not damage actors outside its radius')
 check(is_instance_valid(game.fusion.wreck) and game.fusion.wreck.bodies.size()>0,'detonation creates the real physical mecha wreck')
 await frames(260)
 check(game.hp>0 and not game.fusion.fused and not game.self_destruct.armed,'normal respawn clears the armed state and alarm')
 print('RESULT ',checks-failures,'/',checks,' critical hold, shutdown, explosion and respawn checks')
 game.queue_free();await frames(8);quit(1 if failures else 0)

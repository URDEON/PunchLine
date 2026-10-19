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
 game=load('res://main.tscn').instantiate();game.preferences.values.grass_quality=0;root.add_child(game)
 while game.loading:await process_frame
 for enemy in game.enemies:game.set_dummy_mode(enemy,0)
 game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100;game.fusion.request();game.fusion.sequence.advance(11.5);await frames(40)
 var factory:Node3D=game.arena.punchline.housing
 factory.part(game,'AudioCameraFloor',Vector3(60,.4,60),Vector3(600,-.2,0),null)
 game.player.global_position=Vector3(600,.025,0);game.player.velocity=Vector3.ZERO;game.yaw=0;game.camera_lock=true;await frames(15)
 game.feedback.audio_events.clear();var contacts_before:int=game.fusion.sequence.articulation.gait.steps
 Input.action_press('forward');await frames(220);Input.action_release('forward');await frames(40)
 var steps:Array=[];var one_shot:=true
 for event in game.feedback.audio_events:
  if String(event.id).begins_with('mecha_step_'):steps.append(event)
 for key in game.feedback.MECHA_REFERENCES:
  if key.begins_with('mecha_step_'):one_shot=one_shot and game.feedback.MECHA_REFERENCES[key].loop_mode==AudioStreamWAV.LOOP_DISABLED and game.feedback.MECHA_REFERENCES[key].get_length()<.6
 check(steps.size()>=3 and steps.size()<=16 and one_shot,'walking emits short one-shot contact samples with no looping movement intro')
 var synced:bool=game.fusion.sequence.articulation.gait.steps-contacts_before>=steps.size()
 check(synced,'footstep audio count follows real IK foot plants')
 var before:int=game.feedback.played;await frames(120)
 check(game.feedback.played==before,'standing still does not repeat mechanical footsteps')
 game.feedback.sound('block',game.player.global_position)
 check(float(game.feedback.audio_events[-1].volume_db)<=-20,'shield reference is reduced by twelve decibels at the mixer')
 check(game.fusion.spider.eject(),'spider ejects for unlocked camera and gait checks');await frames(150)
 var spider:Node3D=game.fusion.spider
 game.player.global_position=Vector3(600,.035,6);game.player.velocity=Vector3.ZERO;spider.normal=Vector3.UP;spider.forward=Vector3.FORWARD;spider.view_forward=Vector3.FORWARD;game.yaw=0;spider.previous_yaw=0;game.camera_lock=true
 var key:=InputEventKey.new();key.keycode=KEY_C;key.pressed=true;game._unhandled_input(key)
 check(not game.camera_lock,'C disables spider camera lock through the actual input handler')
 var facing:Vector3=spider.forward;game.yaw=PI*.55;await frames(20)
 check(spider.forward.dot(facing)>.99 and spider.view_forward.dot(facing)<.2,'free camera rotates without dragging the idle spider body')
 var start:=Time.get_ticks_msec();var groups:int=spider.rig.step_count
 Input.action_press('forward');var max_error:=0.0
 for i in range(150):
  await physics_frame;max_error=maxf(max_error,spider.rig.max_reach_error)
 Input.action_release('forward');await frames(8)
 var cycles:int=spider.rig.step_count-groups
 check(cycles>=5 and cycles<=18 and max_error<.001,'slower alternating tripods maintain rigid leg lengths without rapid cycling')
 await process_frame
 check(spider.rig.global_position.distance_to(game.player.get_global_transform_interpolated().origin)<.002,'rendered head follows the same interpolated body as the camera')
 var max_radius:=0.0
 var bounds:AABB=spider.rig.head_bounds
 for x in [bounds.position.x,bounds.end.x]:
  for z in [bounds.position.z,bounds.end.z]:max_radius=maxf(max_radius,Vector2(x,z).length())
 check(spider.collider.radius>=max_radius,'armour corners fit inside the physical body collision volume')
 print('AUDIO_GAIT_STATS steps=',steps.size(),' tripod_groups=',cycles,' max_ik_error=',max_error,' required_radius=',max_radius,' collider=',spider.collider.radius)
 print('RESULT ',checks-failures,'/',checks,' gait, camera unlock and mechanical audio checks')
 game.queue_free();await frames(8);quit(1 if failures else 0)

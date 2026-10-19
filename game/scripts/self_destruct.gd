extends Node3D
## Host owns the hold, shutdown timer and blast damage. Replicas only display it.
const HOLD:=3.0
const FUSE:=3.0
var game:Node3D
var charge:=0.0
var remaining:=0.0
var armed:=false
var revision:=0
var detonations:=0
var alarm:AudioStreamPlayer3D
var shutdown_origin:=Vector3.ZERO
func setup(host:Node3D)->void:
 game=host;name="CriticalSelfDestruct"
 alarm=AudioStreamPlayer3D.new();alarm.bus="SFX";alarm.volume_db=-14;alarm.unit_size=7;alarm.max_distance=65
 add_child(alarm);alarm.stream=alarm_stream()
func eligible()->bool:
 return game.hp>0 and game.hp<=game.max_hp*.20 and game.robots.active and not game.fusion.cinematic and not game.fusion.spider.active() and not game.fusion.death_broken
func held()->bool:
 if "input_state" in game:return game.input_pressed("self_destruct")
 return Input.is_physical_key_pressed(KEY_G) and not game.paused and not game.hud_cursor and not game.interface.emote_wheel.visible
func message()->String:
 if armed:return "AUTODESTRUCCIÓN · NÚCLEO APAGADO · %.1f s"%remaining
 if eligible():return "AUTODESTRUCCIÓN DESBLOQUEADA · mantén G por 3 segundos"+(" · %.1f / 3 s"%charge if charge>0 else "")
 return ""
func reset()->void:
 charge=0;remaining=0;armed=false
 if is_instance_valid(alarm):alarm.stop()
func tick(delta:float)->bool:
 if game.hp<=0:reset();return false
 if not armed:
  if not eligible() or not held():charge=0;return false
  if game.stun>0 or game.player_ragdoll or game.moves.player_freeze>0:charge=0;return false
  charge=minf(HOLD,charge+delta)
  if charge<HOLD-.0001:return false
  arm()
 remaining=maxf(0,remaining-delta)
 shutdown(delta)
 if remaining<=0:explode()
 return true
func arm()->void:
 armed=true;remaining=FUSE;revision+=1;shutdown_origin=game.player.global_position
 game.fusion.combat.interrupted();game.fusion.boost_time=0;game.dash_time=0
 game.presentation.cancel_emote();game.robots.cancel();game.attack_anim=0;game.block=false
 game.attack_buffer=0;game.ability_buffer=0;game.jump_buffer=0
 alarm.global_position=game.player.global_position+Vector3.UP*1.5
 alarm.play()
func shutdown(delta:float)->void:
 if game.hp<=0:return
 alarm.global_position=game.player.global_position+Vector3.UP*1.5
 game.player.velocity=Vector3(0,game.player.velocity.y-game.GRAVITY*delta,0);game.player.move_and_slide()
 if game.fusion.fused and is_instance_valid(game.fusion.sequence):
  var sequence:Node3D=game.fusion.sequence;sequence.set_engine_active(false)
  sequence.global_position=game.player.global_position;sequence.rotation.y=game.model.rotation.y
  var art:Node3D=sequence.articulation
  art.gait_enabled=false;art.gait.initialized=false;art.confinement_state={};art.action={};art.guarding=false;art.boosting=false
  var pose:Dictionary=art.angles();var k:float=smoothstep(0,1,(FUSE-remaining)/1.1)
  for side in ["Der","Izq"]:
   pose["Muslo_"+side].x=-1.1*k;pose["Rodilla_"+side].x=2.1*k;pose["Pie_"+side].x=-.18*k
   pose["BrazoSuperior_"+side].x=.24*k;pose["Antebrazo_"+side].x=.20*k
  pose.Torso_Abdomen.x=.30*k;pose.Torso_Pecho.x=.26*k;pose.Cabeza.x=.5*k
  art.apply_pose(pose,Vector3(0,-1.05*k/maxf(.1,art.global_basis.y.length()),0),delta)
 elif game.robots.active and game.robots.current.has("skeleton"):
  game.robots.stop_locomotion();game.rig_anim.active=false
  var skeleton:Skeleton3D=game.robots.current.skeleton
  var k:float=smoothstep(0,1,(FUSE-remaining)/1.0)
  for pair in [["UpperLeg.L",-.8],["UpperLeg.R",-.8],["LowerLeg.L",1.5],["LowerLeg.R",1.5],["Torso",.3],["Head",.4]]:
   var index:int=skeleton.find_bone(pair[0])
   if index>=0:skeleton.set_bone_pose_rotation(index,Quaternion(Vector3.RIGHT,float(pair[1])*k))
func explode()->void:
 var center:Vector3=game.player.global_position+Vector3.UP*(1.6 if game.fusion.fused else .9)
 var radius:float=23.0 if game.fusion.fused else 15.0
 armed=false;alarm.stop();detonations+=1
 game.skill_vfx.mega_event("critical_blast",center,Vector3.UP,"self_destruct",revision)
 game.feedback.sound("burst",center,0)
 var map:Node3D=game.arena.punchline
 if is_instance_valid(map.destruction):map.destruction.damage_area(center,radius,420,Vector3.UP)
 for enemy in game.enemies:
  if float(enemy.hp)<=0:continue
  var target:Vector3=enemy.body.global_position+Vector3.UP
  var separation:float=target.distance_to(center)
  if separation>radius:continue
  var direction:Vector3=(target-center).slide(Vector3.UP).normalized()
  if direction.length()<.01:direction=Vector3.FORWARD
  var amount:float=lerpf(240 if game.fusion.fused else 160,45,clampf(separation/radius,0,1))
  if game.online_session()!=null:
   var victim:Node3D=game.session.actors.get(int(enemy.peer))
   if victim!=null:victim.receive_hit(game,{"damage":amount,"force":24.0,"vertical":11.0,"stun":1.5,"ragdoll":3.0,"kind":"uppercut","direction":direction,"unblockable":true,"audio":"burst"})
  else:game.perform_hit(enemy,amount,0,direction,24,11,1.5,3.0,false,true,"burst")
 game.charge=0;game.hp=0;game.on_player_death()
 if is_instance_valid(game.fusion.wreck):
  for body in game.fusion.wreck.bodies:
   var radial:Vector3=(body.global_position-center).normalized();body.linear_velocity=radial*12+Vector3.UP*7
func state()->Dictionary:return {"charge":charge,"remaining":remaining,"armed":armed,"revision":revision}
func accept(data:Dictionary)->void:
 var was:bool=armed
 charge=float(data.get("charge",0));remaining=float(data.get("remaining",0));armed=bool(data.get("armed",false));revision=int(data.get("revision",0))
 if armed:alarm.global_position=game.player.global_position+Vector3.UP*1.5
 if armed and not was:alarm.play(maxf(0,FUSE-remaining))
 if not armed and was:alarm.stop()
 # The host streams the skeleton pose. Never run movement or damage on a replica.
 if armed and is_instance_valid(game.fusion.sequence):game.fusion.sequence.set_engine_active(false)
func alarm_stream()->AudioStreamWAV:
 var rate:=22050;var pcm:=PackedByteArray();pcm.resize(int(FUSE*rate)*2)
 for i in range(int(FUSE*rate)):
  var t:float=float(i)/rate;var beat:float=fmod(t,.48)
  var envelope:float=clampf(minf(beat/.012,(.32-beat)/.04),0,1)
  var tone:float=sin(TAU*(780 if beat<.16 else 1040)*t)*.26*envelope
  pcm.encode_s16(i*2,int(tone*32767))
 var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=rate;stream.data=pcm;stream.loop_mode=AudioStreamWAV.LOOP_DISABLED;return stream

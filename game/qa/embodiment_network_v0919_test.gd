extends SceneTree
var checks:=0
var passed:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,title:String)->void:
 checks+=1
 if ok:passed+=1
 print("PASS " if ok else "FAIL ",title)
func frames(n:int)->void:
 for i in range(n):await physics_frame
func run()->void:
 var arena:Node3D=load("res://network/online.tscn").instantiate();root.add_child(arena);arena.session.active=true;arena.session.server=true
 for index in range(2):
  arena.session.upsert_player(index+1,{"id":index+1,"nickname":"Piloto"+str(index),"character":1,"variant":index,"color":0,"slot":index,"generation":0,"spawn":Vector3(-16+index*24,.1,0),"yaw":0.0})
 await frames(15)
 var host:Node3D=arena.session.actors[1];var guest:Node3D=arena.session.actors[2]
 arena.session.apply_action(2,1,"emote:0");await frames(12)
 check(guest.presentation.emote_time>0 and host.presentation.emote_time<=0,"invitado 2 inicia su emote sin modificar anfitrión")
 var before:float=guest.rig_anim.current_animation_position;await frames(8)
 check(guest.rig_anim.active and absf(guest.rig_anim.current_animation_position-before)>.04,"emote de invitado avanza el clip real")
 var pose:Dictionary=guest.make_snapshot()
 check(pose.rotations.size()==guest.skeleton.get_bone_count() and pose.rotations.size()>5 and pose.full.presentation.emote_time>0,"snapshot del invitado incluye huesos y estado del emote")
 guest.presentation.cancel_emote();guest.charge=100;check(guest.fusion.request(),"invitado activa Sentinel")
 guest.fusion.sequence.advance(11.5);await frames(15)
 arena.session.apply_input(2,1,Vector2.ZERO,.5,16,.8);await frames(6)
 check(is_equal_approx(guest.pitch,.8),"primera persona online conserva pitch de mirada hacia arriba")
 arena.session.apply_action(2,2,"emote:0");await frames(25)
 check(guest.presentation.emote_time>0 and guest.fusion.sequence.articulation.state=="emote","baile procedural del Sentinel del invitado")
 var snapshot:Dictionary=guest.make_snapshot();var data:Dictionary=snapshot.full.fusion
 check(data.emote.index==0 and data.emote.time>.2 and data.view.y>.79,"snapshot transporta mirada y reloj del emote")
 check(var_to_bytes([snapshot,snapshot,snapshot]).size()<65536,"tres jugadores siguen dentro del límite de estado")
 var viewport:=SubViewport.new();viewport.own_world_3d=true;root.add_child(viewport)
 var remote:Node3D=load("res://network/online.tscn").instantiate();viewport.add_child(remote);remote.session.active=true;remote.session.server=false;remote.session.upsert_player(2,guest.metadata);await frames(3)
 var copy:Node3D=remote.session.actors[2];copy.accept_snapshot(1,snapshot)
 for i in range(12):copy.interpolate_state(.016)
 var rig:Node3D=copy.fusion.sequence.articulation
 check(rig.state=="emote" and rig.emote_state.index==0,"réplica muestra el mismo emote del Sentinel")
 check(rig.gait.queries_total==0,"emote replicado no duplica consultas físicas")
 guest.camera_lock=true;guest.presentation.cancel_emote();arena.session.apply_input(2,2,Vector2.ZERO,.5,16,.3);await frames(20)
 snapshot=guest.make_snapshot();copy.accept_snapshot(2,snapshot)
 for i in range(30):copy.interpolate_state(.016)
 var expected:Vector3=Vector3.FORWARD.rotated(Vector3.RIGHT,.3).rotated(Vector3.UP,.5)
 check(rig.emote_state.is_empty() and rig.pivots.Cabeza.global_basis.z.normalized().dot(expected)>.95,"fin de emote y mirada independiente replicados")
 var host_layers:Array=[]
 for mesh in guest.fusion.visual().find_children("*","GeometryInstance3D",true,false):host_layers.append([mesh,mesh.layers])
 remote.camera_view.update(copy,remote.camera,0,.5,.3,.016)
 var unchanged:=true
 for entry in host_layers:unchanged=unchanged and entry[0].layers==entry[1]
 check(unchanged,"máscara de cabeza del cliente no modifica otro actor")
 remote.camera_view.restore();remote.session.leave();viewport.queue_free();arena.session.leave();arena.queue_free();await frames(8)
 print("RESULTADO ",passed,"/",checks);quit(0 if passed==checks else 1)

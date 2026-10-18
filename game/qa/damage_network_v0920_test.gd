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
func center(damage:Node,index:int)->Vector3:
 var point:=Vector3.ZERO;var count:=0
 for mesh in damage.sources[index]:
  if is_instance_valid(mesh) and mesh.is_visible_in_tree():point+=mesh.global_transform*mesh.get_aabb().get_center();count+=1
 return point/maxi(1,count)
func run()->void:
 var arena:Node3D=load("res://network/online.tscn").instantiate();root.add_child(arena);arena.session.active=true;arena.session.server=true
 for id in range(1,4):arena.session.upsert_player(id,{"id":id,"nickname":"Piloto"+str(id),"character":1 if id<3 else 0,"variant":id-1,"color":0,"slot":id-1,"generation":0,"spawn":Vector3(-16+id*12,.1,0),"yaw":0.0})
 await frames(20)
 var actor:Node3D=arena.session.actors[2];var human:Node3D=arena.session.actors[3]
 actor.charge=100;check(actor.fusion.request(),"jugador 2 activa fusión real");actor.fusion.sequence.advance(11.5);await frames(25)
 actor.hp-=70;actor.fusion.damage.record(70,center(actor.fusion.damage,0));await frames(3)
 check(actor.fusion.damage.missing(0) and not actor.fusion.combat.press(1),"anfitrión valida pérdida de cañón del invitado")
 actor.camera_lock=false;actor.yaw=.5;await frames(15)
 var snapshot:Dictionary=actor.make_snapshot()
 check(not snapshot.full.fusion.view_locked and snapshot.full.fusion.damage.lost==1,"estado incluye lock y módulo destruido")
 var viewport:=SubViewport.new();viewport.own_world_3d=true;root.add_child(viewport)
 var remote:Node3D=load("res://network/online.tscn").instantiate();viewport.add_child(remote);remote.session.active=true;remote.session.server=false;remote.session.upsert_player(2,actor.metadata);await frames(5)
 var copy:Node3D=remote.session.actors[2];copy.accept_snapshot(1,snapshot)
 for i in range(15):copy.interpolate_state(.016)
 var rig:Node3D=copy.fusion.sequence.articulation
 check(copy.fusion.damage.missing(0) and not rig.pivots.BrazoSuperior_Der.visible,"réplica oculta el mismo brazo")
 check(copy.fusion.damage.bodies.has(0) and copy.fusion.damage.bodies[0].freeze and copy.fusion.damage.bodies[0].collision_layer==0,"cliente interpola restos sin duplicar física")
 check(not rig.tracking_view and rig.gait.queries_total==0,"sin lock y sin consultas de pies duplicadas en cliente")
 var body:RigidBody3D=copy.fusion.damage.bodies[0];var expected:Transform3D=snapshot.full.fusion.damage.parts[0].body
 check(body.global_position.distance_to(expected.origin)<.03,"posición mundial de la pieza se replica")
 actor.camera_lock=true;actor.pitch=.3;await frames(30);snapshot=actor.make_snapshot();copy.accept_snapshot(2,snapshot)
 for i in range(35):copy.interpolate_state(.016)
 check(rig.tracking_view and absf(rig.head_pitch)>.1,"lock y cabeza independientes se sincronizan")
 check(not human.human_motion.pose_cache.is_empty(),"pose final humana disponible en el servidor")
 var human_state:Dictionary=human.make_snapshot();var bones_ok:=true
 for index in human.human_motion.pose_cache:bones_ok=bones_ok and human_state.rotations[index].is_equal_approx(human.human_motion.pose_cache[index].rotation)
 check(bones_ok,"snapshot incluye los apoyos corregidos de The Proyected")
 for index in [1,2,3]:actor.fusion.damage.detach(index)
 snapshot=actor.make_snapshot();var size:int=var_to_bytes([snapshot,snapshot,snapshot]).size()
 check(size<65536,"tres mechas con cuatro piezas perdidas caben en estado de red (%d bytes)"%size)
 copy.accept_snapshot(3,snapshot)
 for i in range(10):copy.interpolate_state(.016)
 check(copy.fusion.damage.lost==15 and copy.fusion.damage.bodies.size()==4,"cuatro pérdidas replicadas sin volver a crear piezas anteriores")
 actor.hp=0;actor.on_player_death();await frames(2);snapshot=actor.make_snapshot();copy.accept_snapshot(4,snapshot);copy.interpolate_state(.016)
 check(actor.hp==0 and actor.death_timer>=3 and copy.fusion.death_broken,"muerte y espera se replican")
 await frames(165);check(actor.hp==0,"invitado no reaparece durante retirada de restos")
 await frames(100);check(arena.session.actors[2].hp>0 and not arena.session.actors[2].fusion.fused,"invitado recupera controlador después de limpieza")
 remote.session.leave();viewport.queue_free();arena.session.leave();arena.queue_free();await frames(8)
 print("RESULTADO ",passed,"/",checks);quit(0 if passed==checks else 1)

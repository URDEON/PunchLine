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
func spec(variant:int,generation:int)->Dictionary:
 return {"id":2,"nickname":"Invitado","character":1,"variant":variant,"color":0,"slot":1,"generation":generation,"spawn":Vector3(-16,.1,0),"yaw":0.0}
func run()->void:
 var arena:Node3D=load("res://network/online.tscn").instantiate();root.add_child(arena);arena.session.active=true;arena.session.server=true
 for variant in range(4):
  arena.session.upsert_player(2,spec(variant,variant));await frames(30)
  var actor:Node3D=arena.session.actors[2];var grounding:SkeletonModifier3D=actor.robots.current.grounding
  check(grounding.active_profile and not grounding.pose_cache.is_empty(),"apoyos autoritativos de "+actor.robots.NAMES[variant])
  var pose:Dictionary=actor.make_snapshot();var correct:=true
  for index in grounding.pose_cache:correct=correct and pose.rotations[index].is_equal_approx(grounding.pose_cache[index].rotation)
  check(correct,"snapshot contiene pose final de "+actor.robots.NAMES[variant])
 var host:Node3D=arena.session.actors[2];host.charge=100;check(host.fusion.request(),"invitado inicia fusión");host.fusion.sequence.advance(11.5);await frames(25)
 var snapshot:Dictionary=host.make_snapshot();var viewport:=SubViewport.new();viewport.own_world_3d=true;root.add_child(viewport)
 var remote:Node3D=load("res://network/online.tscn").instantiate();viewport.add_child(remote);remote.session.active=true;remote.session.server=false;remote.session.upsert_player(2,host.metadata);await frames(5)
 var copy:Node3D=remote.session.actors[2];copy.accept_snapshot(1,snapshot);copy.interpolate_state(.016)
 var capsule:Shape3D=copy.robots.naoya.collision.shape;var stable:=true
 for i in range(90):copy.interpolate_state(.016);stable=stable and copy.robots.naoya.collision.shape==capsule
 check(stable,"réplica reutiliza su cápsula y no crea una por fotograma")
 check(not copy.robots.current.grounding.active_profile and copy.robots.current.grounding.queries_frame==0,"cliente no duplica consultas ni mezcla IK con poses de red")
 host.fusion.combat.press(1);host.fusion.combat.elapsed=.2;host.fusion.combat.update_cannon()
 check(host.fusion.combat.aim_laser.visible,"láser real visible al preparar cañón")
 host.hp=0;host.on_player_death()
 check(not host.fusion.combat.aim_laser.visible and not host.fusion.combat.aim_spot.visible,"muerte oculta láser y punto de mira inmediatamente")
 await frames(125);snapshot=host.make_snapshot();copy.accept_snapshot(2,snapshot);copy.interpolate_state(.016)
 check(copy.fusion.death_broken and not copy.fusion.visual().visible,"estado tardío mantiene cuerpo desarmado y oculto")
 check(copy.fusion.wreck.remaining<=host.fusion.wreck.remaining+.08 and copy.fusion.wreck.remaining>0,"réplica tardía usa duración restante del despiece")
 check(copy.fusion.death_wait<=host.fusion.death_wait+.08,"réplica no reinicia espera de muerte de 3,85 s")
 check(copy.player.collision_layer==0 and copy.fusion.hurt_area.collision_layer==0,"replicar cadáver no restaura colisiones de personaje vivo")
 var old_wreck:Node3D=copy.fusion.wreck;remote.session.upsert_player(2,spec(0,4));await frames(5)
 check(not is_instance_valid(old_wreck),"cambio de generación elimina despiece exterior anterior")
 remote.session.leave();viewport.queue_free();arena.session.leave();arena.queue_free();await frames(8)
 print("RESULTADO ",passed,"/",checks);quit(0 if passed==checks else 1)

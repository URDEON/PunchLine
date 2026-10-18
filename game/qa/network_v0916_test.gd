extends SceneTree
var arena: Node3D
var checks := 0
var passed := 0
func _initialize() -> void: run.call_deferred()
func frames(n: int) -> void:
 for i in range(n): await physics_frame
func check(ok: bool,title: String) -> void:
 checks+=1
 if ok:passed+=1
 print("PASS " if ok else "FAIL ",title)
func run() -> void:
 arena=load("res://network/online.tscn").instantiate();root.add_child(arena)
 arena.session.active=true;arena.session.server=true
 for i in range(3):arena.session.upsert_player(i+1,{"id":i+1,"nickname":"QA"+str(i+1),"character":1 if i<2 else 0,"variant":i,"color":0,"slot":i,"generation":0,"spawn":Vector3(-16+i*12,.1,0),"yaw":0.0})
 await frames(10)
 var p:Node3D=arena.session.actors[1];var p2:Node3D=arena.session.actors[2];var naoya:Node3D=arena.session.actors[3]
 # Replica without local physics must use the authoritative grounded flag.
 arena.session.server=false;p2.grounded=true;p2.player.position.y=10
 p2.interface.toggle_emotes()
 check(p2.interface.emote_wheel.visible,"cliente abre B usando suelo replicado, sin requerir física local")
 p2.interface.close_emotes();arena.session.server=true;p2.player.position=Vector3(-4,.1,0);await frames(8)
 arena.session.apply_action(2,1,"emote:0");await frames(4)
 check(p2.presentation.emote_time>0 and p.presentation.emote_time==0,"emote jugador 2 ejecutado por autoridad en el jugador correcto")
 var emote_snapshot:Dictionary=p2.make_snapshot()
 check(emote_snapshot.full.presentation.emote_time>0,"emote del invitado se incluye en snapshot")
 p2.presentation.cancel_emote();p2.player.position=Vector3(25,.1,0)
 p.charge=100;check(p.fusion.request(),"fusión online preparada")
 p.fusion.sequence.advance(11.5);await frames(4)
 p.spawn_protection=0;p.stun=0;p.hp=300
 # Naoya glass bypasses M1 super armour, while ordinary M1 still does not.
 p.fusion.combat.punch();naoya.refresh_targets();naoya.moves.freeze_enemy(naoya.proxies[1],5)
 check(p.moves.player_freeze>4.9 and not p.fusion.visual().visible,"vidrio de Naoya afecta mega incluso durante su M1 protegido")
 await frames(3)
 check(p.fusion.combat.current.is_empty(),"cristalización interrumpe el ataque sin alterar protección contra M1")
 p.moves.break_player_frame("hit");await frames(4)
 # Held input lives on authority; clients do not decide target or damage.
 p.player.position=Vector3(-16,.1,0);p.player.velocity=Vector3.ZERO;p.yaw=0;p.camera_lock=true;p.pitch=-.24;p.dash_cd=0
 p.stun=0;p.attack_anim=0;p.block=false;await frames(5)
 var seq:int=p.input_state.seq
 arena.session.apply_input(1,seq+1,Vector2(.3,0),0,8,-.24);arena.session.apply_action(1,2,"ability1")
 for i in range(90):
  if i%6==0:arena.session.apply_input(1,seq+2+i,Vector2(.3,0),0,8,-.24)
  await frames(1)
 check(p.fusion.combat.cannon_phase=="hold" and p.fusion.combat.projectiles.is_empty(),"autoridad mantiene cañón mientras bit de entrada está pulsado")
 check(p.player.position.x>-15.7,"se permite caminar durante despliegue online")
 var snapshot:Dictionary=p.make_snapshot()
 check(snapshot.full.fusion.combat.deploy>.99 and snapshot.full.fusion.combat.cannon_phase=="hold","snapshot contiene transformación y fase de carga")
 var viewport:=SubViewport.new();viewport.own_world_3d=true;root.add_child(viewport)
 var remote:Node3D=load("res://network/online.tscn").instantiate();viewport.add_child(remote)
 remote.session.active=true;remote.session.server=false;remote.session.upsert_player(1,p.metadata);await frames(3)
 var copy:Node3D=remote.session.actors[1];copy.accept_snapshot(1,snapshot);copy.interpolate_state(.05)
 check(copy.fusion.fused and copy.fusion.sequence.articulation.all_parts.size()==112,"réplica construye Junkyard con sus piezas originales")
 check(copy.fusion.sequence.articulation.deployment>.99 and copy.fusion.combat.aim_laser.visible,"réplica muestra mismo cañón desplegado y láser")
 check(not copy.physical_ragdoll.active,"cliente no simula segundo ragdoll autoritativo")
 arena.session.apply_action(1,3,"cannon_release");await frames(4)
 check(p.fusion.combat.cannon_phase=="retract" and p.fusion.combat.cooldowns[0]>1.8,"soltar online dispara y replica cooldown de dos segundos")
 p.hp=0;p.fusion.break_apart();snapshot=p.make_snapshot();copy.accept_snapshot(2,snapshot);copy.interpolate_state(.05)
 check(copy.fusion.death_broken and not copy.fusion.visual().visible,"desarme de muerte se replica al cliente")
 remote.session.leave();viewport.queue_free();arena.session.leave();arena.queue_free();await frames(8)
 print("RESULTADO ",passed,"/",checks);quit.call_deferred(0 if passed==checks else 1)

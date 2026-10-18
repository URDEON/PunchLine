extends SceneTree
var arena: Node3D
var role: String
var root_dir: String
var checks := 0
var passed := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, title: String) -> void:
 checks += 1
 if ok: passed += 1
 print('PASS ' if ok else 'FAIL ',title)
func pause(seconds: float) -> void: await create_timer(seconds).timeout
func run() -> void:
 role = OS.get_environment('NAOYA_NET_ROLE'); root_dir = OS.get_environment('NAOYA_NET_OUTPUT')
 arena = load('res://network/online.tscn').instantiate(); root.add_child(arena)
 await pause(.2)
 if role == 'host': arena.session.host_game('Export host',0,17900)
 else: arena.session.join_game('127.0.0.1',17900,role,1 if role=='client1' else 0)
 var end := Time.get_ticks_msec()/1000.0+15
 while arena.session.actors.size()!=3 and Time.get_ticks_msec()/1000.0<end: await pause(.05)
 check(arena.session.actors.size()==3,'tres jugadores desde PCK exportado')
 if arena.session.actors.size()!=3: finish(); return
 check(arena.camera!=null and arena.map.collision_count>0,'mapa/cámara exportados')
 for actor in arena.session.actors.values(): check(actor.skeleton.get_bone_count()>0 and actor.rig_anim.get_animation_list().size()>0,'rig y animaciones de '+str(actor.peer_id))
 if role=='host':
  var ids: Array=arena.session.actors.keys(); ids.erase(1); ids.push_front(1)
  var target: Node3D=arena.session.actors[ids[1]]
  arena.session.actors[1].player.position=Vector3(0,.3,4);target.player.position=Vector3(0,.3,1.6)
  arena.session.actors[ids[2]].player.position=Vector3(6,.3,4)
  arena.session.actors[1].model.rotation.y=0; target.spawn_protection=0
  await pause(.3); arena.session.local_input(Vector2.ZERO,0,0); arena.session.local_action('attack'); await pause(.4)
  check(target.hp==95,'contacto M1 en aplicación exportada')
  for variant in range(4):
   var old: Dictionary=arena.session.roster[ids[1]]
   var spec: Dictionary=arena.session.make_spec(int(ids[1]),old.nickname,1,int(old.slot),int(old.generation)+1,int(old.variant));spec.variant=variant;spec.color=variant
   arena.session.upsert_player.rpc(int(ids[1]),spec);await pause(.3)
   var actor: Node3D=arena.session.actors[ids[1]]
   check(actor.robots.current.meshes[0].material_override.albedo_texture!=null and actor.rig_anim.get_animation_list().size()>0,'robot/texturas exportados '+str(variant))
  FileAccess.open(root_dir.path_join('native_done'),FileAccess.WRITE).store_string('go')
 else:
  while not FileAccess.file_exists(root_dir.path_join('native_done')): await pause(.1)
  check(arena.session.telemetry.snapshots>0,'recibe snapshots reales exportados')
 print('RESULTADO ',passed,'/',checks)
 FileAccess.open(root_dir.path_join(role+'.json'),FileAccess.WRITE).store_string(JSON.stringify({'passed':passed,'total':checks,'ok':passed==checks}))
 await pause(.3);finish()
func finish() -> void:
 arena.session.leave();arena.queue_free();await process_frame;await process_frame;quit(0 if passed==checks else 1)

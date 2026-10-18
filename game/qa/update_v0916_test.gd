extends SceneTree
var game: Node3D
var checks := 0
var passed := 0
func _initialize() -> void: run.call_deferred()
func frames(n: int) -> void:
 for i in range(n): await physics_frame
func check(ok: bool,title: String) -> void:
 checks += 1
 if ok: passed += 1
 print("PASS " if ok else "FAIL ",title)
func reset_target() -> Dictionary:
 game.fusion.combat.interrupted();game.fusion.combat.cooldowns=[0.0,0.0,0.0,0.0];game.fusion.combat.m1_cooldown=0
 game.stun=0;game.block=false;game.player.position=Vector3(-16,.1,0);game.player.velocity=Vector3.ZERO;game.yaw=0;game.model.rotation.y=0;game.camera_lock=true
 for e in game.enemies:
  e.physics.cancel();e.ragdoll=false;e.ragdoll_time=0;e.hp=100;e.wakeup_protection=0;e.projection_freeze=0;e.stun=0;e.body.position=Vector3(40+game.enemies.find(e)*3,.1,40)
 var e:Dictionary=game.enemies[0];e.body.position=game.player.position+Vector3(0,0,-7);return e
func run() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await frames(12)
 for e in game.enemies:game.set_dummy_mode(e,0)
 # Repeated physical recovery across all four original rigs.
 game.robots.select(1)
 for index in range(4):
  game.robots.forced=index;game.robots.spawn();game.player.position=Vector3(-16,.15,0);await frames(10)
  var sk:Skeleton3D=game.robots.current.skeleton
  for cycle in range(2):
   game.player_ragdoll=true;game.player_ragdoll_time=.35
   game.physical_ragdoll.start(Vector3(1.5,2,0),{"kind":"horizontal","direction":Vector3.RIGHT})
   await frames(65)
   check(not game.physical_ragdoll.active and game.physical_ragdoll.recovering<=0,"recuperación física completa "+str(index)+"/"+str(cycle))
   var b=sk.find_bone("Body")
   check(sk.get_bone_pose_rotation(b).angle_to(game.physical_ragdoll.rest_rotations[b])<.08,"Body recupera rotación original "+str(index)+"/"+str(cycle))
  check(game.rig_anim.has_animation("RobotGuard") and game.rig_anim.has_animation("RobotBoost"),"guardia y postura de propulsión disponibles "+str(index))
 game.charge=100;game.player.position=Vector3(-16,.1,0);await frames(8)
 check(game.fusion.request(),"G conserva fusión de cuatro chasis")
 game.fusion.sequence.advance(11.5);await frames(4)
 var rig:Node3D=game.fusion.sequence.articulation;var combat:Node3D=game.fusion.combat
 check(rig.all_parts.size()==112 and rig.cannon_transform.gun_parts.size()==31,"112 piezas Junkyard y 31 piezas Rustwing de V8")
 check(rig.cannon_transform.diagnostic.shoulder_caps==4 and rig.cannon_transform.diagnostic.shoulder_extras==2,"hombro blanco y detalles originales conservan sus bisagras")
 check(game.max_hp==300 and game.robots.naoya.collision.shape.height==4,"mega conserva tamaño 4 m y 300 HP")
 check(game.fusion.hurt_area.collision_layer==8,"hurtbox separado de huesos físicos capa 4")
 var e=reset_target();await frames(6)
 Input.action_press("ability1");check(combat.press(1),"cañón mantenido inicia despliegue")
 await frames(100)
 check(e.hp==100 and combat.current.get("id","")=="cannon" and combat.cannon_phase=="hold","mantener 1 no dispara automáticamente")
 check(combat.aim_laser.visible and rig.deployment>.99,"láser y cañón desplegado mientras se apunta")
 check(combat.movement_scale()>.5,"el cañón permite caminar durante la carga")
 var axis:Vector3=(rig.cannon_transform.mount.global_basis*rig.cannon_transform.GUN_AXIS).normalized()
 check(axis.dot((combat.cannon_aim-rig.muzzle()).normalized())>.995,"boca original alineada a trayectoria real")
 Input.action_release("ability1");combat.release_cannon();await frames(10)
 check(combat.cooldowns[0]>1.7 and combat.cooldowns[0]<=2,"soltar dispara con 2 segundos de recarga")
 check(e.hp<100 and e.ragdoll,"proyectil real hace daño y derriba")
 await frames(75)
 check(combat.current.is_empty() and rig.deployment<.01 and not combat.aim_laser.visible,"repliegue inverso devuelve forma base del brazo")
 e=reset_target();await frames(5)
 var fallen:=RigidBody3D.new();game.add_child(fallen);fallen.freeze=true;fallen.collision_layer=4;fallen.collision_mask=1
 var fallen_col:=CollisionShape3D.new();var fallen_box:=BoxShape3D.new();fallen_box.size=Vector3(4,4,1)
 fallen_col.shape=fallen_box;fallen.add_child(fallen_col);fallen.global_position=game.player.global_position+Vector3(0,2,-3.3);await frames(3)
 Input.action_press("ability1");combat.press(1);await frames(70);Input.action_release("ability1");combat.release_cannon();await frames(12)
 check(e.hp<100 and e.ragdoll,"cañón atraviesa cuerpos de ragdoll capa 4 y alcanza objetivo detrás")
 fallen.queue_free();await frames(65)
 e=reset_target();e.body.position=game.player.position+Vector3(0,0,-3);await frames(6)
 check(combat.punch(),"M1 pesado inicia preparación")
 await frames(39)
 check(e.hp<100 and e.ragdoll,"M1 golpe al suelo aplica daño real y derribo")
 print("HAND_DIAG ",rig.pivots.Mano_Der.global_position," player ",game.player.global_position)
 combat.interrupted();await frames(3)
 game.moves.freeze_player(5)
 check(game.moves.player_freeze>4.9 and not game.fusion.visual().visible,"mega cristalizable con representación 2D exclusiva")
 game.moves.break_player_frame("hit");await frames(3)
 check(game.moves.player_freeze==0 and game.fusion.visual().visible,"golpe rompe vidrio y restaura mega 3D")
 reset_target();await frames(6)
 Input.action_press("block");await frames(4)
 check(game.block and is_instance_valid(game.skill_vfx.guard_shield) and game.skill_vfx.guard_shield.visible,"F muestra escudo frontal del mega")
 Input.action_release("block");await frames(3)
 for direction in [Vector3.LEFT,Vector3.RIGHT,Vector3.BACK]:
  reset_target();await frames(5);game.dash_cd=0
  if direction.x<0:Input.action_press("left")
  elif direction.x>0:Input.action_press("right")
  else:Input.action_press("back")
  check(game.fusion.start_boost() and game.fusion.boost_direction.dot(direction)>.99,"dash direccional "+str(direction))
  Input.action_release("left");Input.action_release("right");Input.action_release("back")
  await frames(95)
  check(game.player.is_on_floor() and Vector2(game.player.velocity.x,game.player.velocity.z).length()<.1 and not game.fusion.boost_in_flight,"aterrizaje sin patinaje "+str(direction))
 check(game.skill_vfx.dust.crowns_emitted>=3,"aterrizajes generan polvo de impacto")
 # Refund when the arena surface truly does not exist.
 reset_target();await frames(5);combat.punch();game.player.position=Vector3(300,20,300)
 combat.ground_attack();check(combat.m1_cooldown==0,"suelo inexistente devuelve recarga")
 game.fusion.break_apart();var count=0
 for child in game.get_parent().get_children():
  if child.get_script()==load("res://scripts/mecha_wreck.gd"):count+=child.bodies.size()
 check(count>2 and count<=18 and not game.fusion.visual().visible,"muerte desarma en grupos físicos acotados")
 game.queue_free();await frames(5)
 print("RESULTADO ",passed,"/",checks);quit.call_deferred(0 if passed==checks else 1)

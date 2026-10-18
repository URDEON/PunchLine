extends SceneTree
var checks:=0
var passed:=0
var game:Node3D
var contact_error:=0.0
var length_error:=0.0
var observed:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,title:String)->void:
 checks+=1
 if ok:passed+=1
 print("PASS " if ok else "FAIL ",title)
func frames(n:int)->void:
 for i in range(n):await physics_frame
func release()->void:
 for key in ["forward","back","left","right","walk","block","ability1"]:Input.action_release(key)
func module_center(index:int)->Vector3:
 var result:=Vector3.ZERO;var count:=0
 for mesh in game.fusion.damage.sources[index]:
  if is_instance_valid(mesh) and mesh.is_visible_in_tree():result+=mesh.global_transform*mesh.get_aabb().get_center();count+=1
 return result/float(maxi(1,count))
func hurt_module(index:int,amount:float)->void:
 var point:=module_center(index);game.hp-=amount;game.fusion.damage.record(amount,point)
func inspect_human()->void:
 var modifier:SkeletonModifier3D=game.human_motion;var skeleton:Skeleton3D=game.visual_motion.skeleton
 if modifier.influence_weight<.99:return
 for f in modifier.feet.values():
  if not f.valid:continue
  var a:Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(f.bones[0]).origin
  var b:Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(f.bones[1]).origin
  var c:Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(f.bones[2]).origin
  var ra:Vector3=skeleton.global_transform*skeleton.get_bone_global_rest(f.bones[0]).origin
  var rb:Vector3=skeleton.global_transform*skeleton.get_bone_global_rest(f.bones[1]).origin
  length_error=maxf(length_error,absf(a.distance_to(b)-ra.distance_to(rb)))
  if f.stance and float(f.get("weight",0))>.9:contact_error=maxf(contact_error,absf(c.y-f.ground.y));observed+=1
func run()->void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await frames(12)
 for e in game.enemies:game.set_dummy_mode(e,0)
 var floor_body:=StaticBody3D.new();floor_body.collision_layer=1;game.add_child(floor_body);floor_body.position=Vector3(200,-.1,0)
 var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(80,.2,80);col.shape=shape;floor_body.add_child(col)
 game.player.position=Vector3(200,.03,5);game.player.velocity=Vector3.ZERO;await frames(25)
 check(game.interface.phase_text.text.begins_with("THE PROYECTED"),"nombre visible The Proyected")
 check(game.preferences.bindings.has("lock") and InputMap.has_action("lock"),"lock tiene acción configurable")
 var event:=InputEventKey.new();event.keycode=KEY_C;event.pressed=true;var before:bool=game.camera_lock;game._unhandled_input(event)
 check(game.camera_lock!=before,"tecla C alterna lock")
 game.preferences.install_key("lock",KEY_L);event.keycode=KEY_L;before=game.camera_lock;game._unhandled_input(event)
 check(game.camera_lock!=before,"reasignación de lock se utiliza en partida");game.preferences.install_key("lock",KEY_C)
 game.human_motion.modification_processed.connect(inspect_human)
 Input.action_press("walk");Input.action_press("forward");var position:Vector3=game.player.position;var max_rays:=0
 for i in range(300):await frames(1);max_rays=maxi(max_rays,game.human_motion.queries_frame)
 release()
 check(game.player.position.distance_to(position)>2 and game.human_motion.contacts>4,"locomoción de The Proyected conserva control y establece apoyos")
 check(observed>5 and contact_error<.08,"altura de apoyo humana sin sustituir el ciclo original (%.4f m)"%contact_error)
 check(length_error<.006,"corrección humana no alarga las piernas (%.4f m)"%length_error)
 check(max_rays<=2 and not game.human_motion.pose_cache.is_empty(),"dos rayos como máximo y pose final disponible para red")
 game.attack_anim=.5;await frames(2);check(not game.human_motion.active,"IK humana cede ante ataques");game.attack_anim=0
 game.robots.select(1);game.player.position=Vector3(200,.03,0);game.player.velocity=Vector3.ZERO;await frames(20)
 check(not game.human_motion.active,"modificador humano no toca los robots")
 game.charge=100;check(game.fusion.request(),"fusión preparada")
 game.fusion.sequence.advance(11.5);await frames(45);var rig:Node3D=game.fusion.sequence.articulation
 game.zoom=5.5;game.camera_lock=false;game.yaw=.5;game.pitch=.2;await frames(35)
 check(not rig.tracking_view and absf(rig.pivots.Cabeza.rotation.y)<.03,"sin lock la cabeza no sigue el ratón")
 game.camera_lock=true;await frames(45)
 var desired:=Vector3.FORWARD.rotated(Vector3.RIGHT,.2).rotated(Vector3.UP,.5)
 check(rig.tracking_view and rig.pivots.Cabeza.global_basis.z.normalized().dot(desired)>.96,"lock reactiva mirada independiente")
 check(rig.find_children("NeckClosure","MeshInstance3D",true,false).size()==2,"dos cierres del cuello conservan superficie interior")
 game.zoom=0;game.update_camera(.016)
 check(is_instance_valid(game.camera_view.lens) and game.camera_view.lens.visible,"primera persona activa lente corporal")
 check(game.camera_view.lens.layer>0 and game.camera_view.lens.layer<game.camera_view.cockpit.layer and game.camera_view.cockpit.layer<game.interface.layer,"lente se dibuja sobre 3D y antes de cabina y HUD")
 game.preferences.values.body_lens=0;game.update_camera(.016);check(not game.camera_view.lens.visible,"lente puede desactivarse sin afectar HUD")
 game.preferences.values.body_lens=.14;game.zoom=5.5;game.update_camera(.016);check(not game.camera_view.lens.visible,"tercera persona no aplica ojo de pez")
 game.camera_lock=false;game.yaw=0;game.model.rotation.y=0;await frames(8)
 hurt_module(0,70);await frames(2)
 check(game.fusion.damage.missing(0) and not rig.pivots.BrazoSuperior_Der.is_visible_in_tree(),"impactos destruyen el brazo del cañón")
 check(not game.fusion.combat.press(1) and game.fusion.combat.cooldowns[0]==0,"brazo perdido bloquea habilidad 1 sin gastar recarga")
 if not game.fusion.damage.bodies.has(0):quit(1);return
 var debris:RigidBody3D=game.fusion.damage.bodies[0];var origin:Vector3=debris.global_position
 check(debris.collision_layer==4 and debris.collision_mask==1 and debris.scale.is_equal_approx(Vector3.ONE),"brazo físico colisiona solo con mundo y tiene escala estable")
 Input.action_press("right");await frames(240);release()
 check(is_instance_valid(debris) and game.fusion.damage.bodies.has(0),"brazo permanece más de 3,6 s mientras el robot vive")
 check(debris.global_position.distance_to(game.player.global_position)>1.5,"restos permanecen en el mundo en lugar de seguir al cuerpo")
 var sparks:CPUParticles3D=game.fusion.damage.sockets[0].get_node_or_null("LiveSparks")
 check(sparks!=null and sparks.emitting and sparks.amount<=20,"muñón contiene cables y emisor activo compatible con OpenGL")
 hurt_module(2,90);hurt_module(1,80);await frames(4)
 check(game.fusion.damage.missing(2) and game.fusion.damage.missing(1),"pierna y brazo de apoyo tienen integridad independiente")
 check(game.fusion.damage.speed_scale()==.45 and not game.fusion.start_boost(),"pérdida de tren reduce movimiento y bloquea propulsión")
 check(not game.fusion.combat.press(2) and not game.fusion.damage.guard_available(),"falta de brazos inhabilita martillo y escudo")
 check(game.fusion.combat.punch() and game.fusion.combat.current.id=="m1_stomp" and game.fusion.combat.current.limb=="Izq","M1 utiliza solo la pierna intacta")
 game.fusion.combat.interrupted();await frames(4)
 game.interface.tick(.016);check(is_equal_approx(game.interface.stability.value,20) and not game.interface.stability.alert.visible,"20% coincide exactamente con 60 de 300 HP")
 game.hp=54;game.interface.tick(.016);check(is_equal_approx(game.interface.stability.value,18) and game.interface.stability.alert.visible,"18% activa alertas críticas reales")
 game.hp=0;game.on_player_death();await frames(2)
 check(game.fusion.death_broken and game.hp==0,"muerte de Sentinel inicia espera")
 await frames(175);check(game.hp==0 and game.fusion.fused,"no reaparece antes de desaparecer los restos")
 await frames(85);check(game.hp==100 and not game.fusion.busy() and game.fusion.damage.remnants_gone(),"reaparición posterior a retirada de restos y módulos")
 release();game.queue_free();await frames(8)
 print("HUMAN_METRICS ",{"stance_error":contact_error,"segment_error":length_error,"samples":observed})
 print("RESULTADO ",passed,"/",checks);quit(0 if passed==checks else 1)

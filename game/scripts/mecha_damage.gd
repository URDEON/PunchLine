extends Node3D
## Integridad por extremidad: autoridad decide; los clientes reproducen restos.
const ORDER:=["cannon","support","right_drive","left_drive"]
const ROOTS:=["BrazoSuperior_Der","BrazoSuperior_Izq","Pantorrilla_Der","Pantorrilla_Izq"]
const CAPACITIES:=[65.0,75.0,85.0,85.0]
var controller:Node3D
var rig:Node3D
var integrity:Array[float]=[65.0,75.0,85.0,85.0]
var lost:=0
var sources:Array=[]
var records:Dictionary={}
var bodies:Dictionary={}
var forearms:Dictionary={}
var hinges:Dictionary={}
var forearm_targets:Dictionary={}
var sockets:Dictionary={}
var targets:Dictionary={}
var cleanup:=-1.0
var fade_materials:Array=[]
var pause_velocities: Dictionary = {}
func _ready()->void:
 get_tree().node_added.connect(actor_added)
func actor_added(node:Node)->void:
 if node is CharacterBody3D:exclude_actor.call_deferred(node)
func exclude_actor(node:Variant)->void:
 if not is_instance_valid(node) or not node is CharacterBody3D:return
 for body in bodies.values()+forearms.values():
  if is_instance_valid(body):body.add_collision_exception_with(node)
func set_paused(value:bool)->void:
 if controller.replica:return
 for body in bodies.values()+forearms.values():
  if not is_instance_valid(body):continue
  var id:int=body.get_instance_id()
  if value and not body.freeze:
   pause_velocities[id]=[body.linear_velocity,body.angular_velocity];body.freeze=true
  elif not value and pause_velocities.has(id):
   body.freeze=false;body.linear_velocity=pause_velocities[id][0];body.angular_velocity=pause_velocities[id][1]
 if not value:pause_velocities.clear()
 for socket in sockets.values():
  if is_instance_valid(socket):socket.set_paused(value)
func setup(owner_controller:Node3D)->void:controller=owner_controller
func configure(source:Node3D)->void:
 rig=source;sources.clear()
 for key in ROOTS:
  var meshes:Array=[]
  for mesh in rig.pivots[key].find_children("*","MeshInstance3D",true,false):
   if surviving(mesh):meshes.append(mesh)
  sources.append(meshes)
func surviving(mesh:Node)->bool:
 if not is_instance_valid(mesh):return false
 var current:Node=mesh
 while current!=rig and current!=null:
  if current.is_queued_for_deletion():return false
  current=current.get_parent()
 return true
func missing(index:int)->bool:return lost & (1<<index)!=0
func allowed(slot:int)->bool:
 match slot:
  1:return not missing(0)
  2:return not missing(0) and not missing(1)
  3:return not missing(2) or not missing(3)
  4:return not missing(2) and not missing(3)
 return true
func guard_available()->bool:return not missing(1)
func speed_scale()->float:return 0.0 if missing(2) and missing(3) else (.45 if missing(2) or missing(3) else 1.0)
func reason(slot:int)->String:return ["BRAZO DEL CAÑÓN DESTRUIDO","MARTILLO / FALTA UN BRAZO","PISOTÓN / SIN APOYO","PROPULSIÓN / TREN DAÑADO"][clampi(slot-1,0,3)]
func record(amount:float,point:Vector3)->void:
 if controller.replica or not controller.fused or controller.game.hp<=0 or amount<=0 or not is_instance_valid(rig):return
 var chosen:=-1;var distance:=INF
 for index in range(4):
  if missing(index):continue
  var center:=Vector3.ZERO;var count:=0
  for mesh in sources[index]:
   if is_instance_valid(mesh) and mesh.is_visible_in_tree():center+=mesh.global_transform*mesh.get_aabb().get_center();count+=1
  if count==0:continue
  center/=float(count);var score:=center.distance_squared_to(point)
  if score<distance:distance=score;chosen=index
 if chosen<0:return
 integrity[chosen]=maxf(0,integrity[chosen]-amount)
 if integrity[chosen]<=0:detach(chosen)
func detach(index:int)->void:
 if missing(index):return
 var joint:Node3D=rig.pivots[ROOTS[index]];var frame:=Transform3D(joint.global_basis.orthonormalized(),joint.global_position);var parts:Array=[]
 for part in range(sources[index].size()):
  var mesh=sources[index][part]
  if is_instance_valid(mesh) and mesh.is_visible_in_tree():
   var distal:bool=false
   if index<2:
    var side:String="Der" if index==0 else "Izq"
    distal=rig.pivots["Antebrazo_"+side].is_ancestor_of(mesh)
   parts.append({"index":part,"transform":frame.affine_inverse()*mesh.global_transform,"distal":distal})
 var info:Dictionary={"frame":frame,"parts":parts}
 if index<2:
  var side: String="Der" if index==0 else "Izq"
  var elbow:Node3D=rig.pivots["Antebrazo_"+side]
  info["elbow_frame"]=Transform3D(elbow.global_basis.orthonormalized(),elbow.global_position)
 install(index,info,false)
 controller.game.ult_msg=reason(1 if index==0 else (2 if index==1 else 4));controller.game.ult_msg_time=4
 controller.game.feedback.sound("mecha_armor",joint.global_position,-2)
 if not controller.combat.members_available():controller.combat.interrupted()
 if index>=2:controller.boost_time=0
func install(index:int,info:Dictionary,replica:bool)->void:
 if missing(index) or not is_instance_valid(rig):return
 lost|=1<<index;records[index]=info.duplicate(true)
 # Segmenta únicamente los brazos: hombro y antebrazo mantienen sus mallas.
 # Para snapshots antiguos que no tengan marca distal se conserva un cuerpo.
 var upper:Array=[];var lower:Array=[]
 for part in info.parts:
  if index<2 and bool(part.get("distal",false)):lower.append(part)
  else:upper.append(part)
 var upper_frame:Transform3D=info.get("body",info.frame) if replica else info.frame
 var body:=create_piece_body(index,upper,info,upper_frame,replica,8.0 if not lower.is_empty() else 12.0)
 if not replica:body.linear_velocity=controller.game.player.velocity*.4+Vector3(0,.7,0);body.angular_velocity=Vector3(.4,.3,-.4)
 if index<2 and not lower.is_empty() and info.has("elbow_frame"):
  var lower_frame:Transform3D=info.get("forearm_body",info.elbow_frame) if replica else info.elbow_frame
  var distal_body:=create_piece_body(index,lower,info,lower_frame,replica,4.0)
  if not replica:
   distal_body.linear_velocity=body.linear_velocity
   distal_body.angular_velocity=body.angular_velocity
   body.add_collision_exception_with(distal_body)
   distal_body.add_collision_exception_with(body)
   var hinge:=HingeJoint3D.new();hinge.name="ElbowJoint_"+ORDER[index]
   controller.game.get_parent().add_child(hinge)
   var hinge_axis:Vector3=info.elbow_frame.basis.x.normalized()
   hinge.global_transform=Transform3D(Basis(Quaternion(Vector3.BACK,hinge_axis)),info.elbow_frame.origin)
   body.force_update_transform();distal_body.force_update_transform();hinge.force_update_transform()
   hinge.node_a=hinge.get_path_to(body);hinge.node_b=hinge.get_path_to(distal_body)
   hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT,true)
   hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER,-.25)
   hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER,1.65)
   hinges[index]=hinge
  forearms[index]=distal_body
 bodies[index]=body
 for actor in get_tree().root.find_children("*","CharacterBody3D",true,false):exclude_actor(actor)
 var joint:Node3D=rig.pivots[ROOTS[index]];joint.hide()
 var socket:=preload("res://scripts/damaged_socket.gd").new();joint.get_parent().add_child(socket)
 socket.global_transform=Transform3D(Basis.IDENTITY,joint.global_position)
 socket.position+=Vector3(.05 if index==0 else -.05,-.03,0)
 sockets[index]=socket
 rig.disabled_modules[ROOTS[index]]=true
func create_piece_body(index:int,parts:Array,info:Dictionary,frame:Transform3D,replica:bool,mass_value:float)->RigidBody3D:
 var body:=RigidBody3D.new();body.name="Detached_"+ORDER[index]
 controller.game.get_parent().add_child(body)
 body.global_transform=frame
 if replica:body.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
 body.freeze=replica;body.collision_layer=0 if replica else 4;body.collision_mask=1
 body.mass=mass_value;body.linear_damp=.9;body.angular_damp=1.8;body.continuous_cd=true
 if not replica:body.add_collision_exception_with(controller.game.player)
 var bounds:=AABB();var first:=true
 for part in parts:
  if int(part.index)<0 or int(part.index)>=sources[index].size():continue
  var source=sources[index][int(part.index)]
  if not is_instance_valid(source):continue
  var copy:=MeshInstance3D.new();copy.mesh=source.mesh;copy.material_override=source.material_override
  body.add_child(copy)
  copy.transform=frame.affine_inverse()*info.frame*part.transform
  var box:AABB=copy.transform*copy.get_aabb()
  bounds=box if first else bounds.merge(box);first=false
 if not first:
  var shape:=CollisionShape3D.new();var box:=BoxShape3D.new()
  box.size=(bounds.size*.92).max(Vector3(.12,.12,.12));shape.shape=box;shape.position=bounds.get_center();body.add_child(shape)
 return body
func state()->Dictionary:
 var result:Array=[]
 for index in records:
  var record:Dictionary=records[index].duplicate(true)
  record["module"]=index;record["body"]=bodies[index].global_transform if is_instance_valid(bodies.get(index)) else record.frame
  if is_instance_valid(forearms.get(index)):record["forearm_body"]=forearms[index].global_transform
  result.append(record)
 return {"lost":lost,"integrity":integrity.duplicate(),"parts":result,"cleanup":cleanup}
func apply_state(data:Dictionary)->void:
 if not is_instance_valid(rig):return
 for record in data.get("parts",[]):
  var index:int=record.module
  if index<0 or index>3:continue
  if not missing(index):install(index,record,true)
  targets[index]=record.body
  if record.has("forearm_body"):forearm_targets[index]=record.forearm_body
 integrity.assign(data.get("integrity",CAPACITIES));cleanup=float(data.get("cleanup",-1))
func begin_cleanup(seconds:float)->void:cleanup=maxf(seconds,0)
func remnants_gone()->bool:return bodies.is_empty() and forearms.is_empty()
func _process(delta:float)->void:
 if controller==null or controller.game.paused:return
 for index in targets:
  if is_instance_valid(bodies.get(index)):bodies[index].global_transform=bodies[index].global_transform.interpolate_with(targets[index],1-exp(-delta*18))
 for index in forearm_targets:
  if is_instance_valid(forearms.get(index)):forearms[index].global_transform=forearms[index].global_transform.interpolate_with(forearm_targets[index],1-exp(-delta*18))
 if cleanup<0:return
 cleanup=maxf(0,cleanup-delta)
 if cleanup<.6:
  for body in bodies.values()+forearms.values():
   if is_instance_valid(body):
    for mesh in body.get_children():
     if mesh is MeshInstance3D:mesh.transparency=1-cleanup/.6
 if cleanup<=0:
  for hinge in hinges.values():
   if is_instance_valid(hinge):hinge.queue_free()
  for body in bodies.values()+forearms.values():
   if is_instance_valid(body):body.queue_free()
  bodies.clear();forearms.clear();hinges.clear();targets.clear();forearm_targets.clear()
func clear()->void:
 for hinge in hinges.values():
  if is_instance_valid(hinge):hinge.queue_free()
 for body in bodies.values()+forearms.values():
  if is_instance_valid(body):body.queue_free()
 for socket in sockets.values():
  if is_instance_valid(socket):socket.queue_free()
 bodies.clear();forearms.clear();hinges.clear();forearm_targets.clear();sockets.clear();records.clear();targets.clear();lost=0;integrity.assign(CAPACITIES);cleanup=-1;rig=null;sources.clear()
func _exit_tree()->void:clear()

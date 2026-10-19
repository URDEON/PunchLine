extends Node3D
## Gameplay damage is authoritative; debris is bounded local presentation with no player collision.
var map:Node3D
var enabled:=true
var parts:Dictionary={}
var buildings:Dictionary={}
var damaged:Dictionary={}
var collapsed:Dictionary={}
var revision:=0
var debris:Array[RigidBody3D]=[]
var removed_details:Array=[]
func setup(owner_map:Node3D,destructible:=true)->void:
 map=owner_map;name="DistrictDestruction";enabled=destructible
 if map.housing==null:return
 for lot in map.housing.get_node("GeneratedBuildings").get_children():
  for house in lot.get_children():register_building(lot.name+"/"+house.name,house)
func register_building(id:String,house:Node3D)->void:
 var batches:Dictionary={}
 for batch in house.find_children("*","MultiMeshInstance3D",true,false):
  if batch.has_meta("destruction_batch"):batches[int(batch.get_meta("destruction_batch"))]=batch
 var list:Array=[];var serial:=0
 for body in house.find_children("*","StaticBody3D",true,false):
  var col:CollisionShape3D=body.get_child(0) if body.get_child_count()>0 and body.get_child(0) is CollisionShape3D else null
  if col==null:
   for child in body.get_children():
    if child is CollisionShape3D:col=child;break
  if col==null or col.shape==null:continue
  var key:String=id+":"+str(serial);serial+=1
  var batch:MultiMeshInstance3D=batches.get(int(body.get_meta("destruction_batch",-1)))
  var index:int=int(body.get_meta("destruction_index",-1))
  var category:Node=body
  while category.get_parent()!=house and category.get_parent()!=null:category=category.get_parent()
  var structural:bool=String(category.name) in ["Walls","Floors","Roof","Stairs","Doors"]
  var hp:float=36.0 if structural else 12.0
  if String(category.name)=="Windows":hp=8
  var box:=AABB()
  if col.shape is BoxShape3D:box=AABB(-col.shape.size/2,col.shape.size)
  else:box=col.shape.get_debug_mesh().get_aabb()
  var saved:Transform3D=batch.multimesh.source_transform(index) if is_instance_valid(batch) and index>=0 else Transform3D.IDENTITY
  parts[key]={"body":body,"collision":col,"building":id,"batch":batch,"index":index,"transform":saved,"hp":hp,"max_hp":hp,"box":col.global_transform*box,"structural":structural,"broken":false,"layer":body.collision_layer,"mask":body.collision_mask}
  body.set_meta("destructible_id",key);list.append(key)
 var reserved:Dictionary={}
 for key in list:
  var p:Dictionary=parts[key]
  if is_instance_valid(p.batch):reserved[str(p.batch.get_instance_id())+":"+str(p.index)]=true
 var decor:Array=[]
 for batch in house.find_children("*","MultiMeshInstance3D",true,false):
  if not "source_transforms" in batch.multimesh:continue
  for i in range(batch.multimesh.instance_count):
   if reserved.has(str(batch.get_instance_id())+":"+str(i)):continue
   var transform:Transform3D=batch.multimesh.source_transform(i)
   decor.append({"batch":batch,"index":i,"transform":transform,"point":batch.global_transform*transform.origin,"hidden":false})
 buildings[id]={"node":house,"parts":list,"decor":decor,"hp":240.0*sqrt(float(house.get_meta("storeys",1))),"max_hp":240.0*sqrt(float(house.get_meta("storeys",1)))}
func authoritative()->bool:
 return not ("session" in map.game) or map.game.session.is_host()
func nearest(box:AABB,point:Vector3)->Vector3:return point.clamp(box.position,box.end)
func damage_area(point:Vector3,radius:float,amount:float,direction:Vector3)->Dictionary:
 if not enabled or not authoritative() or amount<=0:return {}
 var changed:Dictionary={};var affected:Dictionary={}
 for id in parts:
  var p:Dictionary=parts[id]
  if p.broken or collapsed.has(p.building) or nearest(p.box,point).distance_to(point)>radius:continue
  p.hp=maxf(0,p.hp-amount);damaged[id]=p.hp;changed[id]=p.hp
  if p.structural:affected[p.building]=true
 var fallen:Array=[]
 for id in affected:
  buildings[id].hp=maxf(0,buildings[id].hp-amount*.65)
  if buildings[id].hp<=0:fallen.append(id)
 if changed.is_empty():return {}
 var packet:Dictionary={"revision":revision+1,"damaged":changed,"collapsed":fallen,"point":point,"direction":direction}
 apply_packet(packet,true)
 if "session" in map.game:
  for peer in map.game.session.ready_peers:map.game.session.district_damage.rpc_id(peer,packet)
 return packet
func remove_part(id:String,animate:bool,point:Vector3,direction:Vector3)->void:
 if not parts.has(id) or parts[id].broken:return
 var p:Dictionary=parts[id];p.broken=true;p.body.visible=false
 p.body.set_deferred("collision_layer",0);p.body.set_deferred("collision_mask",0)
 p.collision.set_deferred("disabled",true)
 if is_instance_valid(p.batch) and p.index>=0:
  var hidden:Transform3D=p.transform;hidden.basis=Basis().scaled(Vector3.ZERO)
  p.batch.multimesh.source_transforms[p.index]=hidden
  p.batch.multimesh.set_instance_transform(p.index,hidden)
 # Remove non-colliding trim in the opening; unbroken physical parts remain intact.
 for entry in buildings[p.building].decor:
  if entry.hidden or not p.box.grow(.30).has_point(entry.point):continue
  entry.hidden=true;removed_details.append(entry)
  var hidden:Transform3D=entry.transform;hidden.basis=Basis().scaled(Vector3.ZERO)
  entry.batch.multimesh.source_transforms[entry.index]=hidden;entry.batch.multimesh.set_instance_transform(entry.index,hidden)
 if animate:spawn_debris(p,point,direction)
func apply_packet(packet:Dictionary,animate:=false)->void:
 var incoming:int=int(packet.get("revision",0))
 if incoming<=revision:return
 revision=incoming
 for id in packet.get("damaged",{}):
  if not parts.has(id):continue
  var hp:float=float(packet.damaged[id]);parts[id].hp=hp;damaged[id]=hp
  if hp<=0:remove_part(id,animate,packet.get("point",Vector3.ZERO),packet.get("direction",Vector3.UP))
 for id in packet.get("collapsed",[]):
  if not buildings.has(id) or collapsed.has(id):continue
  collapsed[id]=true;buildings[id].node.visible=false
  for key in buildings[id].parts:remove_part(key,animate and debris.size()<28,packet.get("point",Vector3.ZERO),packet.get("direction",Vector3.UP))
func state()->Dictionary:
 return {"revision":revision,"damaged":damaged.duplicate(),"collapsed":collapsed.keys()}
func accept_state(data:Dictionary)->void:
 if int(data.get("revision",0))==0:return
 revision=-1;apply_packet(data,false)
func spawn_debris(part:Dictionary,_point:Vector3,direction:Vector3)->void:
 if not bool(map.game.preferences.values.get("debris_enabled",true)):return
 if debris.size()>=32:
  var oldest:RigidBody3D=debris.pop_front()
  if is_instance_valid(oldest):oldest.queue_free()
 var body:=RigidBody3D.new();body.name="LocalRubble";body.collision_layer=0;body.collision_mask=1
 var size:Vector3=part.box.size.min(Vector3(.65,.65,.65)).max(Vector3(.10,.10,.10))
 var geometry:=MeshInstance3D.new();var shape:=BoxMesh.new();shape.size=size;geometry.mesh=shape
 var mat:=StandardMaterial3D.new();mat.albedo_color=Color("9b9180");mat.roughness=.95;geometry.material_override=mat;body.add_child(geometry)
 var col:=CollisionShape3D.new();var physics:=BoxShape3D.new();physics.size=size;col.shape=physics;body.add_child(col)
 add_child(body);body.global_position=part.box.get_center();body.mass=8
 body.linear_velocity=direction.normalized()*2+Vector3.UP*2;body.angular_velocity=Vector3(1.2,2,.8)
 debris.append(body)
 body.set_meta("expires",Time.get_ticks_msec()+7000)
func _process(_delta:float)->void:
 for i in range(debris.size()-1,-1,-1):
  var body:RigidBody3D=debris[i]
  if not is_instance_valid(body):debris.remove_at(i)
  elif Time.get_ticks_msec()>int(body.get_meta("expires",0)):body.queue_free();debris.remove_at(i)
func reset_world()->void:
 for body in debris:
  if is_instance_valid(body):body.queue_free()
 debris.clear();damaged.clear();collapsed.clear();revision=0
 for entry in removed_details:
  entry.batch.multimesh.source_transforms[entry.index]=entry.transform;entry.batch.multimesh.set_instance_transform(entry.index,entry.transform);entry.hidden=false
 removed_details.clear()
 for b in buildings.values():b.node.show();b.hp=b.max_hp
 for p in parts.values():
  p.hp=p.max_hp;p.broken=false;p.body.visible=true
  p.body.set_deferred("collision_layer",p.layer);p.body.set_deferred("collision_mask",p.mask);p.collision.set_deferred("disabled",false)
  if is_instance_valid(p.batch) and p.index>=0:
   p.batch.multimesh.source_transforms[p.index]=p.transform;p.batch.multimesh.set_instance_transform(p.index,p.transform)

extends Node3D
## Lazy fracture + a support graph: only the host decides holes and unsupported pieces.
## Rigid debris uses local Jolt physics; permanent holes/support loss replicate reliably.
var map:Node3D
var enabled:=true
var parts:Dictionary={}
var buildings:Dictionary={}
var damaged:Dictionary={}
var collapsed:Dictionary={}
var revision:=0
var debris:Array[RigidBody3D]=[]
var removed_details:Array=[]
var fractures:Dictionary={}
var fracture_nodes:Array[Node3D]=[]
var cracks:Dictionary={}
var rubble:Array[Node3D]=[]
var event_fragments:=0
var event_falling:=0
var support_checks:=0
var fall_hazards:Array[Dictionary]=[]
var fall_hits:Dictionary={}
var physical_rubble:Dictionary={}
const FRACTURE_SIZE:=.85
const MAX_DYNAMIC:=64
const MAX_RESTING:=192
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
  var local_box:AABB=house.global_transform.affine_inverse()*col.global_transform*box
  var mat:Material=batch.material_override if is_instance_valid(batch) else null
  if mat==null:
   var meshes:Array=body.find_children("*","MeshInstance3D",true,false)
   if not meshes.is_empty():mat=meshes[0].get_active_material(0)
  var kind:=material_kind(mat,String(category.name))
  hp*=float({"glass":.8,"timber":.8,"steel":1.8,"concrete":1.25}.get(kind,1.0))
  parts[key]={"local_bounds":box,"kind":kind,"category":String(category.name),"local_box":local_box,"material":mat,"pose":col.global_transform,"size":box.size,"fractured":false,"parent":"","body":body,"collision":col,"building":id,"batch":batch,"index":index,"transform":saved,"hp":hp,"max_hp":hp,"box":col.global_transform*box,"structural":structural,"broken":false,"layer":body.collision_layer,"mask":body.collision_mask}
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
 buildings[id]={"support_reference":{},"node":house,"parts":list,"decor":decor,"hp":240.0*sqrt(float(house.get_meta("storeys",1))),"max_hp":240.0*sqrt(float(house.get_meta("storeys",1)))}
 # Load capacity at each storey's bearing band is measured before damage.
 for key in list:
  var p:Dictionary=parts[key]
  if p.category!="Walls":continue
  var level:int=maxi(0,floori((p.local_box.get_center().y)/3.6))
  var band:float=level*3.6+.45
  if p.local_box.position.y<=band and p.local_box.end.y>=band:
   p["bearing_level"]=level;p["bearing_area"]=p.local_box.size.x*p.local_box.size.z
   buildings[id].support_reference[level]=float(buildings[id].support_reference.get(level,0))+p.bearing_area
func material_kind(mat:Material,category:String)->String:
 if category=="Windows":return "glass"
 if mat is StandardMaterial3D:
  if mat.metallic>.5:return "steel"
  if mat.albedo_texture!=null:
   var texture:String=mat.albedo_texture.resource_path
   if "wood" in texture:return "timber"
   if "concrete" in texture:return "concrete"
 return "masonry"
func authoritative()->bool:
 return not ("session" in map.game) or map.game.session.is_host()
func nearest(box:AABB,point:Vector3)->Vector3:return point.clamp(box.position,box.end)
func can_fracture(p:Dictionary)->bool:
 return not p.fractured and p.parent.is_empty() and p.collision.shape is BoxShape3D and p.category in ["Walls","Floors"] and p.size.max_axis_index()!=p.size.min_axis_index() and p.size[p.size.max_axis_index()]>1.15

func hide_geometry(p:Dictionary)->void:
 p.broken=true;p.body.visible=false;p.body.set_deferred("collision_layer",0);p.body.set_deferred("collision_mask",0);p.collision.set_deferred("disabled",true)
 if is_instance_valid(p.batch) and p.index>=0:
  var hidden:Transform3D=p.transform;hidden.basis=Basis().scaled(Vector3.ZERO)
  p.batch.multimesh.source_transforms[p.index]=hidden;p.batch.multimesh.set_instance_transform(p.index,hidden)

func fracture(id:String)->Array:
 var source:Dictionary=parts[id]
 if source.fractured:return fractures.get(id,[])
 source.fractured=true;hide_geometry(source)
 var root:=Node3D.new();root.name="Fracture_"+str(fracture_nodes.size());buildings[source.building].node.add_child(root);root.global_transform=source.pose;fracture_nodes.append(root)
 var size:Vector3=source.size
 var thin:int=size.min_axis_index();var step:float=FRACTURE_SIZE if source.category=="Walls" else 1.65
 var counts:=Vector3i.ONE
 for axis in range(3):
  if axis!=thin:counts[axis]=clampi(ceili(size[axis]/step),1,18)
 var cell:Vector3=size/Vector3(counts)
 var batch:=MultiMeshInstance3D.new();batch.name="FracturedMaterial";batch.multimesh=preload("res://housing/scripts/BakedMultiMesh.gd").new();batch.multimesh.transform_format=MultiMesh.TRANSFORM_3D;batch.multimesh.use_colors=true
 var mesh:=BoxMesh.new();mesh.size=Vector3.ONE;batch.multimesh.mesh=mesh;batch.multimesh.instance_count=counts.x*counts.y*counts.z
 var mat:Material=source.material.duplicate() if source.material!=null else StandardMaterial3D.new()
 if mat is StandardMaterial3D:mat.vertex_color_use_as_albedo=true
 batch.material_override=mat;batch.visibility_range_end=320;root.add_child(batch)
 var keys:Array=[];var i:=0
 for x in range(counts.x):
  for y in range(counts.y):
   for z in range(counts.z):
    var at:Vector3=-size/2+cell*(Vector3(x,y,z)+Vector3.ONE*.5)
    var body:=StaticBody3D.new();body.name="MasonryCell"+str(i);root.add_child(body);body.position=at
    var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=cell;collision.shape=shape;body.add_child(collision)
    var transform:=Transform3D(Basis.IDENTITY.scaled(cell),at);batch.multimesh.source_transforms.append(transform);batch.multimesh.set_instance_color(i,Color.WHITE)
    var box:AABB=collision.global_transform*AABB(-cell/2,cell);var local_box:AABB=buildings[source.building].node.global_transform.affine_inverse()*collision.global_transform*AABB(-cell/2,cell)
    var key:String=id+"/"+str(i)
    var hp:float=source.max_hp*(.70 if source.category=="Floors" else 1.0)
    parts[key]={"local_bounds":AABB(-cell/2,cell),"kind":source.kind,"category":source.category,"local_box":local_box,"material":source.material,"pose":collision.global_transform,"size":cell,"fractured":false,"parent":id,"body":body,"collision":collision,"building":source.building,"batch":batch,"index":i,"transform":transform,"hp":hp,"max_hp":hp,"box":box,"structural":source.structural,"broken":false,"layer":1,"mask":1}
    body.set_meta("destructible_id",key);buildings[source.building].parts.append(key);keys.append(key)
    if source.has("bearing_level"):
     var band:float=int(source.bearing_level)*3.6+.45
     if local_box.position.y<=band and local_box.end.y>=band:parts[key]["bearing_level"]=source.bearing_level;parts[key]["bearing_area"]=local_box.size.x*local_box.size.z
    i+=1
 batch.multimesh.upload()
 fractures[id]=keys
 return keys

func unsupported(id:String)->Array:
 support_checks+=1
 var structure:Array=[];var anchored:Array=[];var live_capacity:Dictionary={}
 var b:Dictionary=buildings[id]
 for key in b.parts:
  var p:Dictionary=parts[key]
  if p.broken or (not p.structural and p.category not in ["Windows","Interiors"]):continue
  structure.append(key)
  if p.local_box.position.y<.16:anchored.append(key)
  if p.has("bearing_level"):live_capacity[p.bearing_level]=float(live_capacity.get(p.bearing_level,0))+float(p.bearing_area)*clampf(p.hp/p.max_hp,0,1)
 # Connectivity removes hanging lintels/wall islands. Capacity stops a roof being
 # held up by a surviving sliver after most of a storey's bearing wall is gone.
 var failed_level:=999
 for level in b.support_reference:
  var capacity:float=float(live_capacity.get(level,0))/maxf(.001,float(b.support_reference[level]))
  if capacity<.30:failed_level=mini(failed_level,int(level))
 var grid:Dictionary={};var cell_size:=2.0
 for key in structure:
  var box:AABB=parts[key].local_box.grow(.14)
  for x in range(floori(box.position.x/cell_size),floori(box.end.x/cell_size)+1):
   for y in range(floori(box.position.y/cell_size),floori(box.end.y/cell_size)+1):
    for z in range(floori(box.position.z/cell_size),floori(box.end.z/cell_size)+1):
     var cell:=Vector3i(x,y,z)
     if not grid.has(cell):grid[cell]=[]
     grid[cell].append(key)
 var connected:Dictionary={};var queue:Array=anchored.duplicate();var cursor:=0
 for key in queue:connected[key]=true
 while cursor<queue.size():
  var box:AABB=parts[queue[cursor]].local_box.grow(.13);cursor+=1
  for x in range(floori(box.position.x/cell_size),floori(box.end.x/cell_size)+1):
   for y in range(floori(box.position.y/cell_size),floori(box.end.y/cell_size)+1):
    for z in range(floori(box.position.z/cell_size),floori(box.end.z/cell_size)+1):
     for key in grid.get(Vector3i(x,y,z),[]):
      if not connected.has(key) and box.intersects(parts[key].local_box):connected[key]=true;queue.append(key)
 var fallen:Array=[]
 for key in structure:
  var p:Dictionary=parts[key]
  if not connected.has(key) or (failed_level<999 and p.local_box.get_center().y>failed_level*3.6+.18):fallen.append(key)
 return fallen

func damage_area(point:Vector3,radius:float,amount:float,direction:Vector3)->Dictionary:
 if not enabled or not authoritative() or amount<=0 or radius<=0:return {}
 var changed:Dictionary={};var affected:Dictionary={};var fractured:Array=[];var candidates:Array=[]
 for id in parts.keys():
  var p:Dictionary=parts[id]
  if p.broken or collapsed.has(p.building) or nearest(p.box,point).distance_to(point)>radius:continue
  if can_fracture(p):candidates.append_array(fracture(id));fractured.append(id)
  else:candidates.append(id)
 for id in candidates:
  var p:Dictionary=parts[id];var distance:float=nearest(p.box,point).distance_to(point)
  if distance>radius:continue
  var falloff:float=.28+.72*pow(1-clampf(distance/radius,0,1),.7)
  p.hp=maxf(0,p.hp-amount*falloff);damaged[id]=p.hp;changed[id]=p.hp
  if p.structural:affected[p.building]=true
 if changed.is_empty():return {}
 # Mark removals before the graph is evaluated; presentation is applied below.
 var newly_broken:Array=[]
 for id in changed:
  if changed[id]<=0:parts[id].broken=true;newly_broken.append(id)
 var detached:Array=[];var fallen:Array=[];var rubble_sites:Array=[]
 for key in newly_broken:
  if parts[key].category=="Roof" and not parts[key].building in rubble_sites:rubble_sites.append(parts[key].building)
 for id in affected:
  var islands:Array=unsupported(id)
  detached.append_array(islands)
  for key in islands:
   changed[key]=0;damaged[key]=0
   if parts[key].category=="Roof" and not id in rubble_sites:rubble_sites.append(id)
  var all_walls_gone:=true
  for key in buildings[id].parts:
   var p:Dictionary=parts[key]
   if p.category=="Walls" and not p.broken and not key in islands:all_walls_gone=false;break
  if all_walls_gone:fallen.append(id)
 for id in newly_broken:parts[id].broken=false
 var packet:Dictionary={"revision":revision+1,"damaged":changed,"collapsed":fallen,"fractured":fractured,"detached":detached,"rubble_buildings":rubble_sites,"point":point,"direction":direction,"energy":amount}
 apply_packet(packet,true)
 if "session" in map.game:
  for peer in map.game.session.ready_peers:map.game.session.district_damage.rpc_id(peer,packet)
 return packet
func remove_part(id:String,animate:bool,point:Vector3,direction:Vector3,falling:=false)->void:
 if not parts.has(id) or parts[id].broken:return
 var p:Dictionary=parts[id];hide_geometry(p)
 if cracks.has(id) and is_instance_valid(cracks[id]):cracks[id].queue_free();cracks.erase(id)
 if p.category=="Roof":
  for lamp in buildings[p.building].node.find_children("*","OmniLight3D",true,false):
   if p.box.grow(.8).has_point(lamp.global_position):lamp.visible=false
 if animate and p.kind=="glass":
  var feedback:Node3D=local_feedback()
  if feedback!=null:feedback.sound("glass",point,-8)
 # Remove non-colliding trim in the opening; unbroken physical parts remain intact.
 for entry in buildings[p.building].decor:
  if entry.hidden or not p.box.grow(.30).has_point(entry.point):continue
  entry.hidden=true;removed_details.append(entry)
  var hidden:Transform3D=entry.transform;hidden.basis=Basis().scaled(Vector3.ZERO)
  entry.batch.multimesh.source_transforms[entry.index]=hidden;entry.batch.multimesh.set_instance_transform(entry.index,hidden)
 if animate:
  if event_falling<8 and (p.category=="Roof" or (falling and p.category in ["Floors","Stairs","Interiors"])):spawn_falling(p,direction)
  elif event_fragments<20:spawn_debris(p,point,direction)
func apply_packet(packet:Dictionary,animate:=false)->void:
 var incoming:int=int(packet.get("revision",0))
 if incoming<=revision:return
 revision=incoming;event_fragments=0;event_falling=0
 var detached:Dictionary={}
 for id in packet.get("detached",[]):detached[id]=true
 if authoritative() and animate:schedule_falls(packet)
 for id in packet.get("fractured",[]):
  if parts.has(id):fracture(id)
 for id in packet.get("damaged",{}):
  if not parts.has(id):continue
  var hp:float=float(packet.damaged[id]);parts[id].hp=hp;damaged[id]=hp
  if hp<=0:remove_part(id,animate,packet.get("point",Vector3.ZERO),packet.get("direction",Vector3.UP),detached.has(id))
  elif hp<parts[id].max_hp:show_cracks(id)
 for id in packet.get("collapsed",[]):
  if not buildings.has(id) or collapsed.has(id):continue
  collapsed[id]=true;buildings[id].node.visible=false
  for key in buildings[id].parts:remove_part(key,animate and event_fragments<20,packet.get("point",Vector3.ZERO),packet.get("direction",Vector3.UP))
 for id in packet.get("rubble_buildings",[]):create_physical_rubble(id)
func state()->Dictionary:
 return {"revision":revision,"damaged":damaged.duplicate(),"collapsed":collapsed.keys(),"fractured":fractures.keys(),"rubble_buildings":physical_rubble.keys()}
func accept_state(data:Dictionary)->void:
 if int(data.get("revision",0))==0:return
 revision=-1;apply_packet(data,false)
func show_cracks(id:String)->void:
 if cracks.has(id) or cracks.size()>=128:return
 var p:Dictionary=parts[id]
 if p.category not in ["Walls","Floors"]:return
 var root:=Node3D.new();root.name="StressCracks";add_child(root);root.global_transform=p.pose
 var thin:int=p.size.min_axis_index()
 for sign_side in [-1.0,1.0]:
  var crack:=MeshInstance3D.new();var quad:=QuadMesh.new()
  quad.size=Vector2(p.size.x,p.size.y) if thin==2 else (Vector2(p.size.z,p.size.y) if thin==0 else Vector2(p.size.x,p.size.z))
  crack.mesh=quad;crack.position[thin]=sign_side*(p.size[thin]/2+.006)
  if thin==0:crack.rotation.y=PI/2
  elif thin==1:crack.rotation.x=-PI/2
  var mat:=ShaderMaterial.new();mat.shader=preload("res://shaders/fracture_cracks.gdshader");mat.set_shader_parameter("seed",float(id.sha256_text().substr(0,4).hex_to_int())*.001);crack.material_override=mat;root.add_child(crack)
 cracks[id]=root

func spawn_debris(part:Dictionary,point:Vector3,direction:Vector3)->void:
 if not bool(map.game.preferences.values.get("debris_enabled",true)):return
 var rng:=RandomNumberGenerator.new();rng.seed=(str(revision)+str(part.pose.origin)).sha256_text().substr(0,12).hex_to_int()
 var count:int=4 if part.kind=="glass" else (3 if part.category=="Walls" else 2)
 for shard in range(count):
  if event_fragments>=20:break
  event_fragments+=1
  if debris.size()>=MAX_DYNAMIC:
   var oldest:RigidBody3D=debris.pop_front()
   if is_instance_valid(oldest):rest_piece(oldest);oldest.queue_free()
  var body:=RigidBody3D.new();body.name="FractureRubble";body.collision_layer=64;body.collision_mask=1|64;body.continuous_cd=true
  var size:Vector3=(part.size*Vector3(rng.randf_range(.32,.52),rng.randf_range(.38,.65),rng.randf_range(.38,.65))).min(Vector3(.7,.7,.7)).max(Vector3(.07,.07,.07))
  var points:=PackedVector3Array()
  for x in [-1,1]:
   for y in [-1,1]:
    for z in [-1,1]:points.append(Vector3(x,y,z)*size*.5*Vector3(rng.randf_range(.8,1),rng.randf_range(.8,1),rng.randf_range(.8,1)))
  var shape:=ConvexPolygonShape3D.new();shape.points=points
  var geometry:=MeshInstance3D.new();var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  var faces:Array=[[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]]
  for face in faces:
   for triangle in [[face[0],face[1],face[2]],[face[0],face[2],face[3]]]:
    var a:Vector3=points[triangle[0]];var b:Vector3=points[triangle[1]];var c:Vector3=points[triangle[2]]
    if (b-a).cross(c-a).dot((a+b+c)/3)>0:var swap:Vector3=b;b=c;c=swap
    for vertex in [a,b,c]:surface.set_uv(Vector2(vertex.x,vertex.z));surface.add_vertex(vertex)
  surface.generate_normals();geometry.mesh=surface.commit();geometry.material_override=part.material;body.add_child(geometry)
  var col:=CollisionShape3D.new();col.shape=shape;body.add_child(col)
  var physics:=PhysicsMaterial.new();physics.friction=.82;physics.bounce=.07;body.physics_material_override=physics;body.linear_damp=.28;body.angular_damp=.65
  add_child(body);body.global_transform=Transform3D(part.pose.basis,part.pose*part.local_bounds.get_center());body.global_position+=Vector3(rng.randf_range(-.08,.08),rng.randf_range(-.08,.08),rng.randf_range(-.08,.08))
  var outward:Vector3=(body.global_position-point).normalized();var push:Vector3=(outward*.65+direction.normalized()*.35).normalized()
  var density:float=float({"glass":2500,"timber":650,"steel":7800,"concrete":2400}.get(part.kind,1800))
  body.mass=clampf(size.x*size.y*size.z*density,.3,36)
  body.linear_velocity=push*rng.randf_range(2,6)+Vector3.UP*rng.randf_range(1,3.5);body.angular_velocity=Vector3(rng.randf_range(-3,3),rng.randf_range(-4,4),rng.randf_range(-3,3))
  body.set_meta("life",rng.randf_range(6,9));debris.append(body)
 if event_fragments<=6 and part.kind!="glass":
  var feedback:Node3D=local_feedback()
  if feedback!=null:feedback.particles(part.box.get_center(),Color("aba494"),true,16)

func create_physical_rubble(id:String)->void:
 if physical_rubble.has(id) or not buildings.has(id):return
 var source:Node3D=buildings[id].node
 var rng:=RandomNumberGenerator.new();rng.seed=id.sha256_text().substr(0,12).hex_to_int()
 var root:=Node3D.new();root.name="PersistentStructuralRubble";add_child(root);physical_rubble[id]=root
 var exclude:Array[RID]=[]
 for key in buildings[id].parts:exclude.append(parts[key].body.get_rid())
 var mat:Material
 for key in buildings[id].parts:
  if parts[key].category=="Walls":mat=parts[key].material;break
 for i in range(3):
  var at:Vector3=source.to_global(Vector3(rng.randf_range(-1.8,1.8),0,rng.randf_range(-1.8,1.8)))
  var query:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*18,at-Vector3.UP*24,1);query.exclude=exclude
  var hit:Dictionary=get_world_3d().direct_space_state.intersect_ray(query)
  if hit.is_empty():continue
  at.y=hit.position.y+.008
  var vertices:=PackedVector3Array();var radius:float=rng.randf_range(.75,1.15);var height:float=rng.randf_range(.16,.25)
  vertices.append(Vector3(0,height,0))
  for j in range(8):
   var angle:float=j*TAU/8;vertices.append(Vector3(cos(angle)*radius*rng.randf_range(.85,1),0,sin(angle)*radius*rng.randf_range(.85,1)))
  var body:=StaticBody3D.new();body.name="WalkableRubblePile";root.add_child(body);body.global_position=at
  var collision:=CollisionShape3D.new();var hull:=ConvexPolygonShape3D.new();hull.points=vertices;collision.shape=hull;body.add_child(collision)
  var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for j in range(8):
   var a:Vector3=vertices[j+1];var b:Vector3=vertices[(j+1)%8+1]
   for triangle in [[vertices[0],b,a],[Vector3.ZERO,a,b]]:
    for v in triangle:st.set_uv(Vector2(v.x,v.z));st.add_vertex(v)
  st.generate_normals();var mesh:=MeshInstance3D.new();mesh.mesh=st.commit();mesh.material_override=mat;mesh.visibility_range_end=150;body.add_child(mesh)
 if physical_rubble.size()>64:
  var oldest:String=physical_rubble.keys()[0];var node:Node3D=physical_rubble[oldest];remove_child(node);node.queue_free();physical_rubble.erase(oldest)

func schedule_falls(packet:Dictionary)->void:
 var selected:=0
 var exclude:Array[RID]=[]
 for key in packet.get("damaged",{}):
  if parts.has(key) and float(packet.damaged[key])<=0:exclude.append(parts[key].body.get_rid())
 for key in packet.get("fractured",[]):
  if parts.has(key):exclude.append(parts[key].body.get_rid())
 for id in packet.get("collapsed",[]):
  for key in buildings[id].parts:exclude.append(parts[key].body.get_rid())
 var candidates:Array=packet.get("detached",[]).duplicate()
 for key in packet.get("damaged",{}):
  if float(packet.damaged[key])<=0 and parts.has(key) and parts[key].category=="Roof" and not key in candidates:candidates.append(key)
 for key in candidates:
  if selected>=8 or fall_hazards.size()>=24:break
  var p:Dictionary=parts[key]
  if p.category not in ["Floors","Roof"] or p.box.size.x*p.box.size.z<.5:continue
  fall_hazards.append({"exclude":exclude,"box":p.box,"previous":p.box,"age":0.0,"group":str(packet.revision)+":"+p.building,"damage":clampf(p.box.size.x*p.box.size.z*9,20,75)})
  selected+=1
func _physics_process(delta:float)->void:
 if fall_hazards.is_empty() or not authoritative():return
 if "paused" in map.game and map.game.paused:return
 var actors:Array=map.game.session.actors.values() if "session" in map.game else [map.game]
 var gravity:float=float(ProjectSettings.get_setting("physics/3d/default_gravity",9.8))
 for i in range(fall_hazards.size()-1,-1,-1):
  var fall:Dictionary=fall_hazards[i];fall.age+=delta
  var current:AABB=fall.box;current.position.y-=1.5*fall.age+.5*gravity*fall.age*fall.age
  var stopped:=false
  var old:AABB=fall.previous
  for uv in [Vector2(.5,.5),Vector2(.04,.04),Vector2(.96,.04),Vector2(.04,.96),Vector2(.96,.96)]:
   var before:=Vector3(old.position.x+uv.x*old.size.x,old.position.y+.015,old.position.z+uv.y*old.size.z)
   var after:=Vector3(before.x,current.position.y,before.z)
   var query:=PhysicsRayQueryParameters3D.create(before,after,1);query.exclude=fall.exclude;query.hit_from_inside=true
   var hit:Dictionary=get_world_3d().direct_space_state.intersect_ray(query)
   if not hit.is_empty():current.position.y=maxf(current.position.y,hit.position.y+.02);stopped=true
  var swept:AABB=current.merge(fall.previous);fall.previous=current
  for actor in actors:
   var key:String=fall.group+":"+str(actor.get_instance_id())
   if fall_hits.has(key) or actor.hp<=0:continue
   var target:Vector3=actor.player.global_position+Vector3.UP*(.35 if actor.fusion.spider.active() else 1.0)
   if nearest(swept,target).distance_to(target)>.3:continue
   fall_hits[key]=true
   var direction:Vector3=(target-fall.box.get_center()).slide(Vector3.UP).normalized()
   if direction.length()<.01:direction=Vector3.FORWARD
   actor.receive_environment_hit(fall.damage,direction,target)
  if not "session" in map.game:
   for enemy in map.game.enemies:
    var key:String=fall.group+":"+str(enemy.body.get_instance_id())
    if fall_hits.has(key) or enemy.hp<=0:continue
    var target:Vector3=enemy.body.global_position+Vector3.UP
    if nearest(swept,target).distance_to(target)>.3:continue
    fall_hits[key]=true;map.game.perform_hit(enemy,fall.damage,0,Vector3.RIGHT,6,2,.8,1.6,false,true,"heavy")
  if stopped or fall.age>3.0 or current.end.y<0:fall_hazards.remove_at(i)
 if fall_hazards.is_empty():fall_hits.clear()

func local_feedback()->Node3D:
 if "session" in map.game:
  var actor:Node3D=map.game.session.actors.get(map.game.session.local_id())
  return actor.feedback if actor!=null else null
 return map.game.feedback

func spawn_falling(part:Dictionary,direction:Vector3)->void:
 event_falling+=1
 if debris.size()>=MAX_DYNAMIC:
  var old:RigidBody3D=debris.pop_front()
  if is_instance_valid(old):old.queue_free()
 var body:=RigidBody3D.new();body.name="FallingStructure";body.collision_layer=64;body.collision_mask=1|64;body.mass=300;body.continuous_cd=true;body.linear_damp=.22;body.angular_damp=.6
 var geometry:=MeshInstance3D.new();var shape:Shape3D
 if part.collision.shape is BoxShape3D:
  var mesh:=BoxMesh.new();mesh.size=part.size;geometry.mesh=mesh;shape=part.collision.shape.duplicate()
 else:
  var meshes:Array=part.body.find_children("*","MeshInstance3D",true,false)
  if meshes.is_empty():return
  geometry.mesh=meshes[0].mesh;geometry.position=-part.local_bounds.get_center();shape=geometry.mesh.create_convex_shape()
 geometry.material_override=part.material;body.add_child(geometry)
 var col:=CollisionShape3D.new();col.shape=shape;col.position=geometry.position;body.add_child(col)
 add_child(body);body.global_transform=Transform3D(part.pose.basis,part.pose*part.local_bounds.get_center())
 for other in debris:
  if is_instance_valid(other) and other.name.begins_with("FallingStructure"):body.add_collision_exception_with(other);other.add_collision_exception_with(body)
 body.linear_velocity=direction.normalized()*.6+Vector3.DOWN*1.5;body.angular_velocity=Vector3(.35,.15,-.28);body.set_meta("life",8.0);debris.append(body)

func rest_piece(body:RigidBody3D)->void:
 if not is_instance_valid(body) or not body.get_child(0) is MeshInstance3D:return
 var copy:=MeshInstance3D.new();var source:MeshInstance3D=body.get_child(0)
 copy.mesh=source.mesh;copy.material_override=source.material_override;copy.visibility_range_end=90;add_child(copy);copy.global_transform=source.global_transform
 if not body.sleeping:
  var query:=PhysicsRayQueryParameters3D.create(copy.global_position+Vector3.UP*.1,copy.global_position-Vector3.UP*55,1)
  var hit:Dictionary=get_world_3d().direct_space_state.intersect_ray(query)
  if hit.is_empty():copy.queue_free();return
  var box:AABB=copy.global_transform*copy.get_aabb();copy.global_position.y+=hit.position.y+.015-box.position.y
 rubble.append(copy)
 if rubble.size()>MAX_RESTING:
  var oldest:Node3D=rubble.pop_front()
  if is_instance_valid(oldest):oldest.queue_free()
func _process(delta:float)->void:
 if "paused" in map.game and map.game.paused:return
 for i in range(debris.size()-1,-1,-1):
  var body:RigidBody3D=debris[i]
  if not is_instance_valid(body):debris.remove_at(i);continue
  var life:float=float(body.get_meta("life",6))-delta;body.set_meta("life",life)
  if life<=0 or body.sleeping:rest_piece(body);body.queue_free();debris.remove_at(i)
func reset_world()->void:
 for body in debris:
  if is_instance_valid(body):body.queue_free()
 debris.clear();damaged.clear();collapsed.clear();revision=0;fall_hazards.clear();fall_hits.clear()
 for node in physical_rubble.values():
  if is_instance_valid(node):remove_child(node);node.queue_free()
 physical_rubble.clear()
 for crack in cracks.values():
  if is_instance_valid(crack):crack.queue_free()
 cracks.clear()
 for piece in rubble:
  if is_instance_valid(piece):piece.queue_free()
 rubble.clear()
 for id in fractures:
  for key in fractures[id]:
   buildings[parts[key].building].parts.erase(key);parts.erase(key)
 for node in fracture_nodes:
  if is_instance_valid(node):node.get_parent().remove_child(node);node.queue_free()
 fracture_nodes.clear();fractures.clear()
 for entry in removed_details:
  entry.batch.multimesh.source_transforms[entry.index]=entry.transform;entry.batch.multimesh.set_instance_transform(entry.index,entry.transform);entry.hidden=false
 removed_details.clear()
 for b in buildings.values():
  b.node.show();b.hp=b.max_hp
  for lamp in b.node.find_children("*","OmniLight3D",true,false):lamp.visible=true
 for p in parts.values():
  p.hp=p.max_hp;p.broken=false;p.fractured=false;p.body.visible=true
  p.body.set_deferred("collision_layer",p.layer);p.body.set_deferred("collision_mask",p.mask);p.collision.set_deferred("disabled",false)
  if is_instance_valid(p.batch) and p.index>=0:
   p.batch.multimesh.source_transforms[p.index]=p.transform;p.batch.multimesh.set_instance_transform(p.index,p.transform)

func set_paused(value:bool)->void:
 for body in debris:
  if not is_instance_valid(body):continue
  if value:
   body.set_meta("pause_velocity",body.linear_velocity);body.set_meta("pause_spin",body.angular_velocity);body.freeze=true
  elif body.has_meta("pause_velocity"):
   body.freeze=false;body.linear_velocity=body.get_meta("pause_velocity");body.angular_velocity=body.get_meta("pause_spin")

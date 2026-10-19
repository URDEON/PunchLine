extends RefCounted
## Runtime layout: measured mecha/tower routes stay fixed; ordinary streetside parcels vary by seed.
var rng:=RandomNumberGenerator.new()
var lots:Array=[]
var sidewalks:Array[PackedVector2Array]=[]
var occupied:Array=[]
var access_routes:Array=[]
var terrain_masks:Array=[]
var sidewalk_regions:Array=[]
var road_masks:Array=[]
var parking_masks:Array=[]
var ids:Dictionary={}
func poly(points:Array)->PackedVector2Array:
 var p:=PackedVector2Array()
 for v in points:p.append(Vector2(v[0],v[1]))
 return p
func area(p:PackedVector2Array)->float:
 var result:=0.0
 for i in range(p.size()):result+=p[i].cross(p[(i+1)%p.size()])
 return absf(result)*.5
func rect(p:PackedVector2Array)->Rect2:
 var box:=Rect2(p[0],Vector2.ZERO)
 for v in p:box=box.expand(v)
 return box
func item(p:PackedVector2Array)->Dictionary:return {"polygon":p,"bounds":rect(p)}
func overlaps(a:PackedVector2Array,b:PackedVector2Array)->bool:
 for intersection in Geometry2D.intersect_polygons(a,b):
  if area(intersection)>.002:return true
 return false
func hits(p:PackedVector2Array,items:Array)->bool:
 var box:=rect(p)
 for q in items:
  if box.intersects(q.bounds) and overlaps(p,q.polygon):return true
 return false
func arrays(p:PackedVector2Array)->Array:
 var result:Array=[]
 for v in p:result.append([snappedf(v.x,.001),snappedf(v.y,.001)])
 return result
func shape(b:Dictionary,margin:=0.0,back_extra:=0.0)->PackedVector2Array:
 var points:=PackedVector2Array()
 for p in [Vector2(-b.width/2-margin,-b.depth/2-margin-back_extra),Vector2(b.width/2+margin,-b.depth/2-margin-back_extra),Vector2(b.width/2+margin,b.depth/2+margin+1.2),Vector2(-b.width/2-margin,b.depth/2+margin+1.2)]:
  var q:Array=world_point(b,p);points.append(Vector2(q[0],q[1]))
 return points
func world_point(b:Dictionary,p:Vector2)->Array:
 return [b.center[0]+cos(b.rotation)*p.x+sin(b.rotation)*p.y,b.center[1]-sin(b.rotation)*p.x+cos(b.rotation)*p.y]
func nearest_sidewalk(point:Vector2,lot:Dictionary,width:float)->Vector2:
 var candidates:Array=[]
 for ring in sidewalks:
  for i in range(ring.size()-1):
   var q:Vector2=Geometry2D.get_closest_point_to_segment(point,ring[i],ring[i+1])
   candidates.append({"point":q,"distance":point.distance_squared_to(q)})
 candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.distance<b.distance)
 var seen:Dictionary={};var tested:=0
 for candidate in candidates:
  var key:=Vector2i(candidate.point*4)
  if seen.has(key):continue
  seen[key]=true;tested+=1
  if tested>50 or candidate.distance>6400:break
  var route:PackedVector2Array=path_polygon(point,candidate.point,width)
  if hits(route,parking_masks):continue
  var foreign:=false
  for other in lots:
   if other.id!=lot.id and rect(route).intersects(other.bounds) and overlaps(route,other.polygon):foreign=true;break
  if foreign:continue
  var road_area:=0.0
  for mask in road_masks:
   if not rect(route).intersects(mask.bounds):continue
   for intersection in Geometry2D.intersect_polygons(route,mask.polygon):road_area+=area(intersection)
  if road_area>width*.49:continue
  var pieces:Array=[route]
  for region in lot.connection_regions:
   var next:Array=[]
   for piece in pieces:next.append_array(Geometry2D.clip_polygons(piece,region))
   pieces=next
  for region in sidewalk_regions:
   if pieces.is_empty():break
   var next:Array=[]
   for piece in pieces:
    if rect(piece).intersects(region.bounds):next.append_array(Geometry2D.clip_polygons(piece,region.polygon))
    else:next.append(piece)
   pieces=next
  var uncovered:=0.0
  for piece in pieces:uncovered+=area(piece)
  if uncovered<.003:return candidate.point
 return Vector2(INF,INF)
func path_polygon(a:Vector2,b:Vector2,width:float)->PackedVector2Array:
 var side:Vector2=(b-a).normalized().orthogonal()*width*.5
 return PackedVector2Array([a+side,a-side,b-side,b+side])
func prepare(base:Dictionary)->void:
 lots.clear();sidewalks.clear();occupied.clear();access_routes.clear();terrain_masks.clear();sidewalk_regions.clear();road_masks.clear();parking_masks.clear();ids.clear()
 var vector:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/vector_meshes.json"))
 var lot_ids:Dictionary={}
 var geo:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/district_lots.json"))
 for lot in geo.lots:lot_ids[lot.source_feature]=lot.id
 for feature in vector.features:
  if feature.layer=="Lots":
   var p:PackedVector2Array=poly(feature.rings[0]);lots.append({"id":lot_ids[feature.label],"polygon":p,"bounds":rect(p),"area":area(p),"connection_regions":Geometry2D.offset_polygon(p,.49,Geometry2D.JOIN_ROUND)})
  elif feature.layer=="Sidewalks":
   for ring in feature.rings:sidewalks.append(poly(ring))
   # Triangles preserve the holes inside sidewalk rings; filled ring offsets would
   # incorrectly classify entire city blocks as pavement.
   for triangle in feature.triangles:
    for grown in Geometry2D.offset_polygon(poly(triangle),.49,Geometry2D.JOIN_ROUND):sidewalk_regions.append(item(grown))
  if feature.layer in ["Sidewalks","Roads","Parking"]:
   for tri in feature.triangles:
    var mask:Dictionary=item(poly(tri));terrain_masks.append(mask)
    if feature.layer=="Roads":road_masks.append(mask)
    elif feature.layer=="Parking":parking_masks.append(mask)
 for b in base.buildings:
  for reserved in Geometry2D.offset_polygon(poly(b.support_footprint),.5,Geometry2D.JOIN_MITER):occupied.append(item(reserved))
  for triangle in b.get("path_triangles",[]):access_routes.append(item(poly(triangle)))
func clear_site(p:PackedVector2Array,lot:Dictionary)->bool:
 for outside in Geometry2D.clip_polygons(p,lot.polygon):
  if area(outside)>.002:return false
 return not hits(p,terrain_masks) and not hits(p,occupied) and not hits(p,access_routes)
func new_building(lot:Dictionary,point:Vector2)->Dictionary:
 var roll:float=rng.randf();var storeys:=1
 var type:="small_residential"
 if roll<.20:type="corner_shop"
 elif roll<.39:type="courtyard_home"
 elif roll<.55:type="terrace_home"
 elif roll>.79:storeys=rng.randi_range(2,4);type="apartment_"+str(storeys)
 var width:float=14.0 if storeys>1 else rng.randf_range(8.8,12.8)
 var depth:float=14.0 if storeys>1 else rng.randf_range(8.6,12.2)
 var walk:Vector2=nearest_sidewalk(point,lot,4.08 if storeys>1 else 3.95)
 if not walk.is_finite():return {}
 var front:Vector2=(walk-point).normalized()
 return {"lot":lot.id,"id":"","archetype":type,"access":"shared_building" if storeys>1 else "player_only","storeys":storeys,"storey_height":3.6,"width":width,"depth":depth,"height":storeys*3.6-.2 if storeys>1 else rng.randf_range(3.5,4.1),"door_width":4.08 if storeys>1 else 3.0,"door_height":3.22 if storeys>1 else 2.4,"center":[snappedf(point.x,.001),snappedf(point.y,.001)],"rotation":atan2(front.x,front.y),"route_width":4.08 if storeys>1 else 3.95,"sidewalk":[walk.x,walk.y],"yard_depth":4.5 if type in ["courtyard_home","terrace_home"] else 0.0,"shop_name":["PANADERÍA","CAFÉ","MINIMARKET","FERRETERÍA","FARMACIA","LIBRERÍA","BICICLETAS","TALLER"][rng.randi_range(0,7)],"style":{"palette":rng.randi_range(0,7),"roof_palette":rng.randi_range(0,4),"roof":"gable" if rng.randf()<.55 else "hip","roof_rise":rng.randf_range(1.05,1.8),"porch":type=="corner_shop" or rng.randf()<.55,"shutters":type!="corner_shop" and rng.randf()<.65,"chimney":rng.randf()<.5,"furniture_side":rng.randi_range(0,1),"sign":rng.randi_range(0,3)}}
func make(settings:Dictionary,source:Dictionary)->Dictionary:
 var seed_text:String=String(settings.get("seed","923"));rng.seed=seed_text.sha256_text().substr(0,15).hex_to_int()
 var plan:Dictionary=source.duplicate(true);var fixed:Array=[]
 for b in source.buildings:
  if String(b.access).begins_with("mecha") or int(b.get("storeys",1))>1:fixed.append(b.duplicate(true))
 plan.buildings=fixed
 prepare(plan)
 var density:int=clampi(int(settings.get("density",2)),0,2)
 for lot in lots:
  var points:Array[Vector2]=[];var cell:=14.5
  var phase:=Vector2(rng.randf_range(0,cell),rng.randf_range(0,cell))
  var box:Rect2=lot.bounds
  for x in range(floori(box.position.x/cell),ceili(box.end.x/cell)):
   for z in range(floori(box.position.y/cell),ceili(box.end.y/cell)):
    points.append(Vector2(x*cell,z*cell)+phase+Vector2(rng.randf_range(-3,3),rng.randf_range(-3,3)))
  for i in range(points.size()-1,0,-1):
   var j:int=rng.randi_range(0,i);var swap:Vector2=points[i];points[i]=points[j];points[j]=swap
  var budget:int=maxi(2,mini(22,int(lot.area/600.0)*[.48,.76,1.0][density]))
  var placed:=0
  for point in points:
   if placed>=budget:break
   if not Geometry2D.is_point_in_polygon(point,lot.polygon):continue
   var b:Dictionary=new_building(lot,point)
   if b.is_empty():continue
   var envelope:PackedVector2Array=shape(b,2.5,b.yard_depth)
   if not clear_site(envelope,lot):continue
   var entry:Array=world_point(b,Vector2(0,b.depth/2));var end:=Vector2(b.sidewalk[0],b.sidewalk[1])
   var route:PackedVector2Array=path_polygon(Vector2(entry[0],entry[1]),end,b.route_width)
   if hits(route,occupied):continue
   var paths:Array=[];var valid:=true
   for clipped in Geometry2D.intersect_polygons(route,lot.polygon):
    var pieces:Array=[clipped]
    for mask in terrain_masks:
     if not rect(clipped).intersects(mask.bounds):continue
     var next:Array=[]
     for piece in pieces:next.append_array(Geometry2D.clip_polygons(piece,mask.polygon))
     pieces=next
    for piece in pieces:
     if Geometry2D.is_polygon_clockwise(piece):continue
     var indices:PackedInt32Array=Geometry2D.triangulate_polygon(piece)
     if indices.size()==0:valid=false;break
     for i in range(0,indices.size(),3):paths.append(arrays(PackedVector2Array([piece[indices[i]],piece[indices[i+1]],piece[indices[i+2]]])))
   if not valid or paths.is_empty():continue
   placed+=1;b.id="SeedBuilding_%02d"%placed;b.entry=entry;b.path_triangles=paths
   # Human-scale doorways are an explicit minority; measured mecha houses stay intact.
   if b.storeys==1 and b.archetype in ["small_residential","courtyard_home","terrace_home"] and (seed_text+lot.id+b.id).sha256_text().substr(0,6).hex_to_int()%4==0:
    b.access="human_only";b.door_width=1.10;b.door_height=2.15
   var footprint:=PackedVector2Array()
   for corner in [Vector2(-b.width/2,-b.depth/2),Vector2(b.width/2,-b.depth/2),Vector2(b.width/2,b.depth/2),Vector2(-b.width/2,b.depth/2)]:
    var p:Array=world_point(b,corner);footprint.append(Vector2(p[0],p[1]))
   b.footprint=arrays(footprint);b.support_footprint=arrays(shape(b))
   b.validated_envelope=b.support_footprint.duplicate(true);b.plot_footprint=arrays(shape(b,.7,b.yard_depth))
   plan.buildings.append(b);occupied.append(item(shape(b,.7,b.yard_depth)))
   for triangle in paths:access_routes.append(item(poly(triangle)))
 plan.seed=seed_text;plan.seed_text=seed_text;plan.density=density;plan.revision="seeded-neighbourhood-2-furnished"
 return plan

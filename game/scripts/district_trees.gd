extends Node3D
## Seeded trunks share collision on every quality; quality changes foliage distance only.
var trees:Array=[]
var foliage:Array[MultiMeshInstance3D]=[]
var bark:StandardMaterial3D
var leaf_materials:Array[ShaderMaterial]=[]
var rng:=RandomNumberGenerator.new()
func setup(placement:RefCounted,seed_text:String)->void:
 name="SeededTrees";rng.seed=seed_text.sha256_text().substr(0,15).hex_to_int()+31573
 bark=StandardMaterial3D.new();bark.albedo_color=Color("65564a");bark.roughness=.96
 bark.albedo_texture=preload("res://housing/textures/wood.png") if ResourceLoader.exists("res://housing/textures/wood.png") else null
 var cylinder:=CylinderMesh.new();cylinder.top_radius=.64;cylinder.bottom_radius=1;cylinder.height=1;cylinder.radial_segments=8
 var branch_transforms:Array[Transform3D]=[];var leaves:Array=[[],[]]
 var cards:=QuadMesh.new();cards.size=Vector2(1,1)
 for texture_path in ["res://assets/environment/v098/urban/Textures/treeA.png","res://assets/environment/v098/urban/Textures/treeB.png"]:
  var mat:=ShaderMaterial.new();mat.shader=preload("res://shaders/district_foliage.gdshader");mat.set_shader_parameter("leaves",load(texture_path));mat.set_shader_parameter("leaf_region",Vector4(.10,.02,.80,.70) if leaf_materials.is_empty() else Vector4(.17,.28,.66,.48));leaf_materials.append(mat)
 var centres:Array[Vector2]=[]
 for lot in placement.lots:
  var box:Rect2=lot.bounds
  var budget:int=clampi(int(box.get_area()/700),2,24);var placed:=0
  for attempt in range(180):
   if placed>=budget:break
   var point:Vector2=box.position+Vector2(rng.randf(),rng.randf())*box.size
   if not placement.safe_in_lot(point,lot,3.1) or placement.blocked(point,3.1):continue
   var close:=false
   for other in centres:
    if point.distance_squared_to(other)<45:close=true;break
   if close:continue
   centres.append(point);placed+=1
   var pine:bool=rng.randf()<.32;var height:float=rng.randf_range(5.2,8.8) if pine else rng.randf_range(4.4,7.2)
   var width:float=rng.randf_range(1.7,2.4);var radius:float=rng.randf_range(.14,.22)
   var base:=Vector3(point.x,.03,point.y)
   var body:=StaticBody3D.new();body.name="TreeTrunk%03d"%trees.size();body.collision_layer=1;body.collision_mask=0
   var shape:=CylinderShape3D.new();shape.radius=radius;shape.height=height*.68
   var col:=CollisionShape3D.new();col.shape=shape;col.position.y=shape.height/2;body.add_child(col);add_child(body);body.position=base
   trees.append({"body":body,"point":point,"height":height,"radius":radius,"pine":pine})
   branch_transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(radius,height*.72,radius)),base+Vector3.UP*height*.36))
   if pine:
    for level in range(6):
     var whorl_height:float=height*(.32+level*.115)
     var reach:float=width*(1.0-level*.135)
     for j in range(5):
      var angle:float=j*TAU/5+level*.55
      var pos:Vector3=base+Vector3(cos(angle)*reach*.36,whorl_height,sin(angle)*reach*.36)
      var basis:=Basis.from_euler(Vector3(rng.randf_range(-.35,.35),angle,0)).scaled(Vector3(reach*1.7,height*.24,1))
      leaves[1].append(Transform3D(basis,pos))
   else:
    for j in range(5):
     var angle:float=j*TAU/5+rng.randf_range(-.2,.2)
     var start:Vector3=base+Vector3.UP*height*.46
     var end:Vector3=base+Vector3(cos(angle)*width*.64,height*rng.randf_range(.65,.80),sin(angle)*width*.64)
     var offset:Vector3=end-start
     branch_transforms.append(Transform3D(Basis(Quaternion(Vector3.UP,offset.normalized())).scaled(Vector3(radius*.48,offset.length(),radius*.48)),(start+end)*.5))
    for j in range(15):
     var angle:float=j*2.39996;var spread:float=width*sqrt(float(j%7)/7)
     var pos:=base+Vector3(cos(angle)*spread,height*rng.randf_range(.68,.88),sin(angle)*spread)
     var basis:=Basis.from_euler(Vector3(rng.randf_range(-.6,.6),rng.randf()*TAU,0)).scaled(Vector3(width*1.65,width*1.55,1))
     leaves[0].append(Transform3D(basis,pos))
 make_batch("TrunksAndBranches",cylinder,branch_transforms,bark,320)
 for i in range(2):foliage.append_array(make_batch("Canopy"+str(i),cards,leaves[i],leaf_materials[i],160))
 set_meta("tree_count",trees.size())
func make_batch(label:String,mesh:Mesh,transforms:Array,mat:Material,distance:float)->Array:
 var cells:Dictionary={};var result:Array=[]
 for transform in transforms:
  var key:=Vector2i(floori(transform.origin.x/32),floori(transform.origin.z/32))
  if not cells.has(key):cells[key]=[]
  cells[key].append(transform)
 for key in cells:
  var batch:=MultiMeshInstance3D.new();batch.name=label+str(key);batch.material_override=mat;batch.position=Vector3(key.x*32,0,key.y*32)
  var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.mesh=mesh;mm.instance_count=cells[key].size()
  for i in range(cells[key].size()):
   var transform:Transform3D=cells[key][i];transform.origin-=batch.position
   mm.set_instance_transform(i,transform);mm.set_instance_color(i,Color(rng.randf_range(.85,1.1),rng.randf_range(.88,1.08),rng.randf_range(.85,1.05)))
  batch.multimesh=mm;batch.visibility_range_end=distance;add_child(batch);result.append(batch)
 return result
func apply_settings(values:Dictionary)->void:
 var quality:int=clampi(int(values.get("graphics_preset",1)),0,2)
 for batch in foliage:
  batch.visibility_range_end=[85.0,140.0,220.0][quality]
  batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if quality==0 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
 for mat in leaf_materials:mat.set_shader_parameter("wind",float(values.get("grass_wind",.55)))

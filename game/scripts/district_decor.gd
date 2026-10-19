extends Node3D
## Deterministic park furniture occupies only free lot interiors, never measured accesses.
var placements:Array[Dictionary]=[]
var batches:Dictionary={}
var rng:=RandomNumberGenerator.new()
func setup(placement:RefCounted,trees:Node3D,seed_text:String)->void:
 name="SeededParkDetails";rng.seed=seed_text.sha256_text().substr(0,15).hex_to_int()+7291
 var wood:=material(Color("76604a"));var metal:=material(Color("34474b"));var stone:=material(Color("8c9184"))
 var colours:Array=[material(Color("d6b461")),material(Color("a697b9")),material(Color("d4b7a2"))]
 for lot in placement.lots:
  var used:=0;var budget:int=clampi(int(lot.bounds.get_area()/1100),2,12)
  for attempt in range(180):
   if used>=budget:break
   var point:Vector2=lot.bounds.position+Vector2(rng.randf(),rng.randf())*lot.bounds.size
   if not placement.safe_in_lot(point,lot,2.2) or placement.blocked(point,2.2):continue
   var close:=false
   for tree in trees.trees:
    if point.distance_squared_to(tree.point)<5.5:close=true;break
   if close:continue
   var kind:int=used%4;var origin:=Vector3(point.x,.035,point.y);var yaw:float=rng.randf()*TAU
   var frame:=Transform3D(Basis(Vector3.UP,yaw),origin)
   var group:=Node3D.new();group.name=["ParkBench","RockGarden","FlowerPlanter","ParkLantern"][kind]+str(placements.size());add_child(group);group.transform=frame
   if kind==0:
    box(group,Vector3(1.9,.16,.55),Vector3(0,.5,0),wood,true)
    box(group,Vector3(1.9,.55,.12),Vector3(0,.85,.28),wood,true)
    for x in [-.72,.72]:box(group,Vector3(.12,.5,.48),Vector3(x,.25,0),metal,true)
    for x in [-.9,.9]:box(group,Vector3(.08,.08,.6),Vector3(x,.78,0),metal,false)
    for z in [-.19,0,.19]:box(group,Vector3(1.88,.022,.025),Vector3(0,.592,z),metal,false)
   elif kind==1:
    for i in range(4):
     var shape:=SphereMesh.new();shape.radius=1;shape.height=2;shape.radial_segments=7;shape.rings=4
     var mesh:=MeshInstance3D.new();mesh.mesh=shape;mesh.material_override=stone;mesh.position=Vector3(rng.randf_range(-.65,.65),.22,rng.randf_range(-.55,.55));mesh.scale=Vector3(rng.randf_range(.35,.65),rng.randf_range(.24,.5),rng.randf_range(.3,.6));group.add_child(mesh)
    box(group,Vector3(1.5,.45,1.3),Vector3(0,.225,0),stone,true,false)
   elif kind==2:
    box(group,Vector3(1.6,.45,1.15),Vector3(0,.225,0),stone,true)
    box(group,Vector3(1.4,.06,.95),Vector3(0,.47,0),material(Color("453e2e")),false)
    for i in range(10):
     var at:=Vector3(rng.randf_range(-.6,.6),.52,rng.randf_range(-.36,.36));var height:float=rng.randf_range(.22,.52)
     box(group,Vector3(.025,height,.025),at+Vector3.UP*height/2,metal,false)
     var petal:=SphereMesh.new();petal.radius=.075;petal.height=.09;petal.radial_segments=6;petal.rings=3
     var flower:=MeshInstance3D.new();flower.mesh=petal;flower.material_override=colours[i%3];flower.position=at+Vector3.UP*height;group.add_child(flower)
   else:
    box(group,Vector3(.2,2.9,.2),Vector3(0,1.45,0),metal,true)
    box(group,Vector3(.58,.1,.58),Vector3(0,3.13,0),metal,false)
    var glow:=material(Color("e1d4a4"));glow.emission_enabled=true;glow.emission=Color("eecb91");glow.emission_energy_multiplier=.6
    box(group,Vector3(.38,.46,.38),Vector3(0,2.86,0),glow,false)
   placements.append({"point":point,"kind":kind,"yaw":yaw,"lot":lot.label});used+=1
   var r:=1.65;placement.add_mask([PackedVector2Array([point+Vector2(-r,-r),point+Vector2(r,-r),point+Vector2(r,r),point+Vector2(-r,r)])],.55)
 set_meta("decoration_count",placements.size())
func material(colour:Color)->StandardMaterial3D:
 var mat:=StandardMaterial3D.new();mat.albedo_color=colour;mat.roughness=.85;return mat
func box(parent:Node3D,size:Vector3,at:Vector3,mat:Material,collision:bool,visible_mesh:=true)->void:
 var holder:Node3D=StaticBody3D.new() if collision else Node3D.new();parent.add_child(holder);holder.position=at
 if visible_mesh:
  var mesh:=MeshInstance3D.new();var shape:=BoxMesh.new();shape.size=size;mesh.mesh=shape;mesh.material_override=mat;holder.add_child(mesh)
 if collision:
  var shape:=CollisionShape3D.new();var box_shape:=BoxShape3D.new();box_shape.size=size;shape.shape=box_shape;holder.add_child(shape)

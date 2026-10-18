@tool
extends Node3D
## Editable geometric architecture. All detail stays in the validated building envelope.
@export_file("*.json") var plan_path:="res://housing/data/generated_plan.json"
const REVISION:="architecture-2.1"
const WALL_COLORS:=[Color("e5d7b7"),Color("d2ae88"),Color("b9c6b1"),Color("c2cfce"),Color("cba28e"),Color("d8d0bc"),Color("b5c4ca"),Color("eadfcb")]
const ROOF_COLORS:=[Color("b56b4d"),Color("925247"),Color("676d70"),Color("a37451"),Color("7c8b85")]
var materials:Dictionary={}
var detail_batches:Dictionary={}
var active_building:Node3D

func material(key:String,color:Color,texture:="",tile:=1.0)->StandardMaterial3D:
	if not materials.has(key):
		var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.88
		if texture!="":
			var base:String=get_script().resource_path.get_base_dir().get_base_dir()
			m.albedo_texture=load(base+"/textures/"+texture+".png")
			m.uv1_triplanar=true;m.uv1_world_triplanar=true;m.uv1_scale=Vector3.ONE*tile
			m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		materials[key]=m
	return materials[key]

func category(parent:Node3D,label:String)->Node3D:
	var node:=Node3D.new();node.name=label;parent.add_child(node);return node

func box_mesh(size:Vector3)->BoxMesh:
	var box:=BoxMesh.new();box.size=size;return box

func visual(parent:Node3D,label:String,size:Vector3,at:Vector3,mat:Material)->MeshInstance3D:
	var mesh:=MeshInstance3D.new();mesh.name=label;mesh.position=at;mesh.mesh=box_mesh(size);mesh.material_override=mat
	mesh.visibility_range_end=320;mesh.visibility_range_end_margin=20;parent.add_child(mesh);return mesh

func part(parent:Node3D,label:String,size:Vector3,at:Vector3,mat:Material)->StaticBody3D:
	var body:=StaticBody3D.new();body.name=label;body.position=at;parent.add_child(body)
	if is_instance_valid(active_building) and mat!=null:detail(parent,size,at,mat)
	else:visual(body,"Mesh",size,Vector3.ZERO,mat)
	var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;col.shape=shape;body.add_child(col);return body

func detail(parent:Node3D,size:Vector3,at:Vector3,mat:Material,rotation:=Vector3.ZERO)->void:
	# Repeated trim uses one draw per material per category; transforms remain editable.
	var target:Node3D=parent
	if is_instance_valid(active_building):
		while target!=active_building and target.get_parent()!=active_building:target=target.get_parent() as Node3D
	var transform:=Transform3D(Basis.from_euler(rotation).scaled(size),at)
	transform=relative_transform(parent,target)*transform
	var key:String=str(target.get_instance_id())+":"+str(mat.get_instance_id())
	if not detail_batches.has(key):detail_batches[key]={"parent":target,"material":mat,"transforms":[]}
	detail_batches[key].transforms.append(transform)

func relative_transform(node:Node3D,ancestor:Node3D)->Transform3D:
	# Baking starts in SceneTree._initialize, before nodes necessarily enter the tree.
	# Compose local transforms instead of querying invalid global transforms.
	var result:=Transform3D.IDENTITY
	var current:Node3D=node
	while current!=ancestor:
		result=current.transform*result
		current=current.get_parent() as Node3D
	return result

func flush_details()->void:
	for key in detail_batches:
		var group:Dictionary=detail_batches[key]
		var node:=MultiMeshInstance3D.new();node.name="TrimBatch";node.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;node.multimesh=load(get_script().resource_path.get_base_dir()+"/BakedMultiMesh.gd").new();node.multimesh.transform_format=MultiMesh.TRANSFORM_3D
		node.multimesh.mesh=box_mesh(Vector3.ONE);node.multimesh.instance_count=group.transforms.size();node.material_override=group.material
		var saved:Array[Transform3D]=[];saved.assign(group.transforms);node.multimesh.source_transforms=saved
		node.visibility_range_end=250;node.visibility_range_end_margin=15;group.parent.add_child(node)
	detail_batches.clear()

func finish_build(root:Node3D)->void:
	flush_details();active_building=null
	# Roofs, walls, glass, plants and labels must disappear at the same distance.
	# Different limits left floating roofs above invisible houses in the real game.
	for geometry in root.find_children("*","GeometryInstance3D",true,false):
		geometry.visibility_range_end=320
		geometry.visibility_range_end_margin=20
		geometry.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF

func generate()->Dictionary:
	var data=JSON.parse_string(FileAccess.get_file_as_string(plan_path))
	if not data is Dictionary or not data.has("buildings"):push_error("Invalid housing plan");return {}
	var fingerprint:String=(REVISION+JSON.stringify(data)).sha256_text()
	if get_meta("plan_hash","")==fingerprint:return data
	for label in ["GeneratedBuildings","GeneratedPaths"]:
		var previous:=get_node_or_null(NodePath(label))
		if previous:remove_child(previous);previous.free()
	var container:=category(self,"GeneratedBuildings")
	var paths:=category(self,"GeneratedPaths")
	for b in data.buildings:
		var lot:=container.get_node_or_null(NodePath(b.lot)) as Node3D
		if not lot:lot=category(container,b.lot)
		var building:=category(lot,b.id);building.position=Vector3(b.center[0],.146,b.center[1]);building.rotation.y=b.rotation
		building.set_meta("access",b.access);building.set_meta("archetype",b.archetype);building.set_meta("entry",b.entry)
		build(building,b)
		build_path(paths,b)
	set_meta("plan_hash",fingerprint);return data

func build_path(parent:Node3D,b:Dictionary)->void:
	var triangles:Array=b.get("path_triangles",[])
	if triangles.is_empty():return
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in triangles:
		var a:=Vector3(tri[0][0],.034,tri[0][1]);var bb:=Vector3(tri[1][0],.034,tri[1][1]);var c:=Vector3(tri[2][0],.034,tri[2][1])
		triangle(st,a,bb,c,(a+bb+c)/3-Vector3.UP*.1)
	var mesh:=MeshInstance3D.new();mesh.name=b.lot+"_"+b.id;mesh.mesh=st.commit();mesh.material_override=material("garden_path",Color("aaa28b"),"pavers",1.0);parent.add_child(mesh)

func build(root:Node3D,b:Dictionary)->void:
	active_building=root
	var ew:float=b.width;var ed:float=b.depth;var h:float=b.height
	var w:float=ew-.4;var dw:float=b.door_width;var dh:float=b.door_height
	var style:Dictionary=b.get("style",{})
	var palette:int=int(style.get("palette",0))%WALL_COLORS.size()
	var roof_palette:int=int(style.get("roof_palette",0))%ROOF_COLORS.size()
	var workshop:bool=b.access in ["mecha_crouch","mecha_standing"]
	var shop:bool=b.archetype in ["corner_shop","commercial_hall"]
	var porch:bool=not workshop and (shop or bool(style.get("porch",false)))
	var front:float=ed/2-(.85 if porch else .2);var back:float=-ed/2+.2
	var wall:=material("wall_"+str(palette),WALL_COLORS[palette],"plaster",1.0)
	var trim:=material("trim_"+str(palette),Color("e9e1ce").lerp(WALL_COLORS[palette],.22),"plaster",1.5)
	var dark:=material("wood_"+str(palette),Color("354e48") if palette%2==0 else Color("574237"),"wood",1.2)
	var base:=material("foundation",Color("948e7c"),"brick",.7)
	var floor_mat:=material("floor_work" if workshop else "floor_home",Color("bdc0b8") if workshop else Color("bcaa83"),"concrete" if workshop else "wood",.75)
	var floors:=category(root,"Floors");var walls:=category(root,"Walls");var roofs:=category(root,"Roof")
	roofs.add_to_group("housing_roofs")
	part(floors,"Slab",Vector3(ew,.12,ed),Vector3(0,-.06,0),floor_mat)
	part(roofs,"Ceiling",Vector3(ew,.22,ed),Vector3(0,h+.11,0),trim)
	build_roof(roofs,ew,ed,h,style,roof_palette,wall,trim,workshop)
	if b.access=="inaccessible":
		part(walls,"SolidInaccessible",Vector3(w,h,front-back),Vector3(0,h/2,(front+back)/2),wall)
		finish_build(root);return
	var windows:=category(root,"Windows");var doors:=category(root,"Doors");var accents:=category(root,"FacadeDetails")
	doors.set_meta("functional","permanently open passage");doors.set_meta("clear_width",dw);doors.set_meta("clear_height",dh)
	var side:float=(w-dw)/2
	var front_holes:Array=[{"x":0.0,"width":dw,"bottom":0.0,"height":dh,"kind":"door"}]
	if side>1.2:
		for sign_side in [-1.0,1.0]:front_holes.append({"x":sign_side*(dw/2+side/2),"width":minf(1.55,side-.55),"bottom":1.0,"height":1.25,"kind":"window"})
	wall_with_openings(walls,windows,"Front",Vector3(0,0,front-.125),0,w,h,front_holes,wall,trim,dark,style)
	var rear_holes:Array=[]
	for x in [-w*.24,w*.24]:rear_holes.append({"x":x,"width":1.5,"bottom":1.15 if workshop else .95,"height":1.3,"kind":"window"})
	wall_with_openings(walls,windows,"Back",Vector3(0,0,back+.125),PI,w,h,rear_holes,wall,trim,dark,style)
	var length:float=front-back
	var side_holes:Array=[]
	for x in [-length*.25,length*.25]:side_holes.append({"x":x,"width":minf(1.6,length*.22),"bottom":1.15 if workshop else .95,"height":1.3,"kind":"window"})
	wall_with_openings(walls,windows,"Left",Vector3(-w/2+.125,0,(front+back)/2),-PI/2,length,h,side_holes,wall,trim,dark,style)
	wall_with_openings(walls,windows,"Right",Vector3(w/2-.125,0,(front+back)/2),PI/2,length,h,side_holes,wall,trim,dark,style)
	# Door jambs sit outside the clear aperture. No painted-on or blocking door leaf.
	for sign_side in [-1.0,1.0]:detail(doors,Vector3(.12,dh+.12,.15),Vector3(sign_side*(dw/2+.06),dh/2,front+.035),dark)
	detail(doors,Vector3(dw+.24,.14,.16),Vector3(0,dh+.07,front+.04),dark)
	part(doors,"Threshold",Vector3(dw,.035,.32),Vector3(0,-.0175,front-.06),base)
	if b.has("support_footprint"):
		var ramps:=category(root,"Ramps")
		var ramp:=part(ramps,"EntranceRamp",Vector3(dw,.08,1.2),Vector3(0,-.10,ed/2+.6),floor_mat);ramp.rotation.x=atan2(.12,1.2)
	var rooms:=category(root,"Interiors")
	part(rooms,"PartitionLeft",Vector3(side,h,.2),Vector3(-(dw+side)/2,h/2,0),wall)
	part(rooms,"PartitionRight",Vector3(side,h,.2),Vector3((dw+side)/2,h/2,0),wall)
	# Low masonry plinth, fascia and corners add depth while staying inside the envelope.
	for x in [-w/2+.08,w/2-.08]:
		detail(accents,Vector3(.16,h,.16),Vector3(x,h/2,front-.02),trim)
		detail(accents,Vector3(.16,h,.16),Vector3(x,h/2,back+.02),trim)
	for sign_side in [-1.0,1.0]:
		detail(accents,Vector3(.08,.28,length-.2),Vector3(sign_side*(w/2+.02),.14,(front+back)/2),base)
		detail(accents,Vector3(side,.28,.08),Vector3(sign_side*(dw+side)/2,.14,front+.02),base)
	if porch:
		for x in [-w/2+.25,w/2-.25]:
			detail(accents,Vector3(.14,h,.14),Vector3(x,h/2,ed/2-.14),dark)
			plant(accents,Vector3(x,.02,front+.33),palette)
		if shop:awning(accents,w,front,h,dark,roof_palette)
		else:detail(accents,Vector3(w,.15,.64),Vector3(0,h-.1,front+.30),dark)
	if shop:
		var sign_node:=Label3D.new();sign_node.name="ShopSign";sign_node.text=["ALMACÉN","PANADERÍA","CAFÉ","TALLER DE BARRIO"][int(style.get("sign",0))%4]
		sign_node.font_size=48;sign_node.pixel_size=.006;sign_node.position=Vector3(0,h-.35,front+.11);sign_node.modulate=Color("fff1cf");sign_node.outline_size=5;sign_node.outline_modulate=Color("34453b");accents.add_child(sign_node)
	furnish(rooms,w,back,front,dw,h,workshop,shop,style)
	finish_build(root)
	var count:=0
	for opening in windows.get_children():
		if opening.has_meta("aperture"):count+=1
	root.set_meta("window_count",count);root.set_meta("architecture_revision",REVISION);root.set_meta("style",style)

func wall_with_openings(parent:Node3D,windows:Node3D,label:String,at:Vector3,yaw:float,length:float,height:float,holes:Array,wall:Material,trim:Material,dark:Material,style:Dictionary)->void:
	var group:=category(parent,label);group.position=at;group.rotation.y=yaw
	var cuts:Array[float]=[-length/2,length/2]
	for hole in holes:cuts.append(hole.x-hole.width/2);cuts.append(hole.x+hole.width/2)
	cuts.sort()
	for i in range(cuts.size()-1):
		var left:float=cuts[i];var right:float=cuts[i+1]
		if right-left<.001:continue
		var mid:float=(left+right)/2;var opening:Dictionary={}
		for hole in holes:
			if mid>hole.x-hole.width/2-.001 and mid<hole.x+hole.width/2+.001:opening=hole;break
		if opening.is_empty():part(group,"Pier_"+str(i),Vector3(right-left,height,.25),Vector3(mid,height/2,0),wall)
		else:
			var bottom:float=opening.bottom;var top:float=bottom+opening.height
			if bottom>.001:part(group,"Below_"+str(i),Vector3(right-left,bottom,.25),Vector3(mid,bottom/2,0),wall)
			if height-top>.001:part(group,"Above_"+str(i),Vector3(right-left,height-top,.25),Vector3(mid,(height+top)/2,0),wall)
	for i in range(holes.size()):
		var hole:Dictionary=holes[i]
		if hole.kind!="window":continue
		var opening:=category(windows,label+"_"+str(i));opening.position=at;opening.rotation.y=yaw
		opening.set_meta("aperture",Rect2(hole.x-hole.width/2,hole.bottom,hole.width,hole.height))
		window(opening,hole,trim,dark,bool(style.get("shutters",true)))

func window(parent:Node3D,hole:Dictionary,trim:Material,dark:Material,shutters:bool)->void:
	var x:float=hole.x;var bottom:float=hole.bottom;var ww:float=hole.width;var hh:float=hole.height
	var glass:=material("clear_glass",Color(.68,.85,.87,.17));glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glass.cull_mode=BaseMaterial3D.CULL_DISABLED;glass.roughness=.12
	# Glass occupies the actual hole. There is no wall behind it; physics still blocks climbing through.
	part(parent,"Glass",Vector3(ww-.09,hh-.09,.025),Vector3(x,bottom+hh/2,0),glass)
	for sx in [-1.0,1.0]:
		detail(parent,Vector3(.09,hh+.14,.13),Vector3(x+sx*(ww/2+.035),bottom+hh/2,.18),trim)
		if shutters:detail(parent,Vector3(.23,hh+.09,.07),Vector3(x+sx*(ww/2+.19),bottom+hh/2,.16),dark)
	for sy in [bottom-.035,bottom+hh+.035]:detail(parent,Vector3(ww+.16,.09,.15),Vector3(x,sy,.18),trim)
	detail(parent,Vector3(.045,hh,.055),Vector3(x,bottom+hh/2,.16),dark)
	detail(parent,Vector3(ww,.045,.055),Vector3(x,bottom+hh*.52,.13),dark)
	detail(parent,Vector3(ww+.28,.10,.24),Vector3(x,bottom-.10,.18),trim)

func triangle(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,center:Vector3)->void:
	var normal:Vector3=(c-a).cross(b-a)
	if normal.length_squared()<.00000001:return
	if normal.dot((a+b+c)/3-center)<0:
		var swap:=b;b=c;c=swap;normal=-normal
	normal=normal.normalized()
	for v in [a,b,c]:st.set_normal(normal);st.set_uv(Vector2(v.x,v.z));st.add_vertex(v)

func prism(parent:Node3D,label:String,face:Array[Vector3],extrusion:Vector3,mat:Material)->void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center:=extrusion/2
	for v in face:center+=v/face.size()
	for i in range(1,face.size()-1):
		triangle(st,face[0],face[i],face[i+1],center)
		triangle(st,face[0]+extrusion,face[i]+extrusion,face[i+1]+extrusion,center)
	for i in range(face.size()):
		var a:Vector3=face[i];var b:Vector3=face[(i+1)%face.size()]
		triangle(st,a,b,b+extrusion,center);triangle(st,a,b+extrusion,a+extrusion,center)
	var body:=StaticBody3D.new();body.name=label;parent.add_child(body)
	var mesh:=MeshInstance3D.new();mesh.mesh=st.commit();mesh.material_override=mat;mesh.visibility_range_end=360;body.add_child(mesh)
	var col:=CollisionShape3D.new();col.shape=mesh.mesh.create_trimesh_shape();body.add_child(col)

func build_roof(parent:Node3D,w:float,d:float,h:float,style:Dictionary,color_index:int,wall:Material,trim:Material,workshop:bool)->void:
	var roof_kind:String=style.get("roof","gable")
	var roof_mat:=material("roof_"+str(color_index),ROOF_COLORS[color_index],"clay_tiles",1.3)
	if workshop:roof_mat=material("metal_roof_"+str(color_index),ROOF_COLORS[color_index].lightened(.08),"plaster",2.0)
	var rise:float=float(style.get("roof_rise",1.55));var y:float=h+.27
	var x0:float=-w/2+.06;var x1:float=w/2-.06;var z0:float=-d/2+.06;var z1:float=d/2-.06
	var roof_corners:Array[Vector3]=[Vector3(x0,y,z0),Vector3(x1,y,z0),Vector3(x1,y,z1),Vector3(x0,y,z1)]
	var a:=Vector3(0,y+rise,z0);var b:=Vector3(0,y+rise,z1)
	if roof_kind=="hip":a.z=-d*.2;b.z=d*.2
	prism(parent,"LeftPitch",[roof_corners[0],a,b,roof_corners[3]],Vector3.DOWN*.14,roof_mat)
	prism(parent,"RightPitch",[a,roof_corners[1],roof_corners[2],b],Vector3.DOWN*.14,roof_mat)
	if roof_kind=="hip":
		prism(parent,"BackHip",[roof_corners[0],roof_corners[1],a],Vector3.DOWN*.14,roof_mat)
		prism(parent,"FrontHip",[roof_corners[3],b,roof_corners[2]],Vector3.DOWN*.14,roof_mat)
	else:
		prism(parent,"BackGable",[roof_corners[0],roof_corners[1],a],Vector3(0,0,.16),wall)
		prism(parent,"FrontGable",[roof_corners[3],b,roof_corners[2]],Vector3(0,0,-.16),wall)
	var roof_trim:=category(parent,"FasciaAndRidge")
	detail(roof_trim,Vector3(.11,.18,d-.10),Vector3(x0,y-.04,0),trim)
	detail(roof_trim,Vector3(.11,.18,d-.10),Vector3(x1,y-.04,0),trim)
	var ridge_mesh:=CylinderMesh.new();ridge_mesh.top_radius=.13;ridge_mesh.bottom_radius=.13;ridge_mesh.height=.36;ridge_mesh.radial_segments=8
	var ridge:=MultiMeshInstance3D.new();ridge.name="RidgeTiles";ridge.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;ridge.multimesh=load(get_script().resource_path.get_base_dir()+"/BakedMultiMesh.gd").new();ridge.multimesh.transform_format=MultiMesh.TRANSFORM_3D;ridge.multimesh.mesh=ridge_mesh
	var count:int=maxi(1,int((b.z-a.z)/.33));ridge.multimesh.instance_count=count;ridge.material_override=roof_mat
	var saved:Array[Transform3D]=[]
	for i in range(count):saved.append(Transform3D(Basis(Vector3.RIGHT,PI/2),Vector3(0,y+rise+.04,lerpf(a.z+.16,b.z-.16,(i+.5)/count))))
	ridge.multimesh.source_transforms=saved
	ridge.visibility_range_end=260;parent.add_child(ridge)
	# One simple brick chimney breaks the silhouette; fully inside the roof footprint.
	if not workshop and bool(style.get("chimney",true)):
		var at:=Vector3(w*.24,y+rise*.72,-d*.2)
		part(parent,"Chimney",Vector3(.52,1.3,.56),at,material("chimney",Color("a67c60"),"brick",2.0))
		detail(roof_trim,Vector3(.64,.10,.68),at+Vector3.UP*.65,trim)

func plant(parent:Node3D,at:Vector3,palette:int)->void:
	var pot:=part(parent,"Planter",Vector3(.42,.40,.42),at+Vector3.UP*.2,material("terracotta",Color("a66a50"),"plaster"))
	var leaf_mat:=material("foliage",Color("4b7752"));var bloom:=material("bloom_"+str(palette%3),[Color("d69488"),Color("e3c875"),Color("abb7d6")][palette%3])
	for i in range(4):
		var mesh:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.16;sphere.height=.30;sphere.radial_segments=8;sphere.rings=4
		mesh.mesh=sphere;mesh.material_override=leaf_mat;mesh.position=Vector3(sin(i*2.4)*.13,.42+(i%2)*.12,cos(i*2.4)*.13);pot.add_child(mesh)
		detail(pot,Vector3(.12,.09,.12),mesh.position+Vector3.UP*.12,bloom)

func awning(parent:Node3D,w:float,front:float,h:float,dark:Material,color_index:int)->void:
	var stripes:=category(parent,"Awning")
	var count:=int(w/.30)
	var red:=material("awning_"+str(color_index),ROOF_COLORS[color_index].lightened(.18),"plaster")
	var cream:=material("awning_cream",Color("e4dac2"),"plaster")
	for i in range(count):detail(stripes,Vector3((w-.35)/count,.05,.63),Vector3(-w/2+.175+(i+.5)*(w-.35)/count,h-.53,front+.34),red if i%2 else cream,Vector3(.16,0,0))
	detail(stripes,Vector3(w-.32,.16,.06),Vector3(0,h-.65,front+.65),dark)

func furnish(parent:Node3D,w:float,back:float,front:float,door_width:float,h:float,workshop:bool,shop:bool,style:Dictionary)->void:
	var furniture:=category(parent,"Furniture")
	var wood:=material("furniture_wood",Color("957451"),"wood",1.0)
	var metal:=material("furniture_metal",Color("474f50"),"plaster")
	var side:float=-1 if int(style.get("furniture_side",0))%2 else 1
	var x:float=side*(w/2-.65)
	# A wall bench leaves the entire central measured route clear.
	part(furniture,"Worktop" if workshop else "Table",Vector3(.8,.12,1.4),Vector3(x,.84,back+1.05),wood)
	for z in [back+.55,back+1.55]:detail(furniture,Vector3(.10,.80,.10),Vector3(x,.40,z),metal)
	if shop:
		part(furniture,"Counter",Vector3(.75,1.0,1.35),Vector3(-x,.5,front-1.1),wood)
	if not workshop:
		plant(furniture,Vector3(-x,0,back+.65),int(style.get("palette",0)))
		var beams:=category(parent,"CeilingBeams")
		for z in [back+1.0,front-1.0]:detail(beams,Vector3(w-.5,.10,.13),Vector3(0,h-.05,z),wood)

func set_roof_visible(building:Node3D,show_roof:bool)->void:
	for child in building.get_node("Roof").find_children("*","GeometryInstance3D",true,false):child.visible=show_roof

func own_tree(node:Node,scene_root:Node)->void:
	for child in node.get_children():child.owner=scene_root;own_tree(child,scene_root)

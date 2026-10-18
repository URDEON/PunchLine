extends Node3D
## Four-layer vector reconstruction. Never asserts that missing source meshes were restored.
var colors := {"Roads":Color("8f9699"),"Parking":Color("9ba0a3"),"Lots":Color("a5b87c"),"Sidewalks":Color("9e9c92")}
var levels := {"Roads":0.0,"Parking":0.012,"Lots":0.026,"Sidewalks":0.16}

func point(v: Array,y: float) -> Vector3:
	return Vector3(v[0],y,v[1])
func triangle(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,up := false) -> void:
	if up and (c-a).cross(b-a).y<0:
		var swap:=b;b=c;c=swap
	var normal: Vector3=(c-a).cross(b-a).normalized()
	for v in [a,b,c]:
		st.set_normal(normal);st.set_uv(Vector2(v.x,v.z));st.add_vertex(v)
func build() -> void:
	name="District500"
	set_meta("source_notice","Reconstructed four supplied layers; original seven-layer District500.tscn was not supplied")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/vector_meshes.json"))
	var layers: Dictionary={}
	for label in ["Roads","Parking","Lots","Sidewalks","Curbs","RoadMarkings","ParkingMarkings"]:
		var node:=Node3D.new();node.name=label;add_child(node);layers[label]=node
		if label in data.missing_layers:node.set_meta("source_missing",true)
	var substrate:=MeshInstance3D.new();substrate.name="Substrate"
	var plane:=PlaneMesh.new();plane.size=Vector2(500,500);substrate.mesh=plane;substrate.position.y=-.125
	var soil:=StandardMaterial3D.new();soil.albedo_color=colors.Roads;soil.roughness=.95
	soil.albedo_texture=load(get_script().resource_path.get_base_dir().get_base_dir()+"/textures/asphalt.png");soil.uv1_scale=Vector3.ONE*150
	substrate.material_override=soil;add_child(substrate)
	var ground:=StaticBody3D.new();ground.name="SubstrateContact";add_child(ground)
	var ground_col:=CollisionShape3D.new();var ground_shape:=BoxShape3D.new();ground_shape.size=Vector3(500,.06,500);ground_col.shape=ground_shape;ground_col.position.y=-.155;ground.add_child(ground_col)
	for f in data.features:
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var y: float=levels[f.layer]
		for tri in f.triangles:
			triangle(st,point(tri[0],y),point(tri[1],y),point(tri[2],y),true)
		for ring in f.rings:
			for i in range(ring.size()-1):
				var a:=point(ring[i],y);var b:=point(ring[i+1],y);var c:=point(ring[i+1],-.1);var d:=point(ring[i],-.1)
				triangle(st,a,b,c);triangle(st,a,c,d)
		var mesh:=MeshInstance3D.new();mesh.name=f.label;mesh.mesh=st.commit()
		var mat:=StandardMaterial3D.new();mat.albedo_color=colors[f.layer];mat.roughness=.95
		var textures:Dictionary={"Roads":"asphalt","Parking":"asphalt","Lots":"grass","Sidewalks":"pavers"}
		var scales:Dictionary={"Roads":.30,"Parking":.30,"Lots":.45,"Sidewalks":.75}
		var base:String=get_script().resource_path.get_base_dir().get_base_dir()
		mat.albedo_texture=load(base+"/textures/"+textures[f.layer]+".png")
		mat.uv1_scale=Vector3.ONE*scales[f.layer];mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		mesh.material_override=mat
		layers[f.layer].add_child(mesh)
		var body:=StaticBody3D.new();body.name="SurfaceContact";mesh.add_child(body)
		var col:=CollisionShape3D.new();var shape:ConcavePolygonShape3D=mesh.mesh.create_trimesh_shape();shape.backface_collision=true;col.shape=shape;body.add_child(col)
		if f.repaired_mask:mesh.set_meta("derived_make_valid",true)

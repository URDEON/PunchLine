extends MeshInstance3D
## Bastidor 3D local de 72 triángulos, una superficie y ningún subviewport.
var camera: Camera3D
func _ready() -> void:
	camera = get_parent() as Camera3D
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	layers = 1 << 18
	var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for data in [[Vector3(-.96,0,0),Vector3(.095,2.05,.12),-.045],[Vector3(.96,0,0),Vector3(.095,2.05,.12),.045],[Vector3(0,1.02,0),Vector3(2.05,.09,.15),0.0],[Vector3(0,-1.03,0),Vector3(2.05,.12,.15),0.0],[Vector3(-.82,.88,.04),Vector3(.4,.065,.18),-.35],[Vector3(.82,.88,.04),Vector3(.4,.065,.18),.35]]:
		var box := BoxMesh.new(); box.size = data[1]
		surface.append_from(box,0,Transform3D(Basis(Vector3.BACK,data[2]),data[0]))
	mesh = surface.commit()
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded; varying vec3 n; void vertex(){n=NORMAL;} void fragment(){float key=clamp(dot(normalize(n),normalize(vec3(-.4,.7,1.))),0.,1.); ALBEDO=mix(vec3(.025,.04,.045),vec3(.20,.27,.28),key); ROUGHNESS=.4;}"
	var material := ShaderMaterial.new(); material.shader = shader; material_override = material
func _process(_delta: float) -> void:
	if not visible or camera == null: return
	var extent := camera.get_viewport().get_visible_rect().size
	var aspect := extent.x/maxf(1,extent.y)
	var height := tan(deg_to_rad(camera.fov)*.5)*.6
	scale = Vector3(height*aspect,height,.20); position = Vector3(0,0,-.6)

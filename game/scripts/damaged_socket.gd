extends Node3D
## Tapón de la unión, cables de geometría estática y un emisor pequeño.
func _ready()->void:
 var material:=StandardMaterial3D.new();material.albedo_color=Color("263238");material.metallic=.65;material.roughness=.6
 var cap:=MeshInstance3D.new();var disk:=CylinderMesh.new();disk.top_radius=.18;disk.bottom_radius=.18;disk.height=.04;disk.radial_segments=12;cap.mesh=disk;cap.material_override=material;add_child(cap)
 var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for cable in range(4):
  var points:Array[Vector3]=[]
  for step in range(5):points.append(Vector3((cable-1.5)*.04+sin(float(step+cable))*.012,-.025-float(step)*.035,(cable%2)*.035+float(step)*.018))
  for segment in range(4):
   var axis:Vector3=(points[segment+1]-points[segment]).normalized();var right:=axis.cross(Vector3.FORWARD).normalized()*.005;var front:=right.normalized().cross(axis)*.005
   for face in range(4):
    var a:=TAU*face/4;var b:=TAU*(face+1)/4
    var p:=points[segment]+right*cos(a)+front*sin(a);var q:=points[segment]+right*cos(b)+front*sin(b)
    var v:=points[segment+1]+right*cos(a)+front*sin(a);var w:=points[segment+1]+right*cos(b)+front*sin(b)
    for vertex in [p,v,q,q,v,w]:surface.add_vertex(vertex)
 surface.generate_normals();var cable_mesh:=MeshInstance3D.new();cable_mesh.mesh=surface.commit();cable_mesh.material_override=material;add_child(cable_mesh)
 # Compatibility: emplear el mismo emisor CPU que los efectos visibles del juego.
 # Solo seis partículas por socket; al quitar el socket se libera su emisor.
 var sparks:=CPUParticles3D.new();sparks.name="LiveSparks";sparks.amount=14;sparks.lifetime=.45;sparks.explosiveness=.35;sparks.position=Vector3(0,-.07,.20)
 sparks.local_coords=false;sparks.randomness=.75
 sparks.direction=Vector3.DOWN;sparks.spread=75;sparks.initial_velocity_min=.8;sparks.initial_velocity_max=2.1;sparks.gravity=Vector3(0,-3.5,0)
 sparks.scale_amount_min=.38;sparks.scale_amount_max=.95;sparks.color=Color(1,.65,.2,1)
 var ramp:=Gradient.new();ramp.set_color(0,Color(1,.95,.7,1));ramp.set_color(1,Color(1,.4,.05,0));sparks.color_ramp=ramp
 var point:=SphereMesh.new();point.radius=.016;point.height=.032;point.radial_segments=4;point.rings=2
 var glow:=StandardMaterial3D.new();glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;glow.albedo_color=Color("ffb43e");glow.emission_enabled=true;glow.emission=Color("ff9f2f");glow.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glow.vertex_color_use_as_albedo=true;point.material=glow
 sparks.mesh=point;add_child(sparks);sparks.emitting=true
func set_paused(value:bool)->void:
 var sparks:CPUParticles3D=get_node_or_null("LiveSparks")
 if sparks!=null:sparks.speed_scale=0 if value else 1

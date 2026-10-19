extends Node3D
var elapsed:=0.0
var sphere:MeshInstance3D
var wave:MeshInstance3D
var light:OmniLight3D
var radius:=23.0
func _ready()->void:
 physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
 var fire:=StandardMaterial3D.new();fire.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;fire.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;fire.albedo_color=Color(1,.53,.12,.9);fire.emission_enabled=true;fire.emission=Color(1,.3,.04);fire.emission_energy_multiplier=5
 sphere=MeshInstance3D.new();var ball:=SphereMesh.new();ball.radius=1;ball.height=2;ball.radial_segments=32;ball.rings=16;sphere.mesh=ball;sphere.material_override=fire;sphere.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(sphere)
 wave=MeshInstance3D.new();var ring:=TorusMesh.new();ring.inner_radius=.94;ring.outer_radius=1;ring.rings=48;ring.ring_segments=8;wave.mesh=ring;wave.material_override=fire.duplicate();wave.position.y=-global_position.y+.12;wave.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(wave)
 light=OmniLight3D.new();light.light_color=Color("ffb369");light.omni_range=radius*1.5;light.light_energy=10;add_child(light)
func _process(delta:float)->void:
 elapsed+=delta
 var t:float=clampf(elapsed/1.3,0,1);sphere.scale=Vector3.ONE*maxf(.02,sin(t*PI*.65)*radius*.42)
 sphere.material_override.albedo_color.a=(1-t)*.8;sphere.visible=t<1
 var reach:float=minf(radius,elapsed*21);wave.scale=Vector3(maxf(.01,reach),.45,maxf(.01,reach));wave.material_override.albedo_color.a=maxf(0,1-elapsed/1.6)
 light.light_energy=maxf(0,10-elapsed*12)
 if elapsed>2.4:queue_free()

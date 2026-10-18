extends SubViewportContainer
## Dispositivo 3D de ajustes; sus piezas muestran los valores reales guardados.
var preferences:Node
var category:="video"
var viewport:SubViewport
var rig:Node3D
var camera:Camera3D
var rings:Array[Node3D]=[]
var meters:Array[Node3D]=[]
var keys:Array[Label3D]=[]
var panels:Array[Node3D]=[]
var timer:=0.0
var clock:=0.0
func make_material(color:Color)->StandardMaterial3D:
 var result:=StandardMaterial3D.new();result.albedo_color=color;result.metallic=.7;result.roughness=.32;return result
func block(at:Vector3,extent:Vector3,color:Color)->MeshInstance3D:
 var node:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=extent;node.mesh=mesh;node.material_override=make_material(color);rig.add_child(node);node.position=at;return node
func _ready()->void:
 stretch=true;mouse_filter=Control.MOUSE_FILTER_IGNORE
 viewport=SubViewport.new();viewport.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.size=Vector2i(640,200);viewport.gui_disable_input=true;add_child(viewport)
 rig=Node3D.new();viewport.add_child(rig)
 block(Vector3(0,-.45,0),Vector3(4.6,.12,1.5),Color("1d303a"))
 for i in range(3):
  var ring:=MeshInstance3D.new();var mesh:=TorusMesh.new();mesh.inner_radius=.42+float(i)*.09;mesh.outer_radius=mesh.inner_radius+.035;mesh.rings=24;mesh.ring_segments=8
  ring.mesh=mesh;ring.material_override=make_material(Color("56d6db") if i!=1 else Color("c3a978"));rig.add_child(ring);ring.position=Vector3(-1.25,.28,0);ring.rotation.x=PI/2;ring.rotation.z=.25*i;rings.append(ring)
 for i in range(12):meters.append(block(Vector3(.1+i*.14,-.25,0),Vector3(.075,.5,.1),Color("5be6cb")))
 for i in range(4):
  block(Vector3(.1+i*.48,-.24,.38),Vector3(.38,.15,.4),Color("34576b"))
  var text:=Label3D.new();text.font_size=50;text.pixel_size=.004;text.billboard=BaseMaterial3D.BILLBOARD_ENABLED;text.position=Vector3(.1+i*.48,-.1,.5);rig.add_child(text);keys.append(text)
 for i in range(3):
  var panel:=block(Vector3(.6+float(i)*.4,.45,-float(i)*.28),Vector3(.9,.5,.055),Color("334f63"));panel.rotation.y=-.35;panels.append(panel)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-30,0);light.light_energy=1.8;viewport.add_child(light)
 var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_CLEAR_COLOR;environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("517387");environment.environment.ambient_light_energy=.8;viewport.add_child(environment)
 camera=Camera3D.new();viewport.add_child(camera);camera.position=Vector3(1.4,1.1,5);camera.fov=40;camera.look_at(Vector3(0,.05,0));camera.current=true
func _process(delta:float)->void:
 if viewport==null:return
 if not is_visible_in_tree():viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;return
 timer+=delta;clock+=delta*float(preferences.values.ui_motion)
 if timer<.05:return
 timer=0;viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
 var cursor:=get_local_mouse_position()/size.max(Vector2.ONE)-Vector2(.5,.5)
 rig.rotation=Vector3(.02+cursor.y*.07,-.10-cursor.x*.12,0)
 for i in range(rings.size()):
  rings[i].visible=category in ["video","camera"];rings[i].rotation.z=clock*(.15+float(i)*.07)+float(preferences.values.fov)*.01
  rings[i].scale=Vector3.ONE*(1+float(preferences.values.body_lens)*float(i)*.15)
 for i in range(meters.size()):
  meters[i].visible=category=="audio";meters[i].scale.y=.12+float(preferences.values.master)*(.4+.6*absf(sin(float(i)*.8+clock)))
 for i in range(keys.size()):
  keys[i].visible=category=="controls";keys[i].text=preferences.key_name(["forward","dash","lock","emote"][i])
 for i in range(panels.size()):
  panels[i].visible=category=="interface";panels[i].position.y=.25+sin(clock+float(i))*.035;panels[i].scale=Vector3.ONE*float(preferences.values.hud_scale)

extends Node
## Camera-local IR light and an isolated target pass; no replicated material mutation.
const HEAT_LAYER:=1<<18
const LABELS:=["NORMAL","VISIÓN NOCTURNA","TÉRMICA","RAYOS X"]
var host:Node3D
var camera:Camera3D
var layer:CanvasLayer
var screen:ColorRect
var viewport:SubViewport
var heat_camera:Camera3D
var infrared:SpotLight3D
var warm:ShaderMaterial
var cold:ShaderMaterial
var copies:Array=[]
var mode:=-1
var timer:=0.0
var roots:Array=[]
var source_signature:=""
func setup(game:Node3D,view:Camera3D)->void:
 host=game;camera=view
 layer=CanvasLayer.new();layer.layer=1;camera.add_child(layer)
 screen=ColorRect.new();screen.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(screen)
 screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shader:=ShaderMaterial.new();shader.shader=preload("res://shaders/spider_vision.gdshader");screen.material=shader
 viewport=SubViewport.new();viewport.name="VisionTargets";viewport.transparent_bg=true
 viewport.world_3d=game.get_world_3d();viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
 viewport.msaa_3d=Viewport.MSAA_DISABLED;viewport.positional_shadow_atlas_size=0;add_child(viewport)
 heat_camera=Camera3D.new();heat_camera.cull_mask=HEAT_LAYER;heat_camera.current=true;heat_camera.far=42
 heat_camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
 var environment:=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color(0,0,0,0)
 heat_camera.environment=environment;viewport.add_child(heat_camera)
 shader.set_shader_parameter("heat_image",viewport.get_texture())
 infrared=SpotLight3D.new();infrared.name="LocalInfrared";infrared.spot_range=22;infrared.spot_angle=85
 infrared.light_energy=2.4;infrared.light_color=Color("c2d0c0");infrared.shadow_enabled=false;infrared.visible=false
 camera.add_child(infrared)
 warm=ShaderMaterial.new();warm.shader=preload("res://shaders/spider_heat.gdshader");warm.set_shader_parameter("temperature",1.0)
 cold=warm.duplicate();cold.set_shader_parameter("temperature",.25)
 camera.cull_mask &= ~HEAT_LAYER
 set_process(false);layer.hide()
func gather()->void:
 var actors:Array=[]
 if "session" in host:
  for actor in host.session.actors.values():
   if actor==host or actor.hp<=0:continue
   var visual:Node3D=actor.fusion.spider.rig if actor.fusion.spider.active() else (actor.fusion.visual() if actor.fusion.fused else actor.rig_holder)
   actors.append({"body":actor.player,"visual":visual,"warm":true,"spider":actor.fusion.spider if actor.fusion.spider.active() else null})
   if actor.fusion.spider.active():actors.append({"body":actor.fusion.spider.parked,"visual":actor.fusion.sequence._fusion_root,"warm":false})
 else:
  for enemy in host.enemies:
   if enemy.get("hp",0)>0:actors.append({"body":enemy.body,"visual":enemy.body,"warm":true})
 if is_instance_valid(host.fusion.sequence):actors.append({"body":host.fusion.spider.parked,"visual":host.fusion.sequence._fusion_root,"warm":false})
 var sources:Array=[];var signature:="";var next_roots:Array=[]
 for actor in actors:
  if not is_instance_valid(actor.visual) or not is_instance_valid(actor.body):continue
  var index:int=next_roots.size();next_roots.append(actor)
  signature+=str(actor.body.get_instance_id())+str(actor.warm)
  for source in actor.visual.find_children("*","MeshInstance3D",true,false):
   if not source.is_visible_in_tree() or source.mesh==null:continue
   signature+=":"+str(source.get_instance_id())
   sources.append({"source":source,"actor":index,"warm":actor.warm})
 if signature==source_signature:return
 source_signature=signature
 for entry in copies:
  if is_instance_valid(entry.copy):entry.copy.queue_free()
 copies.clear();roots=next_roots
 for entry in sources:
  var source:MeshInstance3D=entry.source
  var copy:=MeshInstance3D.new();copy.name="VisionTarget";copy.mesh=source.mesh;copy.skin=source.skin
  copy.layers=HEAT_LAYER;copy.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  copy.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
  copy.material_override=warm if entry.warm else cold;add_child(copy)
  if source.skin!=null and not source.skeleton.is_empty():
   var bones:Node=source.get_node_or_null(source.skeleton)
   if bones!=null:copy.skeleton=copy.get_path_to(bones)
  copies.append({"source":source,"copy":copy,"actor":entry.actor})
func set_mode(value:int)->void:
 if mode==value:return
 mode=clampi(value,0,3);screen.material.set_shader_parameter("mode",mode)
 layer.visible=mode>0;infrared.visible=mode==1
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS if mode>=2 else SubViewport.UPDATE_DISABLED
 warm.set_shader_parameter("vision_mode",mode);cold.set_shader_parameter("vision_mode",mode)
 if mode>=2:gather()
 else:
  for entry in copies:
   if is_instance_valid(entry.copy):entry.copy.queue_free()
  copies.clear();roots.clear();source_signature=""
 timer=.5
func update(value:int,delta:float)->void:
 set_mode(value)
 if mode<2:return
 timer-=delta
 if timer<=0:gather();timer=.5
 var size:Vector2=host.get_viewport().get_visible_rect().size
 var scale_value:float=[.5,.65,.85][clampi(int(host.preferences.values.get("graphics_preset",1)),0,2)]
 viewport.size=Vector2i(maxi(160,int(size.x*scale_value)),maxi(100,int(size.y*scale_value)))
 heat_camera.global_transform=camera.global_transform;heat_camera.fov=camera.fov;heat_camera.near=camera.near
 var visible:Array[bool]=[]
 for actor in roots:
  if not is_instance_valid(actor.body):visible.append(false);continue
  var point:Vector3=target_point(actor)
  var shown:bool=camera.global_position.distance_to(point)<=40
  if shown and mode==2:
   var ray:=PhysicsRayQueryParameters3D.create(camera.global_position,point,1)
   var excluded:Array[RID]=[host.player.get_rid()]
   if actor.body is CollisionObject3D:excluded.append(actor.body.get_rid())
   ray.exclude=excluded
   shown=host.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
  visible.append(shown)
 for entry in copies:
  if not is_instance_valid(entry.source) or not is_instance_valid(entry.copy):continue
  entry.copy.visible=visible[entry.actor] and entry.source.is_visible_in_tree()
  entry.copy.global_transform=entry.source.get_global_transform_interpolated()
func target_point(actor:Dictionary)->Vector3:
 var spider:Node=actor.get("spider")
 var offset:Vector3=spider.normal*.35 if is_instance_valid(spider) else Vector3.UP*(1.0 if actor.warm else 1.5)
 return actor.body.global_position+offset
func release()->void:
 for entry in copies:
  if is_instance_valid(entry.copy):entry.copy.queue_free()
 copies.clear();roots.clear()
 if is_instance_valid(layer):layer.queue_free()
 if is_instance_valid(infrared):infrared.queue_free()
 if is_instance_valid(viewport):viewport.queue_free()
func _exit_tree()->void:release()

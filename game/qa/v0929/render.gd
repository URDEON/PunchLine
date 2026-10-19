extends SceneTree
var game:Node3D
const OUTPUT='res://housing/docs/evidence/update_v0929/'
func _initialize():run.call_deferred()
func frames(n:int):
 for i in range(n):await physics_frame
func capture(label:String):
 RenderingServer.set_render_loop_enabled(true)
 for i in range(5):await process_frame;await RenderingServer.frame_post_draw
 var result:Error=root.get_texture().get_image().save_png(OUTPUT+label+'.png')
 if result!=OK:push_error('Screenshot write failed');quit(1)
 print('CAPTURE ',label)
 RenderingServer.set_render_loop_enabled(false)
func run():
 if DisplayServer.get_name()=='headless':push_error('Forward+ Vulkan required');quit(1);return
 RenderingServer.set_render_loop_enabled(false)
 Engine.set_meta('punchline_world',load('res://scripts/world_config.gd').DEFAULTS.duplicate())
 game=load('res://main.tscn').instantiate();root.add_child(game)
 await process_frame;await capture('loading_seed')
 var captured:=false
 while game.loading:
  await process_frame
  if not captured:
   for node in game.get_children():
    if node is CanvasLayer and 'progress' in node and node.progress.value>30 and node.progress.value<90:
     captured=true;await capture('loading_construction')
 await frames(25)
 for enemy in game.enemies:game.set_dummy_mode(enemy,0)
 game.set_process(false);game.camera_view.restore();game.preferences.set_preset(1);game.preferences.set_value('fog_enabled',false)
 game.camera.global_position=Vector3(-110,9,-40);game.camera.look_at(Vector3(-40,12,-100))
 await capture('district_clouds_no_fog')
 var a:Node3D=game.arena.punchline.ambience
 var prop:Dictionary=a.decorations.placements[0];var origin:=Vector3(prop.point.x,0,prop.point.y)
 game.camera.global_position=origin+Vector3(4,1.8,6);game.camera.look_at(origin+Vector3.UP*.6)
 await capture('tall_grass_park_details')
 var plan:Dictionary=load('res://scripts/world_config.gd').make_plan(load('res://scripts/world_config.gd').DEFAULTS)
 var selected:Dictionary={}
 for b in plan.buildings:
  if b.access=='human_only':selected=b;break
 var house:Node3D=game.arena.punchline.housing.get_node('GeneratedBuildings/'+selected.lot+'/'+selected.id)
 game.camera.global_position=house.to_global(Vector3(selected.width/2-1.4,1.6,selected.depth/2-1.4));game.camera.look_at(house.to_global(Vector3(-1.4,1.0,selected.depth/2-2.5)))
 await capture('furnished_house_interior')
 game.camera.global_position=house.to_global(Vector3(0,2.0,selected.depth/2+5));game.camera.look_at(house.to_global(Vector3(0,1.5,selected.depth/2-.3)))
 await capture('human_scale_door')
 var d:Node3D=game.arena.punchline.destruction;var p:Dictionary={}
 for value in d.parts.values():
  if value.building==selected.lot+'/'+selected.id and value.category=='Walls' and value.size.y>2.5 and value.size.x>2.2:p=value;break
 var normal:Vector3=p.pose.basis[p.size.min_axis_index()].normalized()
 var point:Vector3=p.box.get_center()
 game.camera.global_position=point+normal*5+Vector3.UP*.8;game.camera.look_at(point)
 d.damage_area(point,.65,15,normal);await frames(2)
 for key in d.fractures:
  for id in d.fractures[key]:
   var cell:Dictionary=d.parts[id]
   if not cell.broken and not cell.batch.multimesh.get_instance_transform(cell.index).is_equal_approx(cell.transform):push_error('Native fracture transform was not uploaded');quit(1);return
 await capture('wall_stress_cracks')
 d.damage_area(point,1.1,120,normal);await frames(15);await capture('wall_local_fracture_rubble')
 var bearing:Array=[]
 for key in d.buildings[p.building].parts.duplicate():
  var value:Dictionary=d.parts[key]
  if int(value.get('bearing_level',-1))==0:
   if d.can_fracture(value):bearing.append_array(d.fracture(key))
   else:bearing.append(key)
 for key in bearing:
  var value:Dictionary=d.parts[key]
  if not value.broken and int(value.get('bearing_level',-1))==0:d.damage_area(value.box.get_center(),.08,160,normal)
 await frames(16);await capture('structural_roof_collapse')
 game.respawn_player();await frames(20);game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
 game.fusion.request();game.fusion.sequence.advance(11.5);await frames(40)
 var spider:Node3D=game.fusion.spider
 spider.eject();await frames(150)
 Input.action_press('forward');await frames(22);Input.action_release('forward')
 game.camera.global_position=game.player.global_position+Vector3(1.5,1.1,1.7);game.camera.look_at(game.player.global_position+Vector3.UP*.37)
 await capture('spider_updated_stride')
 game.player.global_position=spider.mecha_origin+Vector3(0,.035,2.2);game.player.velocity=Vector3.ZERO;spider.normal=Vector3.UP;spider.forward=Vector3.FORWARD;spider.view_forward=spider.forward
 if not spider.request_return():push_error('Native reattachment failed');quit(1);return
 await frames(70)
 game.hp=60;game.self_destruct.arm();await frames(65)
 var blast_origin:Vector3=game.player.global_position
 game.camera.global_position=blast_origin+Vector3(7,3.5,8);game.camera.look_at(blast_origin+Vector3.UP*1.2)
 await capture('critical_shutdown_alarm')
 game.self_destruct.remaining=.02;await frames(2);game.set_physics_process(false)
 for i in range(18):await process_frame
 game.camera.global_position=blast_origin+Vector3(18,9,21);game.camera.look_at(blast_origin+Vector3.UP*1.5)
 await capture('critical_explosion_shockwave')
 print('RESULT native Forward+ loading, scenery, fracture and shutdown captured')
 game.queue_free();await frames(10);quit()

extends SceneTree
var game:Node3D
var last_image:Image
const OUTPUT='res://housing/docs/evidence/update_v0928/'
func _initialize():run.call_deferred()
func frames(n:int):
 for i in range(n):await physics_frame
func capture(label:String):
 RenderingServer.set_render_loop_enabled(true)
 for i in range(5):await process_frame;await RenderingServer.frame_post_draw
 last_image=root.get_texture().get_image()
 if last_image.save_png(OUTPUT+label+'.png')!=OK:quit(1)
 print('CAPTURE ',label)
 RenderingServer.set_render_loop_enabled(false)
func hot_pixels()->int:
 var count:=0
 for y in range(int(last_image.get_height()*.35),int(last_image.get_height()*.75),2):
  for x in range(int(last_image.get_width()*.40),int(last_image.get_width()*.60),2):
   var color:Color=last_image.get_pixel(x,y)
   if color.r>.65 and color.g>.22 and color.b<.3:count+=1
 return count
func run():
 if DisplayServer.get_name()=='headless':push_error('Native renderer required');quit(1);return
 RenderingServer.set_render_loop_enabled(false)
 Engine.set_meta('punchline_world',load('res://scripts/world_config.gd').DEFAULTS.duplicate())
 game=load('res://main.tscn').instantiate();root.add_child(game);await frames(30)
 for enemy in game.enemies:game.set_dummy_mode(enemy,0)
 game.preferences.set_preset(1);game.set_process(false);game.camera_view.restore()
 game.camera.position=Vector3(-70,16,-32);game.camera.look_at(Vector3(-45,0,-65))
 await capture('district_trees_grass_day')
 var trees:Node3D=game.arena.punchline.ambience.trees
 var tree:Dictionary=trees.trees[0]
 var tree_origin:=Vector3(tree.point.x,0,tree.point.y)
 game.camera.global_position=tree_origin+Vector3(6,2.5,7);game.camera.look_at(tree_origin+Vector3.UP*2.4)
 await capture('vegetation_close')
 var ambience:Node3D=game.arena.punchline.ambience
 ambience.configure_environment(ambience.environment,true);await capture('vegetation_night')
 ambience.configure_environment(ambience.environment,false)
 game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
 if not game.fusion.request():push_error('Fusion failed');quit(1);return
 game.fusion.sequence.advance(11.5);await frames(40)
 var spider:Node3D=game.fusion.spider
 if not spider.eject():push_error('Ejection failed');quit(1);return
 await frames(150)
 game.set_physics_process(false);game.camera_view.restore()
 game.camera.global_position=game.player.global_position+Vector3(1.5,1.05,1.8);game.camera.look_at(game.player.global_position+Vector3.UP*.36)
 await capture('spider_reference_scale')
 Input.action_press('forward');game.set_physics_process(true);await frames(9);game.set_physics_process(false);Input.action_release('forward')
 game.camera.global_position=game.player.global_position+Vector3(1.5,1.05,1.8);game.camera.look_at(game.player.global_position+Vector3.UP*.36)
 await capture('spider_walking_rigid_armour')
 game.zoom=0;game.pitch=-.1;spider.camera_update(game.camera,1.0/60)
 await capture('spider_first_person')
 var enemy:Dictionary=game.enemies[0];enemy.body.global_position=game.player.global_position+spider.forward*6
 for i in range(6):await process_frame
 game.camera.look_at(enemy.body.global_position+Vector3.UP*.9)
 var view:Node=spider.vision
 view.update(0,1.0/60);await capture('vision_normal')
 spider.vision_mode=1;game.interface.tick(0);view.update(1,1.0/60);await capture('vision_night')
 spider.vision_mode=2;game.interface.tick(0);view.update(2,1.0/60);await capture('vision_thermal_visible')
 var warm_visible:int=hot_pixels()
 var factory:Node3D=game.arena.punchline.housing
 var wall:StaticBody3D=factory.part(game,'VisionOccluder',Vector3(4,3,.24),game.player.global_position+spider.forward*3+Vector3.UP*1.3,factory.material('vision_wall',Color('b1b4aa'),'plaster',1))
 wall.rotation.y=atan2(spider.forward.x,spider.forward.z)
 await frames(3);view.gather();view.update(2,1.0/60)
 await capture('vision_thermal_occluded')
 var warm_hidden:int=hot_pixels()
 if warm_visible<80 or warm_hidden>4:push_error('Thermal pixels do not respect actual occluder');quit(1);return
 print('THERMAL_PIXELS visible=',warm_visible,' occluded=',warm_hidden)
 spider.vision_mode=3;game.interface.tick(0);view.update(3,1.0/60);await capture('vision_xray_occluded')
 var cyan:=0
 for y in range(int(last_image.get_height()*.35),int(last_image.get_height()*.75),2):
  for x in range(int(last_image.get_width()*.4),int(last_image.get_width()*.6),2):
   var color:Color=last_image.get_pixel(x,y)
   if color.g>.4 and color.b>.4:cyan+=1
 if cyan<100:push_error('X-ray failed to reveal occluded target pixels');quit(1);return
 print('XRAY_PIXELS occluded_target=',cyan)
 var visible:=0
 for copy in view.copies:
  if copy.copy.visible:visible+=1
 if visible==0:push_error('X-ray has no real target geometry');quit(1);return
 spider.vision_mode=0;game.interface.tick(0);view.update(0,1.0/60);wall.queue_free();game.camera_view.restore();await frames(2)
 var plan:Dictionary=load('res://scripts/world_config.gd').make_plan(load('res://scripts/world_config.gd').DEFAULTS)
 var b:Dictionary={}
 for item in plan.buildings:
  if item.archetype=='courtyard_home':b=item;break
 var house:Node3D=factory.get_node('GeneratedBuildings/'+b.lot+'/'+b.id)
 game.camera.global_position=house.to_global(Vector3(13,9,-18));game.camera.look_at(house.to_global(Vector3(0,1,-3)))
 await capture('seeded_house_and_yard')
 var d:Node3D=game.arena.punchline.destruction;var id:String=b.lot+'/'+b.id
 game.camera.global_position=house.to_global(Vector3(12,6,18));game.camera.look_at(house.to_global(Vector3(0,1.8,b.depth/2)))
 await capture('house_before_damage')
 d.damage_area(house.to_global(Vector3(0,1.8,b.depth/2)),2.2,90,-house.global_basis.z);await frames(2)
 await capture('destructible_wall_opening')
 for key in d.buildings[id].parts:
  var part:Dictionary=d.parts[key]
  if not part.broken:d.damage_area(part.box.get_center(),.1,1000,Vector3.UP);break
 await frames(10);await capture('collapsed_building')
 print('RENDER_RESULT native Forward+; rigid reference mesh; 4 camera modes; masked owner; tree/grass lighting; destruction')
 game.queue_free();await frames(8);quit()

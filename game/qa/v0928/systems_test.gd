extends SceneTree
var game:Node3D
var checks:=0
var failures:=0
func _initialize():run.call_deferred()
func frames(n:int):
 for i in range(n):await physics_frame
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print('PASS ' if ok else 'FAIL ',label)
func run():
 var config=load('res://scripts/world_config.gd');Engine.set_meta('punchline_world',config.DEFAULTS.duplicate())
 game=load('res://main.tscn').instantiate();root.add_child(game);await frames(30)
 for enemy in game.enemies:game.set_dummy_mode(enemy,0)
 var map:Node3D=game.arena.punchline;var d:Node3D=map.destruction;var ambience:Node3D=map.ambience
 check(d.parts.size()>5000 and d.buildings.size()==87,'runtime district registers destructible parts for all 87 seeded buildings')
 check(ambience.trees.trees.size()>100,'seeded district has physical trees in green lots')
 var tree_count:int=ambience.trees.trees.size();var points:Array=[]
 for tree in ambience.trees.trees:
  points.append([tree.point.x,tree.point.y,tree.height,tree.radius])
  check(not ambience.placement.blocked(tree.point,3.1),'tree '+str(points.size())+' clears buildings and protected access')
 var file:=FileAccess.open('/tmp/punchline-trees-v0928.json',FileAccess.WRITE);file.store_string(JSON.stringify(points));file.close()
 var grass_points:Array=[]
 for cell in ambience.placement.chunks:
  for point in ambience.placement.chunks[cell]:grass_points.append([point.x,point.y])
 var grass_file:=FileAccess.open('/tmp/punchline-greenery-v0928.json',FileAccess.WRITE)
 grass_file.store_string(JSON.stringify({"seed":"923","points":grass_points,"plan":config.make_plan(config.DEFAULTS)}));grass_file.close()
 var tree_bodies:int=ambience.find_children('*','StaticBody3D',true,false).size()
 for preset in range(3):
  game.preferences.set_preset(preset)
  check(ambience.find_children('*','StaticBody3D',true,false).size()==tree_bodies and ambience.trees.trees.size()==tree_count,'preset '+str(preset)+' preserves authoritative tree collision')
  check(game.preferences.values.grass_quality==preset+1 and ambience.environment.ssao_enabled==(preset>0),'preset '+str(preset)+' applies grass density and ambient occlusion')
 game.preferences.set_preset(1)
 var wall_key:=''
 for key in d.parts:
  var p:Dictionary=d.parts[key]
  if '/Walls/' in str(p.body.get_path()) and p.box.size.y>1.5:wall_key=key;break
 var wall:Dictionary=d.parts[wall_key];var centre:Vector3=wall.box.get_center();var original:Transform3D=wall.transform
 var packet:Dictionary=d.damage_area(centre,.16,40,Vector3.RIGHT);await frames(2)
 check(not packet.is_empty() and wall.broken and wall.collision.disabled and wall.body.collision_layer==0,'mecha-scale damage removes actual masonry collision')
 check(wall.batch.multimesh.source_transform(wall.index).basis.determinant()==0,'damage removes the matching batched wall geometry')
 var revision:int=d.revision;d.apply_packet(packet,true);check(d.revision==revision,'duplicate damage packets are idempotent')
 var state:Dictionary=d.state();check(state.damaged.has(wall_key) and float(state.damaged[wall_key])==0,'late-join state carries removed wall health')
 var building:Dictionary=d.buildings[wall.building]
 check(d.removed_details.size()>0,'broken opening removes nearby decorative trim')
 for key in building.parts:
  var p:Dictionary=d.parts[key]
  if not p.broken:d.damage_area(p.box.get_center(),.08,600,Vector3.RIGHT);break
 await frames(2)
 check(d.collapsed.has(wall.building) and not building.node.visible,'heavy structural damage collapses the whole building')
 var all_disabled:=true
 for shape in building.node.find_children("*","CollisionShape3D",true,false):all_disabled=all_disabled and shape.disabled
 check(all_disabled and d.debris.size()<=32,'collapsed building disables every collider including pitched roofs and bounds visual rubble')
 d.reset_world();await frames(2)
 check(d.revision==0 and d.collapsed.is_empty() and not wall.collision.disabled and wall.body.collision_layer==wall.layer and wall.batch.multimesh.source_transform(wall.index)==original,'new-world reset restores original geometry and collision')
 d.enabled=false;check(d.damage_area(centre,5,1000,Vector3.RIGHT).is_empty() and not wall.broken,'world destructibility option disables gameplay damage');d.enabled=true
 for event in ['mecha_step_0','mecha_step_1','mecha_step_2','mecha_armor','mecha_crash','mecha_servo_1','mecha_servo_2','mecha_servo_3']:
  game.feedback.sound(event,game.player.global_position)
  check(game.feedback.audio_events[-1].stream.begins_with('res://assets/audio/mecha_v0928/'),'provided recording plays for '+event)
 game.robots.forced=1;game.robots.select(1);await frames(35);game.charge=100
 check(game.fusion.request(),'actual fusion starts before vision checks');game.fusion.sequence.advance(11.5);await frames(40)
 var spider:Node3D=game.fusion.spider;check(spider.eject(),'actual head ejects');await frames(150)
 var target_size:Vector3=spider.rig.head_bounds.size
 check(target_size.x<=.621 and target_size.y<=.62 and target_size.z<=.778,'rigid original Rustcrawler core fits measured installed head')
 var core_transform:Transform3D=spider.rig.mesh.transform
 for i in range(6):spider.rig.solve_leg(i,spider.rig.feet_rest[i]+Vector3(.3,.1,0))
 check(spider.rig.mesh.transform==core_transform and spider.rig.max_reach_error<.00001,'bounded IK preserves central armour and rigid segment lengths')
 game.zoom=0;spider.camera_update(game.camera,1.0/60)
 var masks:=true
 for render in spider.rig.render_meshes:masks=masks and (render.layers & game.camera.cull_mask)==0
 check(masks,'first person excludes all thirteen rigid owner sections')
 for mode in range(1,4):
  spider.cycle_vision();spider.camera_update(game.camera,1.0/60)
  check(spider.vision_mode==mode and spider.vision.mode==mode and spider.vision.layer.visible,'T cycles camera into '+spider.vision.LABELS[mode])
 check(spider.vision.copies.size()>0 and spider.vision.heat_camera.cull_mask==spider.vision.HEAT_LAYER,'thermal and X-ray use actual isolated actor geometry')
 spider.cycle_vision();spider.camera_update(game.camera,1.0/60)
 check(spider.vision_mode==0 and not spider.vision.layer.visible and not spider.vision.infrared.visible,'normal camera restores after cycling all modes')
 print('SYSTEM_STATS buildings=',d.buildings.size(),' parts=',d.parts.size(),' trees=',tree_count,' grass=',ambience.placement.count)
 print('RESULT ',checks-failures,'/',checks,' systems checks');game.queue_free();await frames(8);quit(1 if failures else 0)

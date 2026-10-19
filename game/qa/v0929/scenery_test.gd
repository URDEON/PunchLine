extends SceneTree
var checks:=0
var failures:=0
func _initialize():run.call_deferred()
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1
 print('PASS ' if ok else 'FAIL ',label)
func run():
 Engine.set_meta('punchline_world',load('res://scripts/world_config.gd').DEFAULTS.duplicate())
 var game=load('res://main.tscn').instantiate();root.add_child(game)
 var loading:CanvasLayer=game.get_child(game.get_child_count()-1);var ticks:=0;var stage_values:Dictionary={};var start:=Time.get_ticks_msec()
 while game.loading and Time.get_ticks_msec()-start<90000:
  await process_frame;ticks+=1
  for node in game.get_children():
   if node is CanvasLayer and 'stages' in node:
    for stage in node.stages:stage_values[stage]=true
 check(not game.loading and ticks>20 and stage_values.size()>10,'visible animated loading spans seed, houses, greenery, collisions and camera readiness')
 var a:Node3D=game.arena.punchline.ambience
 check(a.placement.count>150000 and a.grass[0].multimesh.mesh.get_aabb().size.y>1.0,'default district has tall geometric grass rather than short ground tufts')
 check(a.grass[0].multimesh.custom_aabb.size.y>1.4,'grass culling bounds contain the taller wind-blown blades')
 check(a.decorations.placements.size()>60 and a.clouds.mesh!=null,'deterministic district includes park furniture, planters, stones, lamps and clouds')
 var clear:=true
 var source=load('res://scripts/district_greenery.gd').new();source.prepare(load('res://scripts/world_config.gd').make_plan(load('res://scripts/world_config.gd').DEFAULTS),'923')
 for prop in a.decorations.placements:
  clear=clear and not source.blocked(prop.point,2.2)
 check(clear,'all park details clear roads, parking, buildings and measured access routes')
 var bodies:int=a.find_children('*','StaticBody3D',true,false).size()
 game.preferences.set_value('fog_enabled',false)
 check(not a.environment.fog_enabled and not a.environment.volumetric_fog_enabled,'Sin niebla disables ambient and volumetric fog together')
 game.preferences.set_preset(2)
 check(not a.environment.fog_enabled and not game.preferences.values.fog_enabled,'graphics presets preserve explicit no-fog mode')
 check(a.find_children('*','StaticBody3D',true,false).size()==bodies,'quality changes preserve authoritative vegetation and park furniture collision')
 var plan:Dictionary=load('res://scripts/world_config.gd').make_plan(load('res://scripts/world_config.gd').DEFAULTS)
 var humans:=0;var interior:=false;var fixed:=0
 for b in plan.buildings:
  var node:Node3D=game.arena.punchline.housing.get_node('GeneratedBuildings/'+b.lot+'/'+b.id)
  if b.access=='human_only':humans+=1;check(node.get_node('Doors').get_meta('clear_width')==1.1,'human-only door keeps its normal physical width')
  if String(b.access).begins_with('mecha'):fixed+=1
  if node.find_children('KitchenBase','StaticBody3D',true,false).size()>0 and node.find_children('BedFrame','StaticBody3D',true,false).size()>0:interior=true
 check(humans>0 and fixed==6,'human door variants coexist with the six preserved measured mecha houses')
 check(interior,'generated residential rooms include usable furniture and kitchen geometry')
 print('SCENERY_COUNTS houses=',plan.buildings.size(),' humans=',humans,' trees=',a.trees.trees.size(),' grass=',a.placement.count,' decor=',a.decorations.placements.size())
 print('RESULT ',checks-failures,'/',checks,' loading, vegetation, interiors and fog checks')
 game.queue_free()
 for i in range(8):await process_frame
 quit(1 if failures else 0)

extends SceneTree
func _initialize()->void:
 var settings=load('res://scripts/world_config.gd')
 var plans:Array=[]
 for seed in ['923','Bosque 42','Bosque 43','Distrito nuevo','-17']:
  for density in [0,2]:
   var config:Dictionary=settings.normalized({'seed':seed,'density':density})
   var plan:Dictionary=settings.make_plan(config)
   if plan!=settings.make_plan(config):push_error('Non-deterministic plan');quit(1);return
   plans.append(plan)
 var file:=FileAccess.open('/tmp/punchline-layouts-v0929.json',FileAccess.WRITE);file.store_string(JSON.stringify(plans));file.close()
 print('EXPORTED ',plans.size(),' reproducible layouts');quit()

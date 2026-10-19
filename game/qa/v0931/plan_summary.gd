extends SceneTree
func _initialize()->void:
 var config=load("res://scripts/world_config.gd")
 var start:=Time.get_ticks_msec()
 var plan:Dictionary=config.make_plan(config.DEFAULTS)
 var towers:=0
 for b in plan.buildings:
  if int(b.get("storeys",1))>1:towers+=1
 var file:=FileAccess.open("/tmp/punchline-plan-v0931.json",FileAccess.WRITE);file.store_string(JSON.stringify(plan))
 print("RESULT buildings=",plan.buildings.size()," multi_storey=",towers," generation_ms=",Time.get_ticks_msec()-start)
 quit(0 if plan.buildings.size()>110 and towers>15 else 1)

extends SceneTree
func _initialize()->void:run.call_deferred()
func run()->void:
	var game:Node3D=load("res://main.tscn").instantiate();root.add_child(game)
	for i in range(90):await physics_frame
	var samples:Array[float]=[];var process:Array[float]=[]
	for i in range(180):
		await physics_frame
		samples.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
		process.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
	samples.sort();process.sort()
	var result:Dictionary={"mode":OS.get_environment("PUNCHLINE_HOUSING_MODE"),"godot":Engine.get_version_info().string,"rendering":"headless dummy; GPU/render FPS not measured","physics_median_ms":samples[90],"physics_p95_ms":samples[171],"process_median_ms":process[90],"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"collision_shapes":game.find_children("*","CollisionShape3D",true,false).size(),"samples":samples.size()}
	var file:=FileAccess.open("res://housing/docs/evidence/performance_"+OS.get_environment("PUNCHLINE_HOUSING_MODE")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t")+"\n");file.close();print("PERF ",result)
	game.queue_free();await process_frame;await process_frame;quit(0)

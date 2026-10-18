extends SceneTree
var game: Node3D
var samples: Array[Dictionary] = []
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	game = load("res://main.tscn").instantiate();root.add_child(game);await frames(20)
	for e in game.enemies:game.set_dummy_mode(e,0)
	var floor_body := StaticBody3D.new();game.add_child(floor_body);floor_body.position = Vector3(1000,-.1,0)
	var col := CollisionShape3D.new();var shape := BoxShape3D.new();shape.size = Vector3(300,.2,300);col.shape = shape;floor_body.add_child(col)
	game.robots.select(1);game.player.position = Vector3(1000,.02,0);game.player.velocity = Vector3.ZERO;game.charge = 100;await frames(30)
	if not game.fusion.request(): push_error("No fue posible iniciar fusión en soak");quit(1);return
	game.fusion.sequence.advance(11.5);await frames(30)
	var start := Time.get_ticks_msec();var duration := 600.0
	if not OS.get_environment("PUNCHLINE_SOAK_SECONDS").is_empty():duration = float(OS.get_environment("PUNCHLINE_SOAK_SECONDS"))
	var next_sample := 0.0;var last_direction := -1;var paused_once := false
	while float(Time.get_ticks_msec()-start)/1000 < duration:
		await physics_frame
		var elapsed := float(Time.get_ticks_msec()-start)/1000
		var direction := floori(elapsed/12)%4
		if direction != last_direction:
			for action in ["forward","back","left","right"]:Input.action_release(action)
			Input.action_press(["forward","right","back","left"][direction]);last_direction = direction
		if not paused_once and elapsed > duration*.5:
			game.set_paused(true);await frames(60);game.set_paused(false);paused_once = true
		if elapsed >= next_sample:
			next_sample = elapsed+1
			samples.append({"seconds":elapsed,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"memory":OS.get_static_memory_usage(),"effects":game.moves.effects.size(),"tweens":get_processed_tweens().size(),"fusion":game.fusion.fused})
			if int(elapsed)%60 == 0:print("SOAK ",samples[-1])
	for action in ["forward","back","left","right"]:Input.action_release(action)
	var file := FileAccess.open(OS.get_environment("PUNCHLINE_SOAK_OUTPUT") if not OS.get_environment("PUNCHLINE_SOAK_OUTPUT").is_empty() else "user://soak_v0924.json",FileAccess.WRITE);file.store_string(JSON.stringify(samples,"\t"));file.close()
	var stable: bool = game.fusion.fused and samples.size()>10
	var first: Dictionary = samples[mini(20,samples.size()-1)];var last: Dictionary = samples[-1]
	stable = stable and int(last.nodes)-int(first.nodes)<50 and int(last.resources)-int(first.resources)<20
	print("PASS " if stable else "FAIL ","fusión prolongada con objetos y recursos acotados")
	game.queue_free();await frames(10);print("RESULTADO ",1 if stable else 0,"/1");quit(0 if stable else 1)

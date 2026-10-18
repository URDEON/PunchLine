extends SceneTree
func _initialize()->void:run.call_deferred()
func run()->void:
	var game:Node3D=load("res://main.tscn").instantiate();root.add_child(game)
	for i in range(12):await physics_frame
	game.robots.select(1);game.charge=100;game.player.position=Vector3(-16,.1,0)
	for i in range(10):await physics_frame
	if not game.fusion.request():quit(1);return
	game.fusion.sequence.advance(11.5)
	for i in range(5):await physics_frame
	var rig:Node3D=game.fusion.sequence.articulation
	for connection in rig.foot_contact.get_connections():rig.foot_contact.disconnect(connection.callable)
	var report:Dictionary={"kind":"headless_animation_microbenchmark","gpu_fps":false,"samples":[]}
	for enabled in [false,true,false,true,false,true]:
		rig.gait_enabled=enabled;rig.gait.clear();game.player.position=Vector3(-16,.001,0)
		var measures:Array=[]
		for i in range(360):
			game.player.position.z-=1.05/60;game.fusion.sequence.global_position=game.player.position
			rig.configure_locomotion(game.player,false,Vector3(0,0,-1.05))
			var start:=Time.get_ticks_usec();rig.locomotion(1.0/60,1.05,true,0,1.05/60,true)
			if i>=60:measures.append(Time.get_ticks_usec()-start)
		measures.sort();report.samples.append({"procedural":enabled,"median_us":measures[150],"p95_us":measures[285],"queries_total":rig.gait.queries_total})
	print("PROFILE ",JSON.stringify(report))
	game.fusion.reset();game.queue_free()
	for i in range(8):await physics_frame
	await process_frame;quit()

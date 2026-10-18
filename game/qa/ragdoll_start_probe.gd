extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var game: Node3D = load("res://main.tscn").instantiate(); root.add_child(game)
	for i in range(10): await physics_frame
	game.set_physics_process(false); game.locomotion_tree.active = false
	var ctl: Node = game.physical_ragdoll
	game.rig_anim.active = true; game.rig_anim.play("mixamo/idle",0); game.rig_anim.seek(.15,true)
	ctl.start(Vector3(3,2,-1))
	for body in ctl.bodies:
		print("INITIAL ",body.bone_name," ",body.global_transform," SERVER ",PhysicsServer3D.body_get_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM))
	for i in range(210):
		await physics_frame; ctl.follow_actor()
		var unsafe := false
		for body in ctl.bodies: unsafe = unsafe or body.linear_velocity.length() > 20
		if i < 2 or i in [10,20,40,59,100,150,209] or unsafe:
			for body in ctl.bodies: print("FRAME ",i," ",body.bone_name," P ",body.global_position," V ",body.linear_velocity)
	ctl.stop(false); game.feedback.stop_all(); OS.delay_msec(150); game.queue_free(); await process_frame; await process_frame; quit()

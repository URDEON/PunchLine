extends SceneTree
func _initialize()->void:run.call_deferred()
func run()->void:
	var game:Node3D=load("res://main.tscn").instantiate();root.add_child(game)
	for i in range(12):await physics_frame
	game.robots.select(1);game.player.position=Vector3(-16,.1,0);game.charge=100
	for i in range(10):await physics_frame
	if not game.fusion.request():quit(1);return
	game.fusion.sequence.advance(11.5)
	for i in range(10):await physics_frame
	var rig:Node3D=game.fusion.sequence.articulation;var ok:=true;var maximum:=0.0
	for i in range(rig.CAP_JOINTS.size()):
		var transform:Transform3D=rig.global_transform*rig.joint_cap_transforms[i]
		var pivot:Node3D=rig.pivots[rig.CAP_JOINTS[i][0]]
		var radius:float=transform.basis.get_scale().length()/sqrt(3)
		maximum=maxf(maximum,radius)
		ok=ok and transform.origin.distance_to(pivot.global_position)<.001 and radius>.10 and radius<.21
	print("PASS " if ok else "FAIL ","juntas en su eje y tamaño real acotado; radio máximo ",maximum)
	game.fusion.reset();game.queue_free()
	for i in range(8):await physics_frame
	print("RESULTADO ",1 if ok else 0,"/1");quit(0 if ok else 1)

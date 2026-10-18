extends SceneTree
var game: Node3D
func _initialize() -> void:
	call_deferred("run")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	game=load("res://main.tscn").instantiate()
	root.add_child(game)
	for distance in [1.2,1.8,2.2,4.0,8.0]:
		for degrees in [-45.0,-30.0,-15.0,0.0,15.0,30.0,45.0]:
			for action in ["left","right","forward","back","attack","block"]: Input.action_release(action)
			game.reset_lab()
			game.yaw=0
			game.preferences.values.hold_attack=false
			for i in range(game.enemies.size()):
				var enemy: Dictionary=game.enemies[i]
				enemy.kind=0
				enemy.body.position=Vector3(35+i*4,0.1,30)
				enemy.body.velocity=Vector3.ZERO
			await frames(35)
			var enemy: Dictionary=game.enemies[0]
			enemy.body.position=game.player.position+Vector3.FORWARD.rotated(Vector3.UP,deg_to_rad(degrees))*distance
			enemy.body.velocity=Vector3.ZERO
			await frames(2)
			var can_use: bool=game.moves.can_use(1)
			var found: bool=not game.moves.projection.select_target().is_empty()
			var positions: String="player=%s enemy=%s floor=%s" % [game.player.position,enemy.body.position,game.player.is_on_floor()]
			game.moves.press(1)
			var selected: bool=not game.moves.target.is_empty()
			await frames(120)
			print("GRID d=%.1f angle=%+.0f can_use=%s found=%s selected=%s damage=%.0f result=%s %s" % [distance,degrees,can_use,found,selected,100-enemy.hp,game.moves.projection.last_result,positions])
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await process_frame
	await process_frame
	quit()

extends "res://qa/update_v0924_test.gd"
func run() -> void:
	game = load("res://main.tscn").instantiate();root.add_child(game);await frames(15)
	for e in game.enemies:game.set_dummy_mode(e,0)
	box(Vector3(400,-.1,0),Vector3(100,.2,100))
	game.robots.select(1);game.player.position = Vector3(400,.025,0);game.player.velocity = Vector3.ZERO;game.charge = 100;await frames(25)
	game.fusion.request();game.fusion.sequence.advance(11.5);await frames(25)
	box(Vector3(400,3.05,0),Vector3(9,.2,9))
	for i in range(12):
		var p: Vector3 = game.player.global_position
		var ray := PhysicsRayQueryParameters3D.create(p+Vector3.UP*.12,p+Vector3.UP*4.15,1);ray.exclude = [game.player.get_rid()]
		var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
		print("TRACE ",i," ",{"position":p,"target":game.robot_clearance.target_height,"height":game.robot_clearance.current_height,"normal":hit.get("normal"),"hit":hit.get("position"),"clock":game.robot_clearance.last_check,"minimum":game.robot_clearance.minimum,"collider_y":game.robots.naoya.collision.position.y,"mask":game.player.collision_mask})
		await frames(1)
	game.queue_free();await frames(8);quit()

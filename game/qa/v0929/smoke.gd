extends SceneTree
func _initialize()->void:run.call_deferred()
func run()->void:
 var game:Node3D=load("res://main.tscn").instantiate();root.add_child(game)
 var start:=Time.get_ticks_msec()
 while game.loading and Time.get_ticks_msec()-start<90000:await process_frame
 if game.loading:push_error("World initialization timed out");quit(1);return
 print("LOADED ms=",Time.get_ticks_msec()-start," houses=",game.arena.punchline.destruction.buildings.size()," grass=",game.arena.punchline.ambience.placement.count," decor=",game.arena.punchline.ambience.decorations.placements.size())
 for i in range(20):await physics_frame
 print("RESULT startup complete; player=",game.player.global_position)
 game.queue_free()
 for i in range(8):await process_frame
 quit()

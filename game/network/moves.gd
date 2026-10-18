extends "res://scripts/combat_moves.gd"
var replica_domain := false
func freeze_enemy(enemy: Dictionary,duration: float) -> void:
	if not game.session.is_host() or not game.session.actors.has(int(enemy.peer)): return
	var target_player: Node3D = game.session.actors[int(enemy.peer)]
	if duration >= 4.999: target_player.moves.freeze_player(duration)
	else: target_player.held_time = maxf(target_player.held_time,duration); game.interrupt_enemy_attack(enemy)
	game.refresh_targets()
func break_enemy_frame(enemy: Dictionary,reason: String = "hit") -> bool:
	return game.session.actors[int(enemy.peer)].moves.break_player_frame(reason)
func replica_tick(delta: float) -> void:
	# Tick only presentation effects. Damage, timers and domain penalties remain on host.
	for i in range(effects.size()-1,-1,-1):
		effects[i].life -= delta
		if effects[i].life <= 0: effects[i].node.queue_free(); effects.remove_at(i)
	if player_freeze > 0 and is_instance_valid(player_frame): player_frame.enforce()
	if key == "b1" and stage in ["windup","approach","commit","barrage"]:
		if gate_nodes.is_empty():
			for point in projection.LEAD_DISTANCES:
				var gate := preload("res://scripts/projection_echo.gd").new(); add_child(gate); gate.setup(CYAN); gate_nodes.append(gate); gates.append(Vector3.ZERO)
		projection.pose_timer -= delta
		if projection.pose_timer <= 0: projection.refresh_pose()
		projection.update_gate()
	else: clear_gates()

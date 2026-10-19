extends "res://scripts/feedback.gd"
func sound(id: String,pos: Vector3,volume: float = 0.0) -> void:
	if not game.session.is_host() or float(cooldowns.get(id,0)) > 0: return
	cooldowns[id] = .18 if id=="block" else (.12 if id=="glass" else .06)
	game.session.spatial_sound.rpc(game.peer_id,id,pos,volume)
func play_local(id: String,pos: Vector3,volume: float) -> void:
	cooldowns[id] = 0
	super.sound(id,pos,volume)

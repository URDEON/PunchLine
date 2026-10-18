extends "res://scripts/robot_character.gd"
func select(character: int) -> void:
	game.session.local_character(character)

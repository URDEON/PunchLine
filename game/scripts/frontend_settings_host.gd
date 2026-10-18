extends Node3D
var zoom:=5.5
var interface:Node
var preferences:Node
func _ready()->void:
 preferences=preload("res://scripts/preferences.gd").new();add_child(preferences);preferences.setup(self)

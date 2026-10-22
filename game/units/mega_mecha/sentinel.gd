extends "res://units/soldiers/soldier.gd"
## Reuses the component contract, not the old fighter/fusion controller.
func _ready() -> void:
	unit_id = "sentinel"
	tuning = tuning.duplicate()
	tuning.standing_height = 4.0
	tuning.crouching_height = 2.7
	tuning.radius = 1.05
	tuning.run_speed = 2.35
	tuning.sprint_speed = 3.2
	tuning.walk_speed = 1.05
	tuning.crouch_speed = 1.0
	tuning.jump_speed = 0.0
	tuning.max_step_height = 0.42
	super._ready()
	health.maximum = 300
	health.restore()
	equipment.definitions.clear()
	equipment.definitions.append(preload("res://combat/sentinel_cannon.tres"))
	view.standing_eye_height = 3.5
	view.crouching_eye_height = 2.35
	view.eye_height = 3.5
	view.distance_scale = 2.3
	view.allow_first_person = false
	view.snap()

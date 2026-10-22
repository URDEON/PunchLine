extends Node3D
const Soldier = preload("res://units/soldiers/soldier.tscn")
const Hud = preload("res://ui/warfare_hud.gd")
const Recorder = preload("res://core/performance_recorder.gd")
const Sentinel = preload("res://units/mega_mecha/sentinel.tscn")
const Feedback = preload("res://combat/combat_feedback.gd")
const Target = preload("res://combat/practice_target.gd")
const Objective = preload("res://game_modes/practice_objective.gd")
var player: CharacterBody3D
var hud: CanvasLayer
var recorder: Node
var respawn_timer: Timer
var feedback: Node3D
var targets: Array[Node3D] = []
var objective: Node3D
@onready var district: Node3D = $District

func _ready() -> void:
	feedback = Feedback.new()
	add_child(feedback)
	player = Sentinel.instantiate() if Engine.get_meta("warfare_unit","soldier")=="sentinel" else Soldier.instantiate()
	player.position = district.spawn
	add_child(player)
	player.equipment.setup(feedback)
	player.respawn_requested.connect(_schedule_respawn)
	respawn_timer = Timer.new()
	respawn_timer.one_shot = true
	respawn_timer.wait_time = 2.5
	add_child(respawn_timer)
	respawn_timer.timeout.connect(respawn)
	for x in [-91.0,-85.0,-79.0]:
		var target := Target.new()
		target.position = Vector3(x,0.04,-55)
		add_child(target)
		targets.append(target)
	objective = Objective.new()
	objective.player = player
	objective.position = Vector3(-85,0.05,-66)
	add_child(objective)
	recorder = Recorder.new()
	add_child(recorder)
	hud = Hud.new()
	hud.game = self
	add_child(hud)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _schedule_respawn() -> void:
	respawn_timer.start()

func respawn() -> void:
	respawn_timer.stop()
	player.respawn(district.spawn)

func return_to_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://ui/warfare_menu.tscn")

func _exit_tree() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

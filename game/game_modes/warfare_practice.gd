extends Node3D
const Soldier = preload("res://units/soldiers/soldier.tscn")
const Hud = preload("res://ui/warfare_hud.gd")
const Recorder = preload("res://core/performance_recorder.gd")
var player: CharacterBody3D
var hud: CanvasLayer
var recorder: Node
var respawn_timer: Timer
@onready var district: Node3D = $District

func _ready() -> void:
	player = Soldier.instantiate()
	player.position = district.spawn
	add_child(player)
	player.respawn_requested.connect(_schedule_respawn)
	respawn_timer = Timer.new()
	respawn_timer.one_shot = true
	respawn_timer.wait_time = 2.5
	add_child(respawn_timer)
	respawn_timer.timeout.connect(respawn)
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

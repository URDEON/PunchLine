extends CharacterBody3D
## Composition root only. Gameplay systems live in separate components.
signal respawn_requested
@export var tuning: Resource = preload("res://units/soldiers/default_soldier.tres")
@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var movement: Node = $Movement
@onready var human_input: Node = $HumanInput
@onready var visual: Node3D = $Visual
@onready var view: Node3D = $View
@onready var health: Node = $Health
var command_override: RefCounted

func _ready() -> void:
	collider.shape = collider.shape.duplicate()
	collider.shape.radius = tuning.radius
	collider.shape.height = tuning.standing_height
	collider.position.y = tuning.standing_height*0.5
	human_input.install_actions()
	view.setup(self)
	movement.landed.connect(view.land)
	health.incapacitated.connect(_on_incapacitated)

func _physics_process(delta: float) -> void:
	if not health.alive: return
	var command: RefCounted = command_override if command_override!=null else human_input.read(view.yaw)
	movement.step(self,command,delta)
	visual.animate(self,command,delta)
	if global_position.y < -15: health.apply_damage(health.maximum)

func _on_incapacitated() -> void:
	velocity = Vector3.ZERO
	view.spectating = true
	respawn_requested.emit()

func respawn(point: Vector3) -> void:
	global_position = point
	velocity = Vector3.ZERO
	reset_physics_interpolation()
	movement.coyote = 0
	movement.jump_buffer = 0
	health.restore()
	view.spectating = false
	view.snap()

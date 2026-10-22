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
@onready var equipment: Node = $Equipment
var unit_id := "soldier"
var impact_time := 0.0
var previous_health := 100.0
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
	previous_health = health.current
	health.changed.connect(_on_health_changed)

func _physics_process(delta: float) -> void:
	if not health.alive: return
	impact_time = maxf(0,impact_time-delta)
	var command: RefCounted = command_override if command_override!=null else human_input.read(view.yaw)
	movement.step(self,command,delta)
	if equipment.feedback!=null: equipment.tick(self,command,delta)
	visual.animate(self,command,delta)
	if global_position.y < -15: health.apply_damage(health.maximum)

func _on_health_changed(current: float,_maximum: float) -> void:
	if current<previous_health:
		impact_time = 0.35
		if visual.has_method("hit"): visual.hit()
		view.kick(0.02)
	previous_health = current

func _on_incapacitated() -> void:
	velocity = Vector3.ZERO
	view.spectating = true
	equipment.reload_remaining = 0
	respawn_requested.emit()

func respawn(point: Vector3) -> void:
	global_position = point
	velocity = Vector3.ZERO
	reset_physics_interpolation()
	movement.coyote = 0
	movement.jump_buffer = 0
	health.restore()
	if equipment.feedback!=null: equipment.reset()
	view.spectating = false
	view.snap()

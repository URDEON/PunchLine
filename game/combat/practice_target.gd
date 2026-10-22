extends StaticBody3D
## Non-human range target with bounded health/recovery; no bots or ragdoll simulation.
var maximum := 100.0
var health := 100.0
var hits := 0
var recover := 0.0
var label: Label3D
var marker: MeshInstance3D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.2,2.0,0.2)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = 1
	add_child(collision)
	marker = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	marker.mesh = mesh
	marker.position.y = 1
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("b9744a")
	marker.material_override = material
	add_child(marker)
	label = Label3D.new()
	label.position.y = 2.3
	label.font_size = 42
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	add_child(label)
	refresh()

func apply_hit(amount: float,_point: Vector3) -> void:
	if health<=0: return
	health = maxf(0,health-amount)
	hits += 1
	if health<=0: recover = 3.0
	refresh()

func refresh() -> void:
	label.text = "BALIZA · %d%%\nIMPACTOS %d" % [health,hits]
	marker.material_override.albedo_color = Color("394a48") if health<=0 else Color("b9744a")

func _physics_process(delta: float) -> void:
	if recover<=0: return
	recover -= delta
	if recover<=0: health = maximum; refresh()

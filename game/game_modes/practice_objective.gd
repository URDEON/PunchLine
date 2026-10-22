extends Node3D
## A real training capture zone; no simulated enemy score or fictional bot population.
var player: CharacterBody3D
var progress := 0.0
var captured := false
var score := 0
var radius := 4.5
var label: Label3D
var score_time := 0.0

func _ready() -> void:
	var ring := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.025
	ring.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2,0.65,0.7,0.18)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = material
	add_child(ring)
	label = Label3D.new()
	label.position.y = 3.2
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 64
	add_child(label)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): return
	var offset := player.global_position-global_position
	offset.y = 0
	if not captured:
		progress = move_toward(progress,1.0 if player.health.alive and offset.length()<radius else 0.0,delta/5)
		if progress>=1: captured = true; score += 100
	else:
		score_time += delta
		if score_time>=5: score_time = 0; score += 1
	label.text = "A · AURORA" if captured else "A · CAPTURAR %d%%" % int(progress*100)

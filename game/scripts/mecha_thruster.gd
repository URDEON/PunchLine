extends Node3D
## Chorro sin cono opaco: núcleo blanco, bordes azules, ruido animado y estela.
var flames: Array[MeshInstance3D] = []
var trails: Array[Node3D] = []
var throttle := 0.0
var seed := 0.0

func _ready() -> void:
	for side in [-1,1]:
		var flame := MeshInstance3D.new(); var quad := QuadMesh.new(); quad.size = Vector2(.40,1.45)
		flame.mesh = quad; flame.position = Vector3(side*.22,-.58,.13)
		var material := ShaderMaterial.new(); material.shader = preload("res://shaders/mecha_exhaust.gdshader"); material.set_shader_parameter("seed",seed+side*2.2)
		flame.material_override = material; flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(flame); flames.append(flame)
		var factory := preload("res://scripts/mecha_dust.gd").new()
		var trail := factory.make_emitter(14,.48,Vector2(1.0,2.8),Vector2(.08,.25),Color(.16,.6,1),.24)
		factory.free(); trail.one_shot = false; trail.explosiveness = .0
		trail.local_coords = false; trail.position = Vector3(side*.22,.0,.13)
		if trail is CPUParticles3D: trail.direction = Vector3.DOWN; trail.gravity = Vector3(0,-.5,0); trail.spread = 14
		else: trail.process_material.direction = Vector3.DOWN; trail.process_material.gravity = Vector3(0,-.5,0); trail.process_material.spread = 14
		add_child(trail); trails.append(trail)

func animate(time: float, power: float) -> void:
	throttle = clampf(power,0,1.4)
	for i in range(flames.size()):
		var pulse := .92+sin(time*47+i*2.1+seed)*.055+sin(time*73+i)*.035
		flames[i].visible = throttle > .01
		flames[i].scale = Vector3(.82+.18*throttle, (.65+.35*throttle)*pulse,1)
		flames[i].material_override.set_shader_parameter("throttle",throttle)
		trails[i].emitting = throttle > .15 and visible

func stop() -> void:
	animate(0,0)

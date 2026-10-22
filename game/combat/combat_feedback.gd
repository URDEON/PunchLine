extends Node3D
## Fixed-size visual/audio pools: no per-shot nodes or persistent physical debris.
var tracers: Array[Dictionary] = []
var voices: Array[AudioStreamPlayer3D] = []
var cursor := 0
var sound: AudioStreamWAV

func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("c9e7c1")
	for i in range(8):
		var line := MeshInstance3D.new()
		line.mesh = ImmediateMesh.new()
		line.material_override = material
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(line)
		line.hide()
		tracers.append({"node":line,"life":0.0})
	for i in range(6):
		var voice := AudioStreamPlayer3D.new()
		voice.max_distance = 90
		voice.unit_size = 8
		voice.volume_db = -16
		add_child(voice)
		voices.append(voice)
	# Original abstract electronic report, generated once; not sampled from a real weapon.
	var bytes := PackedByteArray()
	bytes.resize(4410*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2929
	for i in range(4410):
		var t := float(i)/44100
		var value := (rng.randf_range(-1,1)*0.65+sin(t*TAU*145)*0.35)*exp(-t*55)*0.65
		bytes.encode_s16(i*2,int(value*32767))
	sound = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 44100
	sound.data = bytes

func shot(from: Vector3,to: Vector3,heavy: bool = false) -> void:
	var entry: Dictionary = tracers[cursor%tracers.size()]
	var mesh: ImmediateMesh = entry.node.mesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(to_local(from))
	mesh.surface_add_vertex(to_local(to))
	mesh.surface_end()
	entry.life = 0.065
	entry.node.show()
	var voice := voices[cursor%voices.size()]
	voice.global_position = from
	voice.stream = preload("res://assets/audio/explosionCrunch_000.ogg") if heavy else sound
	voice.pitch_scale = 0.8 if heavy else 1.0
	voice.play()
	cursor += 1

func _process(delta: float) -> void:
	for entry in tracers:
		if entry.life<=0: continue
		entry.life -= delta
		if entry.life<=0: entry.node.hide()

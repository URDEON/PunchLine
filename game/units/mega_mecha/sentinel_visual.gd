extends Node3D
## Direct spawn: original Sentinel, original Rustwing arm, original articulation. No fusion.
const Model = preload("res://assets/fusion/optimized/Junkyard_Sentinel.glb")
const Articulation = preload("res://scripts/sentinel_articulation.gd")
var model: Node3D
var articulation: Node3D
var phase := 0.0
var previous := Vector3.ZERO
var deployment := 0.0
var steps: Array[AudioStreamPlayer3D] = []
var step_index := 0

func _ready() -> void:
	model = Node3D.new()
	model.name = "SentinelVisualRoot"
	add_child(model)
	var source := Model.instantiate()
	model.add_child(source)
	var pieces: Dictionary = {}
	var bounds := AABB()
	var first := true
	for mesh in source.find_children("*","MeshInstance3D",true,false):
		pieces[String(mesh.name)] = mesh
		var box: AABB = model.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	articulation = Articulation.new()
	model.add_child(articulation)
	articulation.setup(pieces)
	model.scale = Vector3.ONE*(4.0/bounds.size.y)
	model.position.y = -bounds.position.y*model.scale.y
	model.rotation.y = PI
	articulation.activation(2.8)
	articulation.foot_contact.connect(_step)
	for i in range(2):
		var voice := AudioStreamPlayer3D.new()
		voice.stream = load("res://assets/audio/mecha_v0914/step_heavy_"+str(i)+".wav")
		voice.volume_db = -14
		voice.unit_size = 12
		voice.max_distance = 80
		add_child(voice)
		steps.append(voice)
	previous = global_position

func animate(body: CharacterBody3D,command: RefCounted,delta: float) -> void:
	var distance := global_position.distance_to(previous)
	previous = global_position
	phase = fposmod(phase+distance*2,TAU)
	deployment = move_toward(deployment,1.0 if command.aim or command.fire else 0.0,delta*1.7)
	articulation.crouch_weight = move_toward(articulation.crouch_weight,1.0 if body.movement.crouched else 0.0,delta*5)
	articulation.action = {"id":"cannon","deploy":deployment,"aim":body.view.camera.global_position-body.view.camera.global_basis.z*180} if deployment>0 else {}
	articulation.configure_locomotion(body,false,body.velocity)
	articulation.configure_view(body.view.yaw,body.view.pitch,true)
	articulation.locomotion(delta,body.movement.locomotion_speed,body.is_on_floor(),body.velocity.y,distance)

func _step(_side: String,point: Vector3) -> void:
	var voice := steps[step_index%steps.size()]
	voice.global_position = point
	voice.play()
	step_index += 1

func set_local_first_person(_enabled: bool) -> void: pass
func set_weapon(_index: int) -> void: pass
func shot() -> void: pass
func ready_to_fire() -> bool: return deployment>0.9
func muzzle_position() -> Vector3: return articulation.muzzle()

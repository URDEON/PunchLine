extends Node3D
## Render-time stabilized body pivot. Mouse aim never inherits visual bob or sway.
const Lens = preload("res://scripts/body_lens.gd")
var body: CharacterBody3D
var arm: SpringArm3D
var camera: Camera3D
var lens: CanvasLayer
var yaw := 0.0
var pitch := -0.08
var third_person := true
var spectating := false
var shoulder := 1.0
var eye_height := 1.63
var sway := Vector2.ZERO
var landing := 0.0
var initialized := false
var camera_clock := 0.0
var standing_eye_height := 1.63
var crouching_eye_height := 1.01
var distance_scale := 1.0
var allow_first_person := true
var recoil := 0.0

func setup(actor: CharacterBody3D) -> void:
	body = actor
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	arm = SpringArm3D.new()
	arm.collision_mask = 1
	arm.margin = 0.10
	var sphere := SphereShape3D.new()
	sphere.radius = 0.15
	arm.shape = sphere
	arm.add_excluded_object(body.get_rid())
	add_child(arm)
	camera = Camera3D.new()
	camera.near = 0.04
	camera.current = true
	arm.add_child(camera)
	lens = Lens.new()
	add_child(lens)
	lens.configure({"chromatic":0.0,"bloom":0.0,"lens_dirt":0.0,"effects":false})
	snap()

func snap() -> void:
	if body == null: return
	global_position = body.global_position+Vector3.UP*eye_height
	initialized = false

func set_first_person(enabled: bool) -> void:
	if not allow_first_person: enabled = false
	third_person = not enabled
	if body!=null: body.visual.set_local_first_person(enabled and not spectating)

func _unhandled_input(event: InputEvent) -> void:
	if body==null or spectating: return
	if DisplayServer.get_name()!="headless" and Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED: return
	if event is InputEventMouseMotion:
		var sensitivity: float = WarfareSettings.values.sensitivity
		yaw = wrapf(yaw-event.relative.x*sensitivity,-PI,PI)
		pitch = clampf(pitch-event.relative.y*sensitivity*(-1 if WarfareSettings.values.invert_y else 1),-1.48,1.35)
		sway += event.relative*0.00008
		sway = sway.clamp(Vector2(-0.012,-0.012),Vector2(0.012,0.012))
	elif event.is_action_pressed("wf_view"):
		set_first_person(third_person)
	elif event.is_action_pressed("wf_shoulder"):
		shoulder *= -1

func land(speed: float) -> void:
	landing = clampf(speed*0.008,0,0.10)

func kick(amount: float) -> void:
	recoil = minf(0.035,recoil+amount*float(WarfareSettings.values.shake))

func _process(delta: float) -> void:
	if body==null or camera==null: return
	var options: Dictionary = WarfareSettings.values
	var fps := not third_person and not spectating
	var weight := 1-exp(-delta*16)
	var target_eye: float = crouching_eye_height if body.movement.crouched else standing_eye_height
	if fps:
		# Keep hands and receiver below the aim line; the camera remains body-linked.
		if body.equipment.aiming: target_eye -= 0.04
	eye_height = lerpf(eye_height,target_eye,weight)
	var position_source := body.get_global_transform_interpolated().origin
	global_position = position_source+Vector3.UP*(2.0 if spectating else eye_height)
	var speed: float = body.movement.locomotion_speed
	var moving := body.is_on_floor() and speed>0.2
	var amplitude := minf(speed/6.5,1.0) if moving else 0.0
	var effect := float(options.shake) if bool(options.bodycam) and fps else 0.0
	var bob := sin(body.visual.phase*2)*0.025*amplitude*effect if bool(options.bob) else 0.0
	global_position.y += bob-landing*float(options.shake)
	landing = move_toward(landing,0,delta*0.5)
	sway = sway.lerp(Vector2.ZERO,1-exp(-delta*10))
	rotation = Vector3(0,yaw,(-sin(body.visual.phase)*0.012*amplitude+sway.x)*effect)
	recoil = move_toward(recoil,0,delta*0.10)
	arm.rotation.x = pitch-sway.y*effect+recoil
	var shoulder_offset := shoulder*0.42 if not fps else 0.0
	# Do not place the spring origin through an adjacent wall when switching shoulder.
	if not fps and absf(shoulder_offset)>0.001:
		var target := global_position+global_basis.x*shoulder_offset
		var ray := PhysicsRayQueryParameters3D.create(global_position,target,1)
		var hit := body.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty(): shoulder_offset = 0
	# Looking down introduces a small, stabilized lean over the vest so the same
	# body's legs remain visible. Sweep the offset against the actual world first.
	var forward_offset := 0.0
	if fps:
		forward_offset = lerpf(0.12,0.52,smoothstep(0.5,1.25,-pitch))
		var lens_ray := PhysicsRayQueryParameters3D.create(global_position,
			global_position-global_basis.z*(forward_offset+0.08),1)
		var obstruction := body.get_world_3d().direct_space_state.intersect_ray(lens_ray)
		if not obstruction.is_empty():
			forward_offset = minf(forward_offset,maxf(0,global_position.distance_to(obstruction.position)-0.08))
	arm.position = Vector3(shoulder_offset,0,-forward_offset)
	arm.spring_length = 0.0 if fps else (4.0 if spectating else float(options.distance)*distance_scale)
	var target_fov: float = float(options.fov)*(0.78 if body.equipment.aiming else 1.0)+minf(5,speed)*0.7*effect
	camera.fov = lerpf(camera.fov,target_fov,weight) if initialized else target_fov
	body.visual.set_local_first_person(fps)
	lens.set_strength(0.06 if fps and bool(options.lens) else 0.0)
	lens.visible = fps and bool(options.lens)
	initialized = true
	camera_clock += delta

func mode_label() -> String:
	if spectating: return "OBSERVACIÓN"
	if third_person: return "TPS"
	return "FPS · BODYCAM" if WarfareSettings.values.bodycam else "FPS"

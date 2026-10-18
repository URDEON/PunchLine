extends Node
var game: Node3D
var active := false
var camera: Camera3D
var orbit_yaw := .6
var elevation := .25
var distance := 33.0

func setup(host: Node3D) -> void:
	game = host
	camera = Camera3D.new(); camera.name = "DomainInspectionCamera"
	camera.near = .1; camera.far = 600
	game.add_child(camera)

func toggle() -> bool:
	if active:
		active = false; game.camera.make_current(); return true
	if not is_instance_valid(game.moves.domain_exterior):
		game.ult_msg = "Activa el dominio antes de inspeccionar su exterior"
		game.ult_msg_time = 2.0; return false
	active = true; camera.make_current(); update(0.0); return true

func input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		toggle(); return true
	if not active: return false
	if event is InputEventMouseMotion:
		orbit_yaw -= event.relative.x*.005
		elevation = clampf(elevation+event.relative.y*.005,-1.45,1.45)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: distance = maxf(14,distance-2)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: distance = minf(65,distance+2)
	return event is InputEventMouseMotion or event is InputEventMouseButton or (event is InputEventKey and event.keycode in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SPACE])

func update(delta: float) -> void:
	if not active: return
	if not is_instance_valid(game.moves.domain_exterior): toggle(); return
	orbit_yaw += Input.get_axis("left","right")*delta
	elevation = clampf(elevation+Input.get_axis("forward","back")*delta,-1.45,1.45)
	var center: Vector3 = game.moves.domain_exterior.global_position
	camera.global_position = center+Vector3(0,0,distance).rotated(Vector3.RIGHT,-elevation).rotated(Vector3.UP,orbit_yaw)
	camera.look_at(center,Vector3.UP)

extends Node3D
var host: Node3D
var lift: AnimatableBody3D
var punchline: Node3D
var laboratory := false
var zones := {"ramp":Vector3(-17,.1,12),"roof":Vector3(-17,5.1,25),"pit":Vector3(19,-5.9,15),"lift":Vector3(-27,.5,16),"fall":Vector3(32,220,25),"boulevard":Vector3(54,.2,0),"district_roof":Vector3(-68,6.25,30),"plaza":Vector3(0,.1,-14)}
var lift_clock := 0.0
var surfaces: Array[StaticBody3D] = []
var urban: Node3D

func setup(game: Node3D, floor_mesh: MeshInstance3D) -> void:
	host = game
	laboratory = false # District500 replaces both older city layouts.
	if not laboratory:
		floor_mesh.get_parent().queue_free()
		punchline = preload("res://scripts/punchline_map.gd").new(); add_child(punchline); punchline.setup(game)
		urban = preload("res://scripts/punchline_interactions.gd").new(); add_child(urban); urban.setup(game,self)
		zones = {"plaza":Vector3(-80,.15,-50),"boulevard":Vector3(-80,.15,-80),"fall":Vector3(-80,220,-50)}
		return
	host = game
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/training_floor.gdshader")
	floor_mesh.material_override = material
	for index in range(8):
		var angle := TAU * index / 8.0
		var p := Vector3(sin(angle), 0, cos(angle)) * 77.0
		game.box(self, Vector3(1.4, 0.4, 1.4), p + Vector3.UP * 0.2, Color("242735"))
		game.box(self, Vector3(0.45, 6.0, 0.45), p + Vector3.UP * 3.2, Color("373843"))
		game.glow_box(self, Vector3(0.08, 3.7, 0.08), p + Vector3.UP * 3.2, Color("a697d5"))
		game.box(self, Vector3(2.2, 0.25, 2.2), p + Vector3.UP * 6.3, Color("272b37"))
	for spec in [[-6.0, "01  /  TÉCNICA", Color("79c9db")], [0.0, "02  /  GUARDIA", Color("dec488")], [6.0, "03  /  DUELO", Color("e091a0")]]:
		var sign := Label3D.new()
		add_child(sign)
		sign.position = Vector3(float(spec[0]), 0.04, -8.0)
		sign.rotation_degrees.x = -90
		sign.font_size = 42
		sign.pixel_size = 0.007
		sign.modulate = spec[2]
		sign.text = spec[1]
	for side in [-1, 1]:
		game.box(self, Vector3(1, 1.6, 10), Vector3(side * 20, 0.8, -3), Color("2b303c"))
		game.glow_box(self, Vector3(0.08, 0.04, 10), Vector3(side * 19.45, 1.62, -3), Color("b5a3de"))
	var inscription := Label3D.new()
	add_child(inscription)
	inscription.text = "PROJECTION  /  TRAINING GROUNDS"
	inscription.font_size = 60
	inscription.pixel_size = 0.009
	inscription.position = Vector3(0, 4, -25)
	inscription.modulate = Color("adb1bf")
	# Obstáculos reales para probar línea de visión y órbitas; fuera de las tres estaciones.
	for side in [-1,1]:
		wall(game,Vector3(side*38.0,1.5,-8.0),Vector3(0.8,3.0,7.0))
	wall(game,Vector3(-63.0,1.5,-12.0),Vector3(4.0,3.0,0.8))
	build_terrain(floor_mesh)
	urban = preload("res://scripts/urban_arena.gd").new(); add_child(urban); urban.setup(game,self)

func setup_async(game:Node3D,floor_mesh:MeshInstance3D,loading:CanvasLayer)->void:
	host=game;laboratory=false;floor_mesh.get_parent().queue_free()
	punchline=preload("res://scripts/punchline_map.gd").new();add_child(punchline)
	await punchline.setup_async(game,loading)
	urban=preload("res://scripts/punchline_interactions.gd").new();add_child(urban);urban.setup(game,self)
	zones={"plaza":Vector3(-80,.15,-50),"boulevard":Vector3(-80,.15,-80),"fall":Vector3(-80,220,-50)}

func wall(game: Node3D, position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = position
	game.box(body,size,Vector3.ZERO,Color("303746"))
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	surfaces.append(body)

func platform(position: Vector3, size: Vector3, color: Color = Color("303746")) -> StaticBody3D:
	var body := StaticBody3D.new(); add_child(body); body.position = position
	host.box(body,size,Vector3.ZERO,color)
	var collision := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size
	collision.shape = shape; body.add_child(collision); surfaces.append(body)
	return body

func ramp(from: Vector3, to: Vector3, width: float) -> void:
	var direction := (to-from).normalized()
	var x_axis := Vector3.UP.cross(direction).normalized()
	var basis := Basis(x_axis,direction.cross(x_axis),direction)
	var body := platform((from+to)*.5-basis.y*.15,Vector3(width,.3,from.distance_to(to)),Color("414653"))
	body.basis = basis
	for side in [-1,1]: host.glow_box(body,Vector3(.045,.025,from.distance_to(to)),Vector3(side*(width*.5-.1),.165,0),Color("cdb279"))

func zone_sign(text: String, position: Vector3, color: Color) -> void:
	var caption := Label3D.new(); add_child(caption); caption.text = text; caption.position = position
	caption.font_size = 40; caption.pixel_size = .008; caption.modulate = color
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func build_terrain(floor_mesh: MeshInstance3D) -> void:
	# Suelo real dividido alrededor del foso: la malla y la colisión tienen el mismo hueco.
	var floor_body := floor_mesh.get_parent()
	for child in floor_body.get_children():
		if child is CollisionShape3D: child.queue_free()
	floor_mesh.hide()
	for spec in [[Vector3(-18,-.5,0),Vector3(64,1,100)],[Vector3(37,-.5,0),Vector3(26,1,100)],[Vector3(19,-.5,-20),Vector3(10,1,60)],[Vector3(19,-.5,35),Vector3(10,1,30)]]:
		var slab := platform(spec[0],spec[1],Color("424c5b"))
		slab.get_child(0).material_override = floor_mesh.material_override
	# Extensión a 160 × 160 m sin tapar el foso ni cambiar las alturas anteriores.
	for spec in [[Vector3(-65,-.5,0),Vector3(30,1,160)],[Vector3(65,-.5,0),Vector3(30,1,160)],[Vector3(0,-.5,-65),Vector3(100,1,30)],[Vector3(0,-.5,65),Vector3(100,1,30)]]:
		var slab := platform(spec[0],spec[1],Color("424c5b"))
		slab.get_child(0).material_override = floor_mesh.material_override
	platform(Vector3(19,-6.5,15),Vector3(10,1,10),Color("292f3c"))
	ramp(Vector3(19,-5.98,11),Vector3(19,.04,21),3.4)
	ramp(Vector3(-17,.04,12),Vector3(-17,5.04,24),4.5)
	platform(Vector3(-17,4.75,27),Vector3(10,.5,6))
	for i in range(4): platform(Vector3(-10+i*2.8,5.25+i*.65,26),Vector3(2.4,.5,2.8),Color("3e4050"))
	platform(Vector3(0,7.5,26),Vector3(4,.5,5))
	# Elevador cinemático real: el controlador de Godot hereda su desplazamiento.
	lift = AnimatableBody3D.new(); lift.name = "TrainingLift"; add_child(lift)
	lift.position = Vector3(-27,.25,16); lift.sync_to_physics = true
	host.box(lift,Vector3(4.8,.4,4.8),Vector3.ZERO,Color("3b3a4a"))
	var shape := BoxShape3D.new(); shape.size = Vector3(4.8,.4,4.8)
	var collider := CollisionShape3D.new(); collider.shape = shape; lift.add_child(collider)
	host.glow_box(lift,Vector3(4.4,.025,4.4),Vector3(0,.21,0),Color("8aaec9"))
	platform(Vector3(-27,9.35,22),Vector3(7,.5,7))
	for spec in [[Vector3(5,.3,14),Vector3(3,.6,3)],[Vector3(8,1,17),Vector3(3,2,3)],[Vector3(10,2,20),Vector3(3,4,3)]]: platform(spec[0],spec[1])
	zone_sign("03 / ALTURAS\nRampa · saltos · recuperación",Vector3(-17,2.5,11),Color("d1bb89"))
	zone_sign("04 / DESNIVEL\nFoso -6 m",Vector3(24,2,10),Color("a5d4dc"))
	zone_sign("05 / ASCENSOR\nEspera · sube · salta",Vector3(-27,2,12),Color("c1a4ed"))

func _physics_process(delta: float) -> void:
	if host == null or host.paused: return
	if urban != null: urban.tick(delta)
	if lift == null: return
	lift_clock += delta
	var cycle := fmod(lift_clock,20.0)
	var height := .25
	if cycle > 3 and cycle < 9: height = lerpf(.25,9.35,smoothstep(3,9,cycle))
	elif cycle >= 9 and cycle < 12: height = 9.35
	elif cycle >= 12: height = lerpf(9.35,.25,smoothstep(12,18,cycle))
	lift.position.y = height

func visit_zone(id: String) -> void:
	if not zones.has(id): return
	host.reset_lab(); host.player.position = zones[id]; host.player.velocity = Vector3.ZERO
	if id == "lift" and lift != null: lift_clock = 0; lift.position.y = .25; lift.reset_physics_interpolation()
	host.player.reset_physics_interpolation(); host.camera_initialized = false
	host.set_paused(false)

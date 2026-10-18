extends Control
const Ink := preload("res://scripts/hud_ink.gd")
const CAPACITIES := [50.0,30.0,20.0]
const SELECTOR := [Vector2(18,112),Vector2(90,112),Vector2(54,154)]
var health := 100.0
var health_display := 100.0
var energy := 0.0
var phase := "BASE"
var states := [false,false,false,false]
var segments := [1.0,1.0,1.0]
var broken := [false,false,false]
var selector_key := "P"
var selector_pressed: Callable
var robot_viewport: SubViewport
var robot_portrait: TextureRect
var holographic := false
var holo_health: TextureProgressBar
var holo_energy: TextureProgressBar

func set_holographic(value: bool) -> void:
	if holo_health == null:
		holo_health = TextureProgressBar.new(); add_child(holo_health)
		holo_health.position = Vector2(120,57); holo_health.size = Vector2(384,38)
		holo_health.texture_under = preload("res://assets/ui/holo/bars/bar_smooth_track_256x32.svg")
		holo_health.texture_progress = preload("res://assets/ui/holo/bars/bar_smooth_fill_health_256x32.svg")
		holo_health.texture_over = preload("res://assets/ui/holo/bars/bar_smooth_frame_256x32.svg")
		holo_health.nine_patch_stretch = true; holo_health.min_value = -11.538; holo_health.max_value = 111.538
		holo_health.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holo_energy = TextureProgressBar.new(); add_child(holo_energy)
		holo_energy.position = Vector2(0,5); holo_energy.size = Vector2(108,108)
		holo_energy.texture_under = preload("res://assets/ui/holo/gauges/gauge_ring_track_128.svg")
		holo_energy.texture_progress = preload("res://assets/ui/holo/gauges/gauge_ring_fill_128.svg")
		holo_energy.texture_over = preload("res://assets/ui/holo/gauges/gauge_ring_frame_128.svg")
		holo_energy.fill_mode = TextureProgressBar.FILL_CLOCKWISE
		holo_energy.radial_initial_angle = 225; holo_energy.radial_fill_degrees = 270
		holo_energy.nine_patch_stretch = true; holo_energy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		move_child(holo_energy,0); move_child(holo_health,0)
	holographic = value; holo_health.visible = value; holo_energy.visible = value
	queue_redraw()

func clear_robot_portrait() -> void:
	if is_instance_valid(robot_portrait): remove_child(robot_portrait); robot_portrait.queue_free()
	if is_instance_valid(robot_viewport): remove_child(robot_viewport); robot_viewport.queue_free()
	robot_portrait = null; robot_viewport = null

func portrait_animator(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found := portrait_animator(child)
		if found != null: return found
	return null

func set_robot_portrait(scene: Node3D, scale_value: float, _model: int, height: float = 2.0) -> void:
	clear_robot_portrait()
	robot_viewport = SubViewport.new(); add_child(robot_viewport)
	robot_viewport.size = Vector2i(160,160); robot_viewport.transparent_bg = true
	robot_viewport.own_world_3d = true; robot_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var copy: Node3D = scene.duplicate(0); robot_viewport.add_child(copy)
	copy.scale = Vector3.ONE*scale_value; copy.rotation.y = 0; copy.process_mode = Node.PROCESS_MODE_DISABLED
	var animator := portrait_animator(copy)
	if animator != null:
		for name in animator.get_animation_list():
			if String(name).ends_with("Idle"):
				animator.play(name); animator.seek(.2,true); animator.advance(0); break
	var light := DirectionalLight3D.new(); robot_viewport.add_child(light)
	light.rotation_degrees = Vector3(-25,-25,0); light.light_energy = 1.8
	var camera := Camera3D.new(); robot_viewport.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = height*.775
	camera.position = Vector3(0,height*.75,4); camera.rotation.y = 0; camera.current = true
	var environment := WorldEnvironment.new(); robot_viewport.add_child(environment)
	environment.environment = Environment.new(); environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE; environment.environment.ambient_light_energy = .8
	robot_portrait = TextureRect.new(); add_child(robot_portrait)
	robot_portrait.position = Vector2(10,15); robot_portrait.size = Vector2(88,88)
	robot_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; robot_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	robot_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE; robot_portrait.texture = robot_viewport.get_texture()
	var shader := Shader.new(); shader.code = "shader_type canvas_item; void fragment(){ COLOR=texture(TEXTURE,UV); COLOR.a*=1.0-smoothstep(.48,.50,length(UV-vec2(.5))); }"
	var material := ShaderMaterial.new(); material.shader = shader; robot_portrait.material = material

func _ready() -> void:
	size = Vector2(510,174)
	mouse_filter = Control.MOUSE_FILTER_PASS
	tooltip_text = "P · Personaje\nEstados: caída, velocidad, forma y guardia."

func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point,PackedVector2Array(SELECTOR))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if selector_pressed.is_valid(): selector_pressed.call()
		accept_event()

func update_state(hp: float, power: float, form: String, flags: Array, key: String, delta: float) -> void:
	health = clampf(hp,0,100)
	health_display = lerpf(health_display,health,1-exp(-delta*18))
	if absf(health_display-health) < 0.05: health_display = health
	energy = clampf(power,0,100)
	if holo_health != null:
		holo_health.value = health_display; holo_energy.value = energy
	phase = form
	states = flags
	selector_key = key
	tooltip_text = "Elegir personaje · clic en el triángulo o "+key
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Se consume de derecha a izquierda: segmentos de 50, 30 y 20 HP.
	var preceding := 0.0
	for i in range(3):
		segments[i] = clampf((health-preceding)/CAPACITIES[i],0,1)
		broken[i] = segments[i] <= 0
		preceding += CAPACITIES[i]
	queue_redraw()

func bar_polygon(x: float, y: float, width: float, height: float = 23.0) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x+9,y),Vector2(x+width,y),Vector2(x+width-9,y+height),Vector2(x,y+height)])

func draw_model() -> Array:
	var result: Array = [Ink.circle(Vector2(54,59),45,Color("121b29ed"),true),Ink.circle(Vector2(54,59),45,Ink.PAPER,false,2.0)]
	if robot_viewport == null: result.append_array(Ink.fit(Ink.drawing("kogane"),Rect2(17,19,74,78)))
	result.append(Ink.polygon(PackedVector2Array(SELECTOR),Ink.GOLD))
	for i in range(4):
		var center := Vector2(151+i*63,26)
		var color := Ink.MINT if states[i] else Color("6d7f94")
		result.append(Ink.circle(center,17,Color("182839"),true))
		result.append(Ink.circle(center,17,color,false,1.8))
		var symbol: Array = Ink.fit(Ink.drawing(["fall","motion","form","guard"][i]),Rect2(center-Vector2(11,11),Vector2(22,22)))
		for command in symbol: command.color = color
		result.append_array(symbol)
		result.append(Ink.polygon(PackedVector2Array([center+Vector2(-12,23),center+Vector2(12,23),center+Vector2(7,29),center+Vector2(-7,29)]),color))
	var starts := [122.0,320.0,430.0]
	var widths := [190.0,102.0,74.0]
	var preceding := 0.0
	for i in range(3):
		var shape := bar_polygon(starts[i],65,widths[i])
		result.append(Ink.polygon(shape,Color("273443")))
		var displayed := clampf((health_display-preceding)/CAPACITIES[i],0,1)
		if displayed > 0:
			var clip := PackedVector2Array([Vector2(starts[i]-1,64),Vector2(starts[i]+widths[i]*displayed,64),Vector2(starts[i]+widths[i]*displayed,89),Vector2(starts[i]-1,89)])
			for part in Geometry2D.intersect_polygons(shape,clip):
				# Un relleno casi agotado puede colapsar al recortar el polígono.
				if not Geometry2D.triangulate_polygon(part).is_empty(): result.append(Ink.polygon(part,Ink.MINT))
		var edge: PackedVector2Array = shape.duplicate()
		edge.append(shape[0])
		result.append({"type":"line","points":edge,"color":Color("697586") if broken[i] else Ink.PAPER,"width":1.8})
		if broken[i]:
			var x: float = starts[i]+widths[i]*0.55
			result.append(Ink.path([[x+2,65],[x-5,72],[x+4,77],[x-4,88]],Ink.GOLD,2.3))
		preceding += CAPACITIES[i]
	var energy_shape := bar_polygon(126,124,374,7)
	result.append(Ink.polygon(energy_shape,Color("273443")))
	if energy > 0:
		var clip := PackedVector2Array([Vector2(126,123),Vector2(126+374*energy/100,123),Vector2(126+374*energy/100,132),Vector2(126,132)])
		for part in Geometry2D.intersect_polygons(energy_shape,clip):
			if not Geometry2D.triangulate_polygon(part).is_empty(): result.append(Ink.polygon(part,Ink.GOLD))
	return result

func _draw() -> void:
	if not holographic: Ink.paint(self,draw_model()); return
	var cyan := Color("64e7ff")
	draw_style_box(holo_panel(),Rect2(113,3,393,165))
	draw_circle(Vector2(54,59),44,Color(.015,.065,.09,.88))
	draw_arc(Vector2(54,59),48,0,TAU,64,cyan*.55,1.2,true)
	draw_colored_polygon(PackedVector2Array(SELECTOR),cyan)
	for i in range(4):
		var center := Vector2(151+i*63,26)
		var color := cyan if states[i] else Color("467281")
		Ink.paint(self,Ink.fit(Ink.drawing(["fall","motion","form","guard"][i]),Rect2(center-Vector2(11,11),Vector2(22,22))))
		draw_line(center+Vector2(-14,16),center+Vector2(14,16),color,2,true)
	# Ultimate line remains readable independently of the circular meter.
	draw_line(Vector2(126,130),Vector2(500,130),Color("163846"),4,true)
	draw_line(Vector2(126,130),Vector2(126+374*energy/100,130),cyan,3,true)

func holo_panel() -> StyleBoxFlat:
	var skin := StyleBoxFlat.new(); skin.bg_color = Color(.015,.055,.075,.78)
	skin.border_color = Color(.22,.72,.86,.5); skin.set_border_width_all(1); skin.border_width_left = 2
	return skin

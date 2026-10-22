extends Control
const Options = preload("res://ui/warfare_options.gd")
const Visual = preload("res://units/soldiers/soldier_visual.gd")
var page: VBoxContainer
var preview: SubViewport
var preview_container: SubViewportContainer
var menu_scroll: ScrollContainer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	var background := ColorRect.new()
	background.color = Color("0a151b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+edge,32)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",32)
	margin.add_child(columns)
	menu_scroll = ScrollContainer.new()
	menu_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.custom_minimum_size.x = 340
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(menu_scroll)
	page = VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation",14)
	menu_scroll.add_child(page)
	preview_container = SubViewportContainer.new()
	preview_container.stretch = true
	preview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columns.add_child(preview_container)
	preview = SubViewport.new()
	preview.size = Vector2i(500,600)
	preview.own_world_3d = true
	preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview_container.add_child(preview)
	var soldier := Visual.new()
	preview.add_child(soldier)
	soldier.rotation.y = PI-0.35
	var camera := Camera3D.new()
	preview.add_child(camera)
	camera.position = Vector3(0,1.20,3.1)
	camera.look_at(Vector3(0,0.93,0))
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35,-25,0)
	light.light_energy = 2.0
	preview.add_child(light)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("10232b")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("afcbd0")
	world.environment.ambient_light_energy = 0.7
	preview.add_child(world)
	resized.connect(_layout)
	_layout()
	show_home()

func _layout() -> void:
	preview_container.visible = size.x>=760
	preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS if preview_container.visible else SubViewport.UPDATE_DISABLED
	menu_scroll.custom_minimum_size.x = minf(340,maxf(240,size.x-64))

func clear_page() -> void:
	for child in page.get_children():
		page.remove_child(child)
		child.queue_free()

func label(text: String,size: int = 18) -> void:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size",size)
	page.add_child(item)

func button(text: String,callback: Callable,disabled: bool = false) -> void:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size.y = 44
	item.disabled = disabled
	page.add_child(item)
	if callback.is_valid(): item.pressed.connect(callback)

func show_home() -> void:
	clear_page()
	label("WARFARE:",48)
	label("DISTRICT500",32)
	label("PRÁCTICA DE INFANTERÍA  /  "+BuildInfo.version,14)
	button("JUGAR",start_practice)
	button("PRÁCTICA",start_practice)
	button("SELECCIÓN DE UNIDAD",show_units)
	button("OPCIONES",show_options)
	button("SALIR",func() -> void: get_tree().quit())
	label("WASD · movimiento    V · FPS / TPS\nShift · carrera    Ctrl · agacharse\nEspacio · salto    Esc · pausa",15)

func show_units() -> void:
	clear_page()
	label("SELECCIÓN DE UNIDAD",26)
	label("Soldado · Destacamento Aurora",19)
	button("DESPLEGAR SOLDADO",start_practice)
	label("Junkyard Sentinel · integración pendiente",15)
	button("MEGA MECHA · PRÓXIMAMENTE",Callable(),true)
	button("VOLVER",show_home)

func show_options() -> void:
	clear_page()
	page.add_child(Options.new())
	button("VOLVER",show_home)

func start_practice() -> void:
	var error := get_tree().change_scene_to_file("res://game_modes/warfare_practice.tscn")
	if error!=OK: push_error("Cannot enter practice: "+error_string(error))

extends CanvasLayer
const Options = preload("res://ui/warfare_options.gd")
var game: Node3D
var status: Label
var details: Label
var pause_panel: PanelContainer
var metrics: Label
var interval := 0.0

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	var frame := Control.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	var top_backing := ColorRect.new()
	top_backing.color = Color(0.025,0.055,0.065,0.85)
	top_backing.position = Vector2(12,12)
	top_backing.size = Vector2(360,68)
	top_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(top_backing)
	status = Label.new()
	status.position = Vector2(24,20)
	status.add_theme_font_size_override("font_size",20)
	frame.add_child(status)
	var bottom_backing := ColorRect.new()
	bottom_backing.color = Color(0.025,0.055,0.065,0.85)
	bottom_backing.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_backing.offset_left = 12
	bottom_backing.offset_right = -12
	bottom_backing.offset_top = -90
	bottom_backing.offset_bottom = -12
	bottom_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(bottom_backing)
	details = Label.new()
	details.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	details.position = Vector2(24,-80)
	details.add_theme_font_size_override("font_size",16)
	frame.add_child(details)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -5
	crosshair.offset_top = -13
	crosshair.modulate = Color("a9dbd5")
	frame.add_child(crosshair)
	metrics = Label.new()
	metrics.position = Vector2(24,110)
	metrics.hide()
	frame.add_child(metrics)
	pause_panel = PanelContainer.new()
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pause_panel.offset_left = -200
	pause_panel.offset_right = 200
	pause_panel.offset_top = -310
	pause_panel.offset_bottom = 310
	frame.add_child(pause_panel)
	var rows := VBoxContainer.new()
	pause_panel.add_child(rows)
	var title := Label.new()
	title.text = "WARFARE:DISTRICT500 · PAUSA"
	rows.add_child(title)
	add_button(rows,"CONTINUAR",toggle_pause)
	rows.add_child(Options.new())
	add_button(rows,"REAPARECER",func() -> void: game.respawn(); toggle_pause())
	add_button(rows,"MENÚ PRINCIPAL",game.return_to_menu)
	pause_panel.hide()

func add_button(parent: Node,text: String,callback: Callable) -> void:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size.y = 34
	parent.add_child(item)
	item.pressed.connect(callback)

func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_panel.visible = get_tree().paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if get_tree().paused else Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_ESCAPE:
			toggle_pause()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode==KEY_F3: metrics.visible = not metrics.visible
		elif event.physical_keycode==KEY_F9: game.recorder.begin()

func _process(delta: float) -> void:
	interval -= delta
	if interval>0: return
	interval = 0.15
	var player: CharacterBody3D = game.player
	status.text = "AURORA / DISTRITO 500\nPRÁCTICA · "+player.view.mode_label()
	details.text = "SALUD %d / %d   ·   EQUIPO: ENLACE DE MUÑECA\nV · vista   B · hombro   Shift · carrera   Alt · caminar\nCtrl · agacharse   Espacio · salto   Esc · pausa" % [player.health.current,player.health.maximum]
	if not player.health.alive: details.text = "FUERA DE COMBATE · REAPARICIÓN EN CURSO"
	if metrics.visible:
		var sample: Dictionary = game.recorder.snapshot()
		metrics.text = "%s  |  %d FPS\nCPU proceso %.2f ms · física %.2f ms\nNodos %d · memoria estática %.1f MB\nF9 · registrar 60 s%s" % [BuildInfo.version,sample.fps,sample.process_ms,sample.physics_ms,sample.nodes,sample.static_memory_bytes/1048576.0," · REGISTRANDO" if game.recorder.remaining>0 else ""]

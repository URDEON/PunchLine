extends PanelContainer
## Shared menu/pause accessibility controls. Changes apply to the live camera.
func _ready() -> void:
	custom_minimum_size.x = 340
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation",10)
	add_child(rows)
	var title := Label.new()
	title.text = "CÁMARA Y PANTALLA"
	rows.add_child(title)
	for field in [["fov","Campo de visión",65.0,110.0,1.0],
		["sensitivity","Sensibilidad",0.0005,0.008,0.0001],
		["distance","Distancia TPS",1.8,5.0,0.1],
		["shake","Intensidad de movimiento",0.0,1.0,0.05],
		["grass_quality","Vegetación (0–3)",0,3,1],
		["fog_amount","Niebla",0.0,1.0,0.05]]:
		var line := HBoxContainer.new()
		rows.add_child(line)
		var label := Label.new()
		label.text = field[1]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(label)
		var value := SpinBox.new()
		value.min_value = field[2]
		value.max_value = field[3]
		value.step = field[4]
		value.value = WarfareSettings.values[field[0]]
		line.add_child(value)
		value.value_changed.connect(_number_changed.bind(field[0]))
	for field in [["bodycam","Movimiento bodycam"],["bob","Balanceo al caminar"],
		["invert_y","Invertir eje vertical"],["lens","Distorsión de lente (opcional)"],
		["fullscreen","Pantalla completa"]]:
		var toggle := CheckButton.new()
		toggle.text = field[1]
		toggle.button_pressed = bool(WarfareSettings.values[field[0]])
		rows.add_child(toggle)
		toggle.toggled.connect(_toggle_changed.bind(field[0]))

func _number_changed(value: float,key: String) -> void:
	WarfareSettings.set_value(key,int(value) if key=="grass_quality" else value)

func _toggle_changed(value: bool,key: String) -> void:
	WarfareSettings.set_value(key,value)

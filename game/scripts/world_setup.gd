extends VBoxContainer
signal start_requested(settings:Dictionary)
var seed_edit:LineEdit
var density:OptionButton
var night:CheckButton
func _ready()->void:
	add_theme_constant_override("separation",10)
	var heading:=Label.new();heading.text="CONFIGURAR MUNDO";heading.add_theme_font_size_override("font_size",22);add_child(heading)
	var saved:Dictionary=preload("res://scripts/world_config.gd").remembered()
	var label:=Label.new();label.text="Semilla del mundo";add_child(label)
	var row:=HBoxContainer.new();add_child(row)
	seed_edit=LineEdit.new();seed_edit.text=String(saved.seed);seed_edit.max_length=48;seed_edit.placeholder_text="Número o texto";seed_edit.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(seed_edit)
	var random:=Button.new();random.text="ALEATORIA";row.add_child(random)
	random.pressed.connect(func()->void:seed_edit.text=str(randi_range(1,2147483647)))
	label=Label.new();label.text="Densidad de edificios";add_child(label)
	density=OptionButton.new();density.add_item("Espaciado");density.add_item("Equilibrado");density.add_item("Completo");density.selected=clampi(int(saved.density),0,2);add_child(density)
	night=CheckButton.new();night.text="Mundo nocturno";night.button_pressed=bool(saved.night);add_child(night)
	label=Label.new();label.text="La misma semilla y densidad producen las mismas casas. Las calles conservan el plano District500.";label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",13);add_child(label)
	var start:=Button.new();start.text="CREAR MUNDO Y JUGAR";start.custom_minimum_size.y=46;add_child(start)
	start.pressed.connect(func()->void:start.disabled=true;start.text="PREPARANDO MUNDO…";start_requested.emit({"seed":seed_edit.text,"density":density.selected,"night":night.button_pressed}))

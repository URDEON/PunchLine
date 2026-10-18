extends Control
var content: VBoxContainer
var buttons: Array[Button] = []
var portrait: SubViewportContainer
var title: Label
var subtitle: Label
var status: Label
var column: VBoxContainer
var current_page := "home"
var motion := 1.0
var transitioning := false
var fade: Tween
var ui_voice: AudioStreamPlayer
var profile: Node3D
var extras:Control
var quit_dialog:ConfirmationDialog
var power_button:Button
var world_setup:VBoxContainer
func _ready() -> void:
    var args := OS.get_cmdline_user_args()
    if args.has("--online"): get_tree().change_scene_to_file.call_deferred("res://network/online.tscn"); return
    if args.has("--individual"): get_tree().change_scene_to_file.call_deferred("res://main.tscn"); return
    profile=preload("res://scripts/frontend_settings_host.gd").new();add_child(profile)
    get_tree().auto_accept_quit=false
    var config := ConfigFile.new()
    if config.load("user://preferences_v09.cfg") == OK: motion = float(config.get_value("settings","ui_motion",1.0))
    Engine.set_meta("punchline_ui_motion",motion)
    ui_voice = AudioStreamPlayer.new(); add_child(ui_voice); ui_voice.volume_db = -18
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var background := preload("res://scripts/menu_backdrop.gd").new(); add_child(background); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    portrait = preload("res://scripts/menu_portrait.gd").new(); add_child(portrait); portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); portrait.anchor_left = .43
    column = VBoxContainer.new(); add_child(column); column.add_theme_constant_override("separation",14)
    title = Label.new(); title.text = "PUNCHLINE"; title.add_theme_font_size_override("font_size",52); title.modulate = Color("dbe5df"); column.add_child(title)
    subtitle = Label.new(); subtitle.text = "THE PROYECTED / PROYECCIÓN Y ACERO"; subtitle.add_theme_font_size_override("font_size",13); subtitle.modulate = Color("9db4b3"); column.add_child(subtitle)
    content = VBoxContainer.new(); column.add_child(content); content.add_theme_constant_override("separation",8)
    status = Label.new(); column.add_child(status); status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; status.add_theme_font_size_override("font_size",12); status.modulate = Color("97abaa")
    power_button=Button.new();power_button.text="⏻";power_button.tooltip_text="Cerrar PunchLine";power_button.position=Vector2(18,14);power_button.size=Vector2(42,42);power_button.add_theme_font_size_override("font_size",27);add_child(power_button);power_button.pressed.connect(request_quit)
    quit_dialog=ConfirmationDialog.new();quit_dialog.title="Cerrar PunchLine";quit_dialog.dialog_text="¿Estás seguro de que quieres cerrar el juego?";quit_dialog.ok_button_text="Cerrar juego";quit_dialog.cancel_button_text="Seguir jugando";quit_dialog.confirmed.connect(func()->void:get_tree().quit());add_child(quit_dialog)
    get_viewport().size_changed.connect(resize_menu); page("home"); resize_menu()
func choice(text: String,callback: Callable) -> void:
    var button: Button = preload("res://scripts/ink_button.gd").new(); content.add_child(button); button.text = text; button.tooltip_text = text; button.custom_minimum_size.y = 49; button.add_theme_font_size_override("font_size",17); button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.pressed.connect(func() -> void:
        ui_voice.stream = preload("res://assets/audio/v098/ui/click1.ogg"); ui_voice.play(); callback.call())
    button.mouse_entered.connect(func() -> void: ui_voice.stream = preload("res://assets/audio/v098/ui/rollover1.ogg"); ui_voice.play())
    buttons.append(button)
func page(id: String) -> void:
    current_page = id
    for child in content.get_children(): content.remove_child(child); child.queue_free()
    buttons.clear()
    if is_instance_valid(extras):extras.queue_free();extras=null
    column.visible=id!="extras";portrait.visible=id=="home"
    if id=="home":
        choice("DEMO",func()->void:page("world"))
        choice("MULTIJUGADOR",func()->void:enter("res://network/online.tscn"))
        choice("AJUSTES",func()->void:page("settings"))
        choice("EXTRAS",func()->void:page("extras"))
        status.text="0.9.24 / THE PROYECTED Y ACERO VIVO"
    elif id=="world":
        var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.custom_minimum_size.y=maxf(100,get_viewport_rect().size.y-300);content.add_child(scroll)
        world_setup=preload("res://scripts/world_setup.gd").new();world_setup.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(world_setup)
        world_setup.start_requested.connect(func(settings:Dictionary)->void:preload("res://scripts/world_config.gd").select(settings);enter("res://main.tscn"))
        choice("VOLVER",func()->void:page("home"));status.text="Elige cómo será tu próxima partida."
    elif id=="settings":
        var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.custom_minimum_size.y=maxf(100,get_viewport_rect().size.y-300);content.add_child(scroll)
        var settings=preload("res://scripts/settings_panel.gd").new();settings.preferences=profile.preferences;scroll.add_child(settings)
        choice("VOLVER",func()->void:page("home"));status.text="Los cambios se guardan y se aplican dentro de la partida."
    elif id=="extras":
        extras=preload("res://scripts/extras_browser.gd").new();add_child(extras);extras.close_requested.connect(func()->void:page("home"));extras.demo_requested.connect(enter)
    else:page("home");return
    if fade != null: fade.kill()
    content.modulate.a = 0; fade = create_tween(); fade.tween_property(content,"modulate:a",1.0,.22*motion+.001)
    resize_menu()
    if not buttons.is_empty(): buttons[0].grab_focus()
func resize_menu() -> void:
    var extent := get_viewport_rect().size
    column.position = Vector2(maxf(18,(extent.x-minf(920 if current_page=="settings" else 540,extent.x-36))*.5),36 if extent.y<500 else 58) if current_page in ["settings","world"] else Vector2(maxf(18,extent.x*.08),maxf(60 if extent.y<500 else 70,(extent.y-minf(510,extent.y-24))*.5))
    column.size.x = minf(920 if current_page=="settings" else 440,extent.x-36); column.custom_minimum_size.x = minf(340,extent.x-36)
    var compact := extent.y < 500
    column.add_theme_constant_override("separation",5 if compact else 14)
    title.add_theme_font_size_override("font_size",34 if compact else 52)
    status.add_theme_font_size_override("font_size",10 if compact else 12)
    for child in content.get_children():
        if child is Label: child.add_theme_font_size_override("font_size",11 if compact else 15)
    for button in buttons:
        button.custom_minimum_size.y = 37 if compact else 49
        button.add_theme_font_size_override("font_size",14 if compact else 17)
    portrait.visible = current_page=="home" and extent.x > 720 and not compact
func enter(scene: String) -> void:
    if transitioning: return
    transitioning = true
    var transition := create_tween(); transition.tween_property(self,"modulate:a",0.0,.25*motion+.001)
    transition.finished.connect(func() -> void: get_tree().change_scene_to_file(scene))
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and current_page != "home": page("home")

func request_quit()->void:
 quit_dialog.popup_centered(Vector2i(mini(420,int(get_viewport_rect().size.x)-24),150))
func _notification(what:int)->void:
 if what==NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(quit_dialog):request_quit()
func _exit_tree()->void:
 if is_inside_tree():get_tree().auto_accept_quit=true

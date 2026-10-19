extends Node3D
const SESSION = preload("res://network/session.gd")
var session: Node
var actor_root: Node3D
var map: Node3D
var camera_view = preload("res://scripts/body_camera.gd").new()
var camera: Camera3D
var preferences: Node = preload("res://scripts/preferences.gd").new()
var interface: CanvasLayer # Las preferencias comunes admiten interfaz opcional.
var zoom := 5.5
var yaw := 0.0
var pitch := -.24
var menu_open := true
var ui: CanvasLayer
var panel: PanelContainer
var panel_scroll: ScrollContainer
var name_field: LineEdit
var rename_button: Button
var ip_field: LineEdit
var port_field: SpinBox
var character_choice: OptionButton
var host_button: Button
var join_button: Button
var resume_button: Button
var leave_button: Button
var character_button: Button
var status_label: Label
var roster_label: Label
var hud: Label
var health: ProgressBar
var hit_indicator: Label
var hit_flash := 0.0
var last_hit := ""
var hit_notice_time := 0.0
var camera_initialized := false
var camera_generation := -1
var camera_target := Vector3.ZERO
var send_timer := 0.0
var message_text := "Tres jugadores · crea una partida o escribe la IP del anfitrión."
var voices: Array[AudioStreamPlayer3D] = []
var audio_bank = preload("res://scripts/combat_audio_bank.gd").new()
var voice_index := 0
var numbers: Array[Dictionary] = []
var telemetry := {"rendered_players":0}

var world_settings:Dictionary=preload("res://scripts/world_config.gd").current()
var seed_field:LineEdit
var density_field:OptionButton
var night_field:CheckButton
var destructible_field:CheckButton

func _ready() -> void:
	name = "OnlineArena"
	add_child(preferences); preferences.setup(self)
	actor_root = Node3D.new(); actor_root.name = "Players"; add_child(actor_root)
	map = preload("res://scripts/punchline_map.gd").new(); map.name = "PunchLine"; add_child(map)
	# Colisiones y materiales del mismo recurso editable utilizado en la 0.9.10.
	map.setup(self)
	var sunlight := DirectionalLight3D.new(); sunlight.name="ArenaSun"; sunlight.rotation_degrees = Vector3(-55,-30,0)
	sunlight.light_color = Color("fff0dc"); sunlight.light_energy = 1.05; sunlight.shadow_enabled = true; add_child(sunlight)
	var world := WorldEnvironment.new(); world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_SKY
	world.name = "ArenaEnvironment"
	var sky := Sky.new(); var sky_material := PanoramaSkyMaterial.new()
	sky_material.panorama = preload("res://assets/environment/v098/sky/skybox-morning.png")
	sky_material.filter = true; sky.sky_material = sky_material; world.environment.sky = sky
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("a7bbd4"); world.environment.ambient_light_energy = .42; add_child(world)
	map.ambience.configure_environment(world.environment,bool(world_settings.night))
	camera = Camera3D.new(); camera.current = true; camera.near = .12; camera.fov = preferences.values.fov
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF; add_child(camera)
	camera.position = Vector3(0,20,36); camera.look_at(Vector3.ZERO)
	session = SESSION.new(); session.name = "Session"; add_child(session); session.setup(self)
	session.message.connect(func(value: String) -> void: message_text = value; refresh_ui())
	session.changed.connect(refresh_ui)
	if OS.get_cmdline_user_args().has("--network-log"):
		session.message.connect(func(value: String) -> void: print("NET MESSAGE ",value))
		session.changed.connect(func() -> void: print("NET PLAYERS ",session.roster.size()," ACTIVE ",session.active))
	for index in range(8):
		var voice := AudioStreamPlayer3D.new(); voice.bus = "Combat"; voice.max_distance = 40; voice.unit_size = 8; voice.volume_db = -8
		add_child(voice); voices.append(voice)
	build_ui(); refresh_ui(); startup_arguments.call_deferred()

func startup_arguments() -> void:
	var args := OS.get_cmdline_user_args()
	var requested_port: int = session.DEFAULT_PORT; var requested_name := name_field.text; var requested_ip := ""
	for arg in args:
		if arg.begins_with("--port="): requested_port = int(arg.trim_prefix("--port="))
		if arg.begins_with("--nickname="): requested_name = arg.trim_prefix("--nickname=")
		if arg.begins_with("--join="): requested_ip = arg.trim_prefix("--join=")
	name_field.text = requested_name; port_field.value = requested_port
	character_choice.selected = 1 if args.has("--robot") else 0
	await get_tree().physics_frame; await get_tree().physics_frame
	if args.has("--host"): session.host_game(requested_name,character_choice.selected,requested_port)
	elif not requested_ip.is_empty(): ip_field.text = requested_ip; session.join_game(requested_ip,requested_port,requested_name,character_choice.selected)

func spawn_for(slot: int) -> Vector3:
	# Aparición protegida del District500 vectorial, compartida con el anfitrión.
	var point: Vector3 = map.player_spawns[posmod(slot,map.player_spawns.size())].global_position
	var ray := PhysicsRayQueryParameters3D.create(point+Vector3.UP*8,point-Vector3.UP*12,1)
	var result := get_world_3d().direct_space_state.intersect_ray(ray)
	return Vector3(point.x,float(result.position.y)+.06,point.z) if not result.is_empty() else point+Vector3.UP

func box_style(color: Color, border: Color, radius: int = 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = color; style.border_color = border
	style.set_border_width_all(1); style.set_corner_radius_all(radius)
	style.content_margin_left = 18; style.content_margin_right = 18; style.content_margin_top = 12; style.content_margin_bottom = 12
	return style

func label(text_value: String, size: int = 16) -> Label:
	var node := Label.new(); node.text = text_value; node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",Color("eef0f8")); node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node

func button(text_value: String, callback: Callable) -> Button:
	var node := preload("res://scripts/ink_button.gd").new(); node.text = text_value; node.custom_minimum_size.y = 44
	node.clip_text = true; node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	node.add_theme_font_size_override("font_size",16)
	node.add_theme_stylebox_override("normal",box_style(Color("222738"),Color("434a62")))
	node.add_theme_stylebox_override("hover",box_style(Color("343b52"),Color("baabed")))
	node.add_theme_stylebox_override("pressed",box_style(Color("161b28"),Color("86d7c2")))
	node.pressed.connect(callback); return node

func build_ui() -> void:
	ui = CanvasLayer.new(); ui.layer = 20; add_child(ui)
	var screen := Control.new(); ui.add_child(screen); screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop := preload("res://scripts/menu_backdrop.gd").new(); screen.add_child(backdrop); backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.set_meta("lobby_background",true)
	var hud_panel := PanelContainer.new(); screen.add_child(hud_panel); hud_panel.position = Vector2(16,16)
	hud_panel.custom_minimum_size.x = 290; hud_panel.add_theme_stylebox_override("panel",box_style(Color(.06,.075,.12,.86),Color("5c607a")))
	var hud_column := VBoxContainer.new(); hud_panel.add_child(hud_column)
	hud = label("PUNCHLINE · ONLINE",17); hud_column.add_child(hud)
	health = ProgressBar.new(); health.show_percentage = false; health.custom_minimum_size = Vector2(250,10)
	health.add_theme_stylebox_override("fill",box_style(Color("86d7c2"),Color("86d7c2"),3)); hud_column.add_child(health)
	var menu_button := button("PARTIDA · ESC",toggle_menu); hud_column.add_child(menu_button)
	hud_panel.hide()
	hit_indicator = label("",25); screen.add_child(hit_indicator); hit_indicator.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hit_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = PanelContainer.new(); screen.add_child(panel)
	panel.add_theme_stylebox_override("panel",box_style(Color(.025,.045,.055,.95),Color("566c6b"),0))
	panel_scroll = ScrollContainer.new(); panel.add_child(panel_scroll); panel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column := VBoxContainer.new(); panel_scroll.add_child(column); column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",9)
	column.add_child(label("PUNCHLINE / CONEXIÓN",29))
	column.add_child(label(BuildInfo.version+" · ANFITRIÓN + DOS AMIGOS",13))
	status_label = label(message_text,14); column.add_child(status_label)
	column.add_child(label("Tu nombre",13)); name_field = LineEdit.new(); name_field.text = load_nickname(); name_field.max_length = 20; name_field.placeholder_text = "Escribe tu nombre"; column.add_child(name_field)
	name_field.text_changed.connect(func(value: String) -> void: save_nickname(value))
	rename_button = button("GUARDAR NOMBRE EN LA PARTIDA",func() -> void: session.local_name(name_field.text)); column.add_child(rename_button)
	column.add_child(label("Personaje",13)); character_choice = OptionButton.new(); character_choice.clip_text = true; character_choice.add_item("The Proyected"); character_choice.add_item("Robot · chasis aleatorio al reaparecer"); column.add_child(character_choice)
	column.add_child(label("IP del anfitrión · Radmin VPN o red local",13)); ip_field = LineEdit.new(); ip_field.placeholder_text = "Ejemplo: 26.12.34.56"; column.add_child(ip_field)
	var port_row := HBoxContainer.new(); column.add_child(port_row); port_row.add_child(label("Puerto UDP",13))
	port_field = SpinBox.new(); port_field.min_value = 1024; port_field.max_value = 65535; port_field.value = session.DEFAULT_PORT; port_row.add_child(port_field)
	column.add_child(label("MUNDO DEL ANFITRIÓN",17))
	seed_field=LineEdit.new();seed_field.text=String(world_settings.seed);seed_field.max_length=48;seed_field.placeholder_text="Semilla";column.add_child(seed_field)
	column.add_child(button("SEMILLA ALEATORIA",func()->void:
		if not session.active and not session.connecting:seed_field.text=str(randi_range(1,2147483647))))
	density_field=OptionButton.new()
	for text in ["Espaciado","Equilibrado","Completo"]:density_field.add_item(text)
	density_field.selected=int(world_settings.density);column.add_child(density_field)
	night_field=CheckButton.new();night_field.text="Mundo nocturno";night_field.button_pressed=bool(world_settings.night);column.add_child(night_field)
	destructible_field=CheckButton.new();destructible_field.text="Edificios destructibles";destructible_field.button_pressed=bool(world_settings.destructible);column.add_child(destructible_field)
	host_button = button("CREAR PARTIDA",func() -> void:
		preload("res://scripts/world_config.gd").select({"seed":seed_field.text,"density":density_field.selected,"night":night_field.button_pressed,"destructible":destructible_field.button_pressed})
		var error: Error = session.host_game(name_field.text,character_choice.selected,int(port_field.value))
		if error != OK: message_text = "No se pudo crear: "+error_string(error); refresh_ui())
	column.add_child(host_button)
	join_button = button("UNIRSE POR IP",func() -> void:
		var error: Error = session.join_game(ip_field.text,int(port_field.value),name_field.text,character_choice.selected)
		if error != OK: message_text = "Revisa la IP y el puerto: "+error_string(error); refresh_ui())
	column.add_child(join_button)
	character_button = button("REAPARECER CON PERSONAJE ELEGIDO",func() -> void: session.local_character(character_choice.selected)); column.add_child(character_button)
	roster_label = label("",14); column.add_child(roster_label)
	resume_button = button("VOLVER A LA PARTIDA · ESC",toggle_menu); column.add_child(resume_button)
	leave_button = button("DESCONECTAR / CANCELAR CONEXIÓN",func() -> void: session.leave()); column.add_child(leave_button)
	if true:
		column.add_child(button("VOLVER AL MODO INDIVIDUAL",func() -> void: session.leave(); get_tree().change_scene_to_file("res://main.tscn")))
	column.add_child(button("SALIR · MENÚ PRINCIPAL",func() -> void: session.leave(); get_tree().change_scene_to_file.call_deferred("res://launcher.tscn")))
	column.add_child(label("WASD · Ctrl caminar · Espacio saltar · Q dash · Clic M1 · F bloquear · P personaje · Rueda zoom.\nAbrir este menú no detiene la partida.\n1–4 habilidades · G transformación · B emotes · K Kogane. El laboratorio individual incluye las pruebas y los enemigos de entrenamiento.",13))
	get_viewport().size_changed.connect(resize_ui); resize_ui()

func resize_ui() -> void:
	var size := get_viewport().get_visible_rect().size
	var extent := Vector2(minf(570,size.x-24),minf(690,size.y-24))
	panel_scroll.custom_minimum_size = Vector2(maxf(180,extent.x-38),maxf(150,extent.y-26))
	panel.position = (size-extent)*.5; panel.set_deferred("size",extent)

func refresh_ui() -> void:
	if panel == null: return
	var busy: bool = session.active or session.connecting
	host_button.visible = not busy; join_button.visible = not busy
	name_field.editable = true; rename_button.visible = session.active; ip_field.editable = not busy; port_field.editable = not busy
	resume_button.visible = session.actors.has(session.local_id())
	character_button.visible = resume_button.visible; leave_button.visible = busy
	seed_field.editable=not busy;density_field.disabled=busy;night_field.disabled=busy;destructible_field.disabled=busy
	status_label.text = message_text
	var lines := PackedStringArray()
	for spec in session.roster.values():
		lines.append("%s · %s%s" % [spec.nickname,"The Proyected" if int(spec.character) == 0 else ["Leela","Stan","George","Mike"][int(spec.variant)]," · anfitrión" if int(spec.id) == 1 else ""])
	roster_label.text = "JUGADORES %d/3\n" % session.roster.size()+"\n".join(lines)
	panel.visible = menu_open
	for child in panel.get_parent().get_children():
		if child.has_meta("lobby_background"): child.visible = menu_open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if menu_open else Input.MOUSE_MODE_CAPTURED
	if not session.actors.has(session.local_id()): camera_initialized = false; camera_generation = -1

func toggle_menu() -> void:
	if not session.actors.has(session.local_id()): menu_open = true
	else: menu_open = not menu_open
	refresh_ui()
	# Soltar el ataque y la guardia inmediatamente al abrir la interfaz.
	if menu_open: session.local_input(Vector2.ZERO,yaw,0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ALT and not menu_open and session.actors.has(session.local_id()):
		var current: Node3D = session.actors[session.local_id()]
		current.hud_cursor = event.pressed; Input.mouse_mode = current.hud_mouse_mode(); return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if menu_open: toggle_menu()
			elif session.actors.has(session.local_id()):
				var local_actor: Node3D = session.actors[session.local_id()]
				if local_actor.menu_blocked: local_actor.set_paused(false)
				else: local_actor.interface.open_menu("online")
			return
		if event.keycode == KEY_V and not menu_open and not preferences.bindings.values().has(KEY_V):
			zoom = maxf(2.0,float(preferences.values.camera_distance)) if zoom <= .55 else 0.0; return
		if event.is_action_pressed("character") and not menu_open and session.actors.has(session.local_id()): session.actors[session.local_id()].interface.toggle_character(); return
	if menu_open: return
	var actor: Node3D = session.actors.get(session.local_id())
	if actor == null: return
	if event.is_action_released("ability1"): session.local_action("cannon_release")
	if actor.menu_blocked or actor.fusion.cinematic: return
	if event is InputEventMouseMotion:
		if actor.hud_cursor: return
		yaw = wrapf(yaw-event.relative.x*.003*float(preferences.values.sensitivity),-PI,PI)
		var body_view:bool=zoom<=.55
		pitch = clampf(pitch-event.relative.y*.003*float(preferences.values.sensitivity),-1.35 if body_view else -1.05,1.35 if body_view else .25)
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if not actor.hud_cursor: session.local_action("attack")
			MOUSE_BUTTON_MIDDLE: session.local_action("lock")
			MOUSE_BUTTON_WHEEL_UP: zoom = maxf(0,zoom-.4)
			MOUSE_BUTTON_WHEEL_DOWN: zoom = minf(10,zoom+.4)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("interact"):session.local_action("interact");return
		if event.is_action_pressed("spider_vision"):session.local_action("vision");return
		if event.is_action_pressed("jump"): session.local_action("jump")
		if event.is_action_pressed("dash"): session.local_action("dash")
		for slot in range(1,5):
			if event.is_action_pressed("ability"+str(slot)): session.local_action("ability"+str(slot))
		if event.is_action_pressed("transform"): session.local_action("transform")
		if event.is_action_pressed("kogane"): session.local_action("kogane")
		if event.is_action_pressed("lock"): session.local_action("lock")
		if event.is_action_pressed("emote"): actor.interface.toggle_emotes()

func _physics_process(delta: float) -> void:
	if not session.active: return
	send_timer += delta
	if send_timer >= 1.0/30.0:
		send_timer = fmod(send_timer,1.0/30.0)
		var axis := Vector2.ZERO; var flags := 0
		if not menu_open and not OS.get_environment("NAOYA_NET_QA").is_empty(): return
		if not menu_open and session.actors.has(session.local_id()) and not session.actors[session.local_id()].menu_blocked and not session.actors[session.local_id()].interface.emote_wheel.visible:
			axis = Input.get_vector("left","right","forward","back")
			if Input.is_action_pressed("block"): flags |= 1
			if Input.is_action_pressed("walk"): flags |= 2
			if Input.is_action_pressed("ability1"): flags |= 8
			if zoom <= .55: flags |= 16
			if bool(preferences.values.hold_attack) and Input.is_action_pressed("attack") and not session.actors[session.local_id()].hud_cursor: flags |= 4
		session.local_input(axis,yaw,flags,pitch)

func _process(delta: float) -> void:
	hit_flash = maxf(0,hit_flash-delta); hit_notice_time = maxf(0,hit_notice_time-delta)
	hit_indicator.text = last_hit if hit_notice_time > 0 else ""
	telemetry.rendered_players = session.actors.size()
	for item in numbers.duplicate():
		item.life -= delta; item.node.position.y += delta; item.node.modulate.a = clampf(item.life/.2,0,1)
		if item.life <= 0: item.node.queue_free(); numbers.erase(item)
	if not session.actors.has(session.local_id()): camera_view.restore(); hud.text = "PUNCHLINE · ONLINE · SIN CONEXIÓN"; health.value = 0; return
	var actor: Node3D = session.actors[session.local_id()]
	interface = actor.interface; actor.interface.visible = not menu_open
	if camera_generation != int(actor.metadata.generation): camera_generation = int(actor.metadata.generation); camera_initialized = false
	var kind: String = "THE PROYECTED" if actor.model_kind == 0 else "ROBOT · "+actor.robots.NAMES[actor.robot_index]
	hud.text = "%s · %d / 100\n%d/3 · %s · DASH %.1f" % [kind,int(actor.hp),session.roster.size(),"ANFITRIÓN" if session.server else "CONECTADO",actor.dash_cd]
	health.value = actor.hp
	if actor.fusion.cinematic or actor.fusion.death_broken: camera_view.restore()
	if actor.fusion.camera_update(camera,delta): actor.fusion.camera_shake(camera,delta); return
	if camera_view.update(actor,camera,zoom,yaw,pitch,delta): return
	camera.near = .12
	var wanted: Vector3 = actor.player.global_position+Vector3.UP*camera_view.eye_height(actor)*.88
	if not camera_initialized: camera_target = wanted; yaw = float(actor.metadata.yaw); camera_initialized = true
	camera_target = camera_target.lerp(wanted,1-exp(-delta*14))
	var offset := Vector3(0,zoom*.25,zoom*(1.6 if actor.fusion.fused else 1.0)).rotated(Vector3.RIGHT,pitch).rotated(Vector3.UP,yaw)
	var eye := camera_target+offset
	var ray := PhysicsRayQueryParameters3D.create(camera_target,eye,1)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty(): eye = hit.position+hit.normal*.22
	camera.global_position = actor.fusion.blend_camera(camera,eye,delta); camera.look_at(camera_target,Vector3.UP)
	actor.fusion.camera_shake(camera,delta)

func play_sound(kind: String, point: Vector3) -> void:
	var selected: Dictionary = audio_bank.choose(kind,bool(preferences.values.reference_audio))
	var stream: AudioStream = selected.get("stream")
	if stream == null:
		var fallback := {"jump":"res://assets/audio/v096/jump.wav","dash":"res://assets/audio/dash_swish.ogg","block":"res://assets/audio/guard_tap.ogg","landing":"res://assets/audio/footstep_concrete_000.ogg"}
		if fallback.has(kind): stream = load(fallback[kind])
	if stream == null: return
	var voice := voices[voice_index%voices.size()]; voice_index += 1
	voice.stop(); voice.stream = stream; voice.position = point; voice.pitch_scale = 1; voice.play()

func show_damage(point: Vector3, damage: float) -> void:
	if numbers.size() >= 30: return
	var text := Label3D.new(); add_child(text); text.position = point; text.text = str(int(damage))
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED; text.pixel_size = .004; text.font_size = 36
	numbers.append({"node":text,"life":.55})

func _exit_tree() -> void:
	if is_instance_valid(session):
		session.active = false
		if session.api != null and session.api.multiplayer_peer != null: session.api.multiplayer_peer.close()

func load_nickname() -> String:
	var config := ConfigFile.new()
	if config.load("user://online_profile.cfg") == OK: return str(config.get_value("profile","nickname",""))
	return ""
func save_nickname(value: String) -> void:
	var config := ConfigFile.new(); config.set_value("profile","nickname",value); config.save("user://online_profile.cfg")

func configure_world(settings:Dictionary)->void:
	world_settings=preload("res://scripts/world_config.gd").normalized(settings)
	if map.world_settings!=world_settings:map.rebuild_world(world_settings)
	map.ambience.configure_environment(get_node("ArenaEnvironment").environment,bool(world_settings.night))
	if seed_field!=null:
		seed_field.text=String(world_settings.seed);density_field.selected=int(world_settings.density);night_field.button_pressed=world_settings.night;destructible_field.button_pressed=world_settings.destructible

extends Control
var host: Node3D
var selected := -1
var radius := 180.0
var opening := 0.0
var glass: Control
var preview: SubViewport
var preview_anim: AnimationPlayer
var preview_model: Node3D
var preview_texture: TextureRect
var preview_index := -2
var hover_sound_time := 0.0
func setup(game: Node3D) -> void:
	host = game; mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var copy := BackBufferCopy.new(); copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT; add_child(copy)
	glass = preload("res://scripts/emote_glass_surface.gd").new(); glass.wheel = self
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(glass)
	var material := ShaderMaterial.new(); material.shader = preload("res://shaders/emote_glass.gdshader"); glass.material = material
	preview_texture = TextureRect.new(); add_child(preview_texture)
	preview_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visibility_changed.connect(func() -> void:
		opening = 0; preview_index = -2
		if visible: create_preview()
		elif preview != null: preview.queue_free(); preview = null; preview_anim = null; preview_texture.texture = null)
	resized.connect(queue_redraw)
func create_preview() -> void:
	if preview != null: return
	preview = SubViewport.new(); preview.name = "RealEmotePreview"; add_child(preview)
	preview.size = Vector2i(240,320); preview.transparent_bg = true; preview.own_world_3d = true
	preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview_model = host.rig_scene.duplicate(0) if host.robots.active else load(host.PLAYER_RIG_SCENE_PATH).instantiate()
	preview.add_child(preview_model)
	preview_model.scale = Vector3.ONE*(host.rig_holder.scale.x if host.robots.active else host.RIG_SCALE_ADJUST); preview_model.rotation.y = 0 if host.robots.active else PI
	preview_anim = host.find_animation_player(preview_model)
	for library in ["dance","extras","emotes"]:
		if host.rig_anim.has_animation_library(library): preview_anim.add_animation_library(library,host.rig_anim.get_animation_library(library))
	var camera := Camera3D.new(); preview.add_child(camera); camera.position = Vector3(0,1.1,4)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = 2.6; camera.current = true
	var light := DirectionalLight3D.new(); preview.add_child(light); light.rotation_degrees = Vector3(-25,-20,0); light.light_energy = 1.2
	var world := WorldEnvironment.new(); preview.add_child(world); world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR; world.environment.background_color = Color(0,0,0,0)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; world.environment.ambient_light_color = Color.WHITE; world.environment.ambient_light_energy = .6
	preview_texture.texture = preview.get_texture()
func segment(index: int) -> PackedVector2Array:
	var center := size*.5
	var step: float = TAU/host.presentation.emote_entries().size()
	var start: float = -PI*.5+step*index+.025; var finish: float = start+step-.05
	var polygon := PackedVector2Array()
	for k in range(17): polygon.append(center+Vector2.from_angle(lerpf(start,finish,k/16.0))*radius)
	for k in range(16,-1,-1): polygon.append(center+Vector2.from_angle(lerpf(start,finish,k/16.0))*radius*.48)
	return polygon
func _process(delta: float) -> void:
	if not visible: return
	opening = minf(1,opening+delta*6); hover_sound_time = maxf(0,hover_sound_time-delta)
	radius = minf(240,minf(size.x,size.y)*.38)*lerpf(.92,1,smoothstep(0,1,opening))
	preview_texture.position = size*.5-Vector2(radius*.30,radius*.45)
	preview_texture.size = Vector2(radius*.60,radius*.83); preview_texture.modulate.a = opening
	var index := selected if selected >= 0 else 0
	if preview_anim != null and preview_index != index:
		preview_index = index
		var data: Dictionary = host.presentation.emote_entries()[index]
		preview_anim.speed_scale = data.speed; preview_anim.play(data.clip,.12)
	queue_redraw(); glass.queue_redraw()
func _draw() -> void:
	if host == null: return
	var center := size*.5; var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO,size),Color(.025,.04,.06,.09*opening))
	var step: float = TAU/host.presentation.emote_entries().size()
	for i in range(host.presentation.emote_entries().size()):
		var polygon := segment(i); polygon.append(polygon[0])
		draw_polyline(polygon,Color(.8,.94,1,.85 if i == selected else .32),1.6,true)
		var point := center+Vector2.from_angle(-PI*.5+step*(i+.5))*radius*.74
		var active := i == selected
		draw_string(font,point+Vector2(-5,-4),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,22 if active else 17,Color("ffe3a1") if active else Color("ccebf4"))
		var caption: String = host.presentation.emote_entries()[i].name if host.robots.active else ["Running Man","Desafío","Sí","No","Brazos","Llamada","Zombi","Entrada"][i]
		var width := font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
		draw_string(font,point+Vector2(-width*.5,18),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(.84,.94,1,.95))
	var title: String = host.presentation.emote_entries()[selected].name if selected >= 0 else "ELIGE TU GESTO"
	var width := font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
	draw_string(font,Vector2(center.x-width*.5,center.y+radius+23),title,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f4e4bd"))
	var help := "1–%d / CLIC · B / ESC CERRAR" % host.presentation.emote_entries().size()
	width = font.get_string_size(help,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
	draw_string(font,Vector2(center.x-width*.5,center.y+radius+43),help,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("bcd1da"))
func pick(point: Vector2) -> int:
	var offset := point-size*.5
	return posmod(int(floor((offset.angle()+PI*.5)/(TAU/host.presentation.emote_entries().size()))),host.presentation.emote_entries().size()) if offset.length() > radius*.48 and offset.length() < radius else -1
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var previous := selected; selected = pick(event.position)
		if selected != previous and selected >= 0 and hover_sound_time <= 0: host.feedback.ui_sound("hover"); hover_sound_time = .12
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected = pick(event.position)
		if selected >= 0: host.interface.choose_emote(selected)
		accept_event()

extends CanvasLayer

const INK := Color("10131d")
const PANEL := Color("1c2130")
const TEXT := Color("eef0f8")
const MUTED := Color("a4acc2")
const ACCENT := Color("a7c7c1")
const MINT := Color("86d7c2")
var game: Node3D
var screen: Control
var identity: Control
var ability_cluster: Control
var menu_button: Button
var menu_grid: GridContainer
var character_popup: PanelContainer
var character_scroll: ScrollContainer
var character_rows: Array[Button] = []
var selector_return_to_menu := false
var selector_tween: Tween
var selector_closing := false
var selector_anchor := Vector2.ZERO
var state_captions: Array[Label] = []
var health_text: Label
var stability: Control
var energy_text: Label
var phase_text: Label
var status: Label
var hint: Label
var metric: Label
var target_label: Label
var cards: Array[Dictionary] = []
var menu: Control
var menu_panel: PanelContainer
var menu_content: VBoxContainer
var scroll: ScrollContainer
var menu_title: Label
var menu_tabs: Dictionary = {}
var selected_tab := "test"
var awaiting_action := ""
var awaiting_button: Button
var hit_marker: Label
var hit_life := 0.0
var combo_hits := 0
var combo_damage := 0.0
var combo_life := 0.0
var emote_wheel: Control
var menu_context: Label
var menu_column: VBoxContainer
var menu_body: GridContainer
var menu_transition: Tween
var content_transition: Tween
var menu_portrait: SubViewportContainer
var menu_depth: SubViewportContainer
var menu_exit: Button
var menu_footer: Button

func style(color: Color, border: Color = Color("343b51"), radius: int = 12) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box

func label(text: String, size: int = 16, color: Color = TEXT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color",Color("111621"))
	node.add_theme_constant_override("outline_size",2)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func button(text: String, callback: Callable) -> Button:
	var node := preload("res://scripts/ink_button.gd").new()
	node.holographic = game != null and game.robots.active
	node.text = text
	var icon := ""
	for pair in [["PERSONAJE","pawn"],["COMBATE","shield"],["EXPLORAR","structure_house"],["AJUSTES","timer_100"],["CONTROLES","arrow_rotate"]]:
		if text.contains(pair[0]): icon = pair[1]; break
	if icon != "":
		node.icon = load("res://assets/ui/v098/"+icon+".png")
		node.add_theme_constant_override("icon_max_width",20)
	node.tooltip_text = text
	node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	node.custom_minimum_size.y = 38
	node.add_theme_font_size_override("font_size", 14)
	node.add_theme_stylebox_override("normal", style(PANEL))
	node.add_theme_stylebox_override("hover", style(Color("2c3046"), ACCENT))
	node.add_theme_stylebox_override("pressed", style(Color("3b3451"), ACCENT))
	node.add_theme_stylebox_override("focus", style(Color(0,0,0,0), ACCENT))
	node.mouse_entered.connect(func() -> void: game.feedback.ui_sound("hover"))
	node.pressed.connect(func() -> void:
		game.feedback.ui_sound()
		callback.call())
	return node

func setup(host: Node3D) -> void:
	game = host
	layer = 5
	screen = Control.new()
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity = preload("res://scripts/hud_identity.gd").new()
	screen.add_child(identity)
	identity.selector_pressed = toggle_character
	stability=preload("res://scripts/stability_display.gd").new();stability.game=game;identity.add_child(stability);stability.position=Vector2(120,57)
	phase_text = identity_text("THE PROYECTED · PROYECCIÓN",Vector2(124,96),Vector2(245,23),21)
	health_text = identity_text("100 / 100",Vector2(392,96),Vector2(110,23),19)
	health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	energy_text = identity_text("",Vector2(126,137),Vector2(378,35),16,ACCENT)
	energy_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in range(4):
		var caption := identity_text(["CAÍDA","VELOC.","FORMA","GUARDIA"][i],Vector2(126+i*63,-7),Vector2(52,15),10,MUTED)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		state_captions.append(caption)
	menu_button = button("ESC · MENÚ",func() -> void: open_menu("test"))
	screen.add_child(menu_button)
	metric = label("", 11, MUTED)
	screen.add_child(metric)
	metric.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	target_label = label("", 13, MUTED)
	screen.add_child(target_label)
	target_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hit_marker = label("×", 30, MINT)
	screen.add_child(hit_marker)
	hit_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hit_marker.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hit_marker.position -= Vector2(16, 24)
	status = label("", 12, MINT)
	screen.add_child(status)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ability_cluster = Control.new()
	screen.add_child(ability_cluster)
	ability_cluster.size = Vector2(620,368)
	ability_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(4):
		var card := preload("res://scripts/hud_ability.gd").new()
		ability_cluster.add_child(card)
		card.setup(i)
		cards.append({"panel":card,"name":card.title_label,"key":card.key_label,"detail":card.detail_label})
	hint = label("", 11, MUTED)
	screen.add_child(hint)
	hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	build_menu()
	emote_wheel = preload("res://scripts/emote_wheel_glass.gd").new()
	screen.add_child(emote_wheel); emote_wheel.setup(game); emote_wheel.hide()
	build_character_selector()
	screen.resized.connect(resize)
	resize()
	tick(0.016)

func identity_text(text: String, position: Vector2, extent: Vector2, font_size: int, color: Color = TEXT) -> Label:
	var node := label(text,font_size,color)
	identity.add_child(node)
	node.position = position
	node.size = extent
	return node

func resize() -> void:
	var viewport_size := screen.size
	var compact := viewport_size.y < 500
	var narrow := viewport_size.x < 850
	var hud_scale: float = clampf(float(game.preferences.values.hud_scale),0.5,1.0)
	var id_scale := minf(1.0,minf(viewport_size.x-24,510)/510.0)
	if compact: id_scale = minf(id_scale,viewport_size.y*0.25/174.0)
	id_scale *= hud_scale
	identity.scale = Vector2.ONE*id_scale
	identity.position = Vector2(12,10)
	var cluster_scale := minf(1.05,minf(viewport_size.x-28,clampf(viewport_size.x*0.42,330,515))/620.0)
	cluster_scale = minf(cluster_scale,viewport_size.y*(0.44 if compact else 0.40)/368.0)
	cluster_scale *= hud_scale
	ability_cluster.scale = Vector2.ONE*cluster_scale
	ability_cluster.position = Vector2(viewport_size.x-620*cluster_scale-14,viewport_size.y-368*cluster_scale-(12 if compact else 24))
	var action_y := 10.0
	if identity.position.x+510*id_scale > viewport_size.x-158:
		action_y = identity.position.y+174*id_scale+6
	var menu_width := 166.0 if game.robots.active else 132.0
	menu_button.position = Vector2(viewport_size.x-menu_width-14,action_y)
	menu_button.size = Vector2(menu_width,38)
	metric.position = menu_button.position+Vector2(0,43)
	metric.size = Vector2(132,18)
	metric.visible = not compact
	target_label.position = Vector2(14,action_y+5) if action_y > 10 else Vector2(identity.position.x+510*id_scale+18,16)
	target_label.size = Vector2(maxf(30,menu_button.position.x-target_label.position.x-12),27)
	target_label.visible = not compact and target_label.size.x >= 100
	status.position = Vector2(14,ability_cluster.position.y-38) if narrow else Vector2(14,viewport_size.y-81)
	status.size = Vector2(viewport_size.x-28 if narrow else maxf(240,ability_cluster.position.x-38),32)
	hint.position = Vector2(14,viewport_size.y-18)
	hint.size = Vector2(viewport_size.x-28,16)
	menu_grid.columns = 2 if viewport_size.x < 850 else 1
	menu_grid.custom_minimum_size.x = 0 if viewport_size.x < 850 else 190
	if menu_body != null: menu_body.columns = 1 if viewport_size.x < 850 else 2
	menu_title.add_theme_font_size_override("font_size",24 if compact else 34)
	menu_context.visible = not compact
	menu_column.add_theme_constant_override("separation",8 if compact else 12)
	for tab in menu_tabs.values():
		tab.custom_minimum_size.y = 26 if compact else 38
		tab.add_theme_font_size_override("font_size",11 if compact else 14)
	menu_footer.custom_minimum_size.y = 28 if compact else 38
	menu_exit.custom_minimum_size.y = 28 if compact else 38
	var requested := Vector2(minf(960,viewport_size.x-24),minf(650,viewport_size.y-24))
	# Usar el tamaño solicitado, no el tamaño todavía impuesto por mínimos anteriores.
	scroll.custom_minimum_size.y = 32 if compact else 66
	menu_panel.custom_minimum_size = Vector2.ZERO
	menu_panel.size = requested
	menu_panel.position = (viewport_size-requested)*0.5
	call_deferred("finish_menu_layout",requested)
	if character_popup != null:
		var width := minf(240,viewport_size.x-24)
		var anchor := identity.position+Vector2(18,160)*id_scale
		character_scroll.custom_minimum_size = Vector2(width-12,minf(174,viewport_size.y-anchor.y-24))
		character_popup.size = Vector2(width,character_scroll.custom_minimum_size.y+12)
		selector_anchor = Vector2(clampf(anchor.x,12,viewport_size.x-width-12),anchor.y)
		if selector_tween == null or not selector_tween.is_running(): character_popup.position = selector_anchor

func finish_menu_layout(requested: Vector2) -> void:
	menu_panel.size = requested
	menu_panel.position = (screen.size-menu_panel.size)*0.5

func build_menu() -> void:
	menu = Control.new()
	screen.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim: Control = preload("res://scripts/menu_backdrop.gd").new()
	menu.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_panel = PanelContainer.new()
	var skin := style(Color(.025,.045,.055,.86),Color(.24,.36,.37,.3),0)
	skin.border_width_left = 3; skin.border_color = Color("b19a66")
	menu_panel.add_theme_stylebox_override("panel",skin)
	menu.add_child(menu_panel)
	menu_depth = preload("res://scripts/menu_depth.gd").new(); menu_depth.ui = self; menu.add_child(menu_depth); menu.move_child(menu_depth,1)
	var column := VBoxContainer.new()
	menu_column = column
	column.add_theme_constant_override("separation", 12)
	menu_panel.add_child(column)
	menu_title = label("THE PROYECTED", 34,Color("e7d2a3"))
	column.add_child(menu_title)
	menu_context = label("PUNCHLINE / "+BuildInfo.version+" · TIEMPO DETENIDO",12,MUTED); column.add_child(menu_context)
	menu_body = GridContainer.new(); menu_body.columns = 2; menu_body.size_flags_vertical = Control.SIZE_EXPAND_FILL; menu_body.add_theme_constant_override("h_separation",28); column.add_child(menu_body)
	menu_grid = GridContainer.new()
	menu_grid.columns = 4
	menu_grid.add_theme_constant_override("h_separation",6)
	menu_grid.add_theme_constant_override("v_separation",6)
	menu_body.add_child(menu_grid)
	for pair in [["character","01 / PERSONAJE"],["test","02 / COMBATE"],["map","03 / EXPLORAR"],["settings","04 / AJUSTES"],["controls","05 / CONTROLES"],["online","06 / MULTIJUGADOR"]]:
		var id: String = pair[0]
		var tab := button(pair[1], func() -> void: select_tab(id))
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		menu_grid.add_child(tab)
		menu_tabs[id] = tab
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_body.add_child(scroll)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_content = VBoxContainer.new()
	menu_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_content.add_theme_constant_override("separation", 10)
	scroll.add_child(menu_content)
	menu_footer = button("VOLVER AL JUEGO · ESC", func() -> void: game.set_paused(false))
	var footer_row := HBoxContainer.new(); column.add_child(footer_row)
	menu_footer.text = "VOLVER · ESC"; menu_footer.clip_text = true; menu_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_row.add_child(menu_footer)
	menu_exit = button("MENÚ PRINCIPAL",game.leave_to_main_menu); menu_exit.clip_text = true; menu_exit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_exit.tooltip_text = "Salir de esta partida y volver al menú principal"
	footer_row.add_child(menu_exit)
	menu_portrait = preload("res://scripts/menu_portrait.gd").new(); menu.add_child(menu_portrait); menu.move_child(menu_portrait,1)
	menu_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); menu_portrait.anchor_left = .50
	menu.hide()
	select_tab("test")

func open_menu(tab: String = "test") -> void:
	game.feedback.ui_sound("open")
	if emote_wheel != null: emote_wheel.hide()
	if character_popup.visible:
		close_character(true)
		await selector_tween.finished
	select_tab(tab)
	game.set_paused(true)
	resize()
	animate_open()

func animate_open() -> void:
	if menu_transition != null: menu_transition.kill()
	var amount: float = float(game.preferences.values.get("ui_motion",1.0))
	menu_panel.modulate.a = .0 if amount > 0 else 1.0
	menu_transition = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	menu_panel.pivot_offset = menu_panel.size*.5
	menu_panel.scale = Vector2.ONE*(.965 if amount > 0 else 1.0)
	menu_depth.reveal = 0 if amount > 0 else 1
	menu_transition.set_parallel(true)
	menu_transition.tween_property(menu_panel,"modulate:a",1.0,.20*amount+.001)
	menu_transition.tween_property(menu_panel,"scale",Vector2.ONE,.26*amount+.001)
	menu_transition.tween_property(menu_depth,"reveal",1.0,.30*amount+.001)

func toggle_emotes() -> void:
	if emote_wheel.visible: close_emotes(); return
	if game.form != "BASE" or not game.can_start_action() or not game.grounded_for_actions(): return
	menu.hide(); emote_wheel.show(); Input.mouse_mode = game.hud_mouse_mode()
	emote_wheel.selected = -1; emote_wheel.queue_redraw()

func close_emotes() -> void:
	game.feedback.ui_sound("close")
	emote_wheel.hide(); game.hud_attack_requires_release = Input.is_action_pressed("attack"); Input.mouse_mode = game.hud_mouse_mode()

func choose_emote(index: int) -> void:
	close_emotes(); game.presentation.start_emote(index)

func build_character_selector() -> void:
	character_popup = PanelContainer.new()
	character_popup.name = "CharacterDropdown"
	var background := style(Color("111114"),Color("28282d"),12)
	background.content_margin_left = 6
	background.content_margin_right = 6
	background.content_margin_top = 6
	background.content_margin_bottom = 6
	character_popup.add_theme_stylebox_override("panel",background)
	screen.add_child(character_popup)
	character_scroll = ScrollContainer.new()
	character_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	character_popup.add_child(character_scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",0)
	character_scroll.add_child(rows)
	for i in range(3):
		var character := i
		var item := button(["The Proyected","Robot","Coming Soon"][i],func() -> void:
			if character < 2: game.robots.select(character)
			close_character(true))
		item.custom_minimum_size.y = 58
		item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item.add_theme_font_size_override("font_size",18)
		item.add_theme_stylebox_override("normal",style(Color("343438"),Color("343438"),8))
		item.add_theme_stylebox_override("hover",style(Color("45454b"),Color("45454b"),8))
		item.add_theme_stylebox_override("disabled",style(Color("111114"),Color("111114"),8))
		item.add_theme_color_override("font_disabled_color",Color("88888f"))
		item.disabled = i == 2
		item.tooltip_text = "Personaje seleccionado" if i == 0 else ("Elegir Robot · chasis aleatorio" if i == 1 else "Próximamente · todavía no disponible")
		rows.add_child(item)
		character_rows.append(item)
	character_popup.hide()

func pause_changed(value: bool) -> void:
	if not value:
		if menu_transition != null: menu_transition.kill()
		if selector_tween != null: selector_tween.kill()
		selector_closing = false; character_popup.hide()
		if emote_wheel != null: emote_wheel.hide()
		selector_return_to_menu = false
	menu.visible = value and not character_popup.visible

func toggle_character() -> void:
	if character_popup.visible and not selector_closing:
		close_character(); return
	if emote_wheel.visible: close_emotes()
	if selector_tween != null: selector_tween.kill()
	if not selector_closing: selector_return_to_menu = game.paused and menu.visible
	selector_closing = false; awaiting_action = ""
	var was_visible := character_popup.visible
	character_popup.show(); game.set_paused(true); resize()
	if not was_visible:
		character_popup.modulate.a = 0; character_popup.scale = Vector2(.98,.86)
		character_popup.position = selector_anchor+Vector2(0,-9)
	selector_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	selector_tween.tween_property(character_popup,"modulate:a",1.0,.20)
	selector_tween.tween_property(character_popup,"scale",Vector2.ONE,.22)
	selector_tween.tween_property(character_popup,"position",selector_anchor,.22)
	character_rows[1 if game.robots.active else 0].grab_focus()

func close_character(resume: bool = false) -> void:
	if not character_popup.visible or selector_closing: return
	selector_closing = true
	var restore_menu := selector_return_to_menu and not resume
	if selector_tween != null: selector_tween.kill()
	selector_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	selector_tween.tween_property(character_popup,"modulate:a",0.0,.14)
	selector_tween.tween_property(character_popup,"scale",Vector2(.99,.93),.14)
	selector_tween.tween_property(character_popup,"position",selector_anchor+Vector2(0,-6),.14)
	selector_tween.finished.connect(func() -> void:
		character_popup.hide(); selector_closing = false; selector_return_to_menu = false
		character_popup.scale = Vector2.ONE; character_popup.modulate.a = 1; character_popup.position = selector_anchor
		if restore_menu: menu.show()
		else: game.set_paused(false))

func select_tab(tab: String) -> void:
	selected_tab = tab
	if menu_panel!=null:
		var surface:StyleBoxFlat=menu_panel.get_theme_stylebox("panel");surface.bg_color=Color(.015,.035,.05,.62 if tab in ["settings","controls"] else .86)
	awaiting_action = ""
	for child in menu_content.get_children():
		menu_content.remove_child(child)
		child.queue_free()
	for id in menu_tabs:
		menu_tabs[id].modulate = ACCENT if id == tab else TEXT
	if tab == "online":
		menu_content.add_child(label("PARTIDA PARA TRES",20,ACCENT))
		var info := label("Crea una partida o únete por IP. Para amigos en otras ciudades, usen la misma red de Radmin VPN. El anfitrión mantiene el juego abierto. La partida online incluye el HUD, las habilidades de The Proyected y de los robots, transformación, evolución, dominio, Kogane y emotes. El laboratorio individual permite preparar pruebas con enemigos.",14,MUTED)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; menu_content.add_child(info)
		menu_content.add_child(button("ABRIR MULTIJUGADOR",func() -> void: get_tree().change_scene_to_file("res://network/online.tscn")))
	elif tab == "character":
		menu_content.add_child(label("PERSONAJE ACTUAL",14,ACCENT))
		var character_name := label("ROBOT · "+game.robots.NAMES[game.robots.index] if game.robots.active else "THE PROYECTED · TÉCNICA DE PROYECCIÓN",19)
		character_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		menu_content.add_child(character_name)
		var description := label("Cuatro chasis. Leela: patadas; Stan: puños pesados; George: versátil; Mike: defensa. El chasis cambia al reaparecer." if game.robots.active else "Avance guiado, Counter, golpes veloces y patada. Kogane acompaña a The Proyected y aparece en su retrato.",13,MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		menu_content.add_child(description)
		if game.robots.active:
			var profile_text: String = "JUNKYARD SENTINEL · 300 HP · 4 m. Ataques amplios y lentos. Los M1 resisten interrupciones de personajes normales; otro mega sí puede cortarlos. Q: impulso diagonal de 5,5 s de recarga, sin invulnerabilidad." if game.fusion.fused else preload("res://scripts/mecha_move_catalog.gd").PROFILES[game.robots.index]
			var profile_label := label(profile_text,14,ACCENT); profile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; menu_content.add_child(profile_label)
			for i in range(4):
				if not game.fusion.fused and not game.robots.available(i+1): continue
				var heading: String = preload("res://scripts/mecha_move_catalog.gd").mega(i+1).title if game.fusion.fused else game.robots.title(i+1)
				menu_content.add_child(label(str(i+1)+" / "+heading,16))
				var detail: String = preload("res://scripts/mecha_move_catalog.gd").description(i+1) if game.fusion.fused else preload("res://scripts/mecha_move_catalog.gd").base_description(game.robots.index,i+1)
				var explanation := label(detail,13,MUTED); explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; menu_content.add_child(explanation)
		menu_content.add_child(label("SELECCIONADO",12,MINT))
		menu_content.add_child(button("Elegir The Proyected",func() -> void: game.robots.select(0); game.set_paused(false)))
		menu_content.add_child(button("Elegir Robot · chasis aleatorio",func() -> void: game.robots.select(1); game.set_paused(false)))
	elif tab == "test":
		for robot_index in range(4):
			var chosen := robot_index
			menu_content.add_child(button("Robot · "+game.robots.NAMES[chosen],func() -> void:
				game.robots.forced = chosen
				if not game.robots.active: game.robots.select(1)
				else: game.respawn_player()
				game.robots.forced = -1; game.set_paused(false)))
		menu_content.add_child(label("FUSIÓN / JUNKYARD SENTINEL",14,ACCENT))
		menu_content.add_child(button("TALLER DEL CAÑÓN · DEMO V8",func() -> void: game.set_paused(false); get_tree().change_scene_to_file.call_deferred("res://CannonDemo.tscn")))
		menu_content.add_child(button("Probar G · fusionar el chasis actual",func() -> void:
			if not game.robots.active: game.robots.select(1)
			game.fusion.reset(); game.charge = 100; game.set_paused(false); game.fusion.request()))
		menu_content.add_child(button("Restaurar robot base / reiniciar G",func() -> void: game.fusion.reset()))
		menu_content.add_child(label("PREPARAR UNA PRUEBA", 14, ACCENT))
		var explanation := label("Estos botones preparan el laboratorio. En combate la energía se gana al acertar.",12,MUTED)
		explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		menu_content.add_child(explanation)
		menu_content.add_child(button("Energía y evolución al 100%", func() -> void:
			game.charge = 100
			game.moves.phase_charge = 100))
		for pair in [["BASE","Humano · Base"],["FORM1","Transformación · Fase 1"],["FORM2","Evolución · Fase 2"]]:
			var form: String = pair[0]
			menu_content.add_child(button(pair[1], func() -> void:
				game.reset_lab()
				if form != "BASE": game.start_form(form, true)
				game.set_paused(false)))
		var reset_button := button("Reiniciar laboratorio",func() -> void: game.reset_lab())
		reset_button.tooltip_text = "Restablece posiciones, vida, energía y cooldowns."
		menu_content.add_child(reset_button)
		menu_content.add_child(button("Registrar rendimiento · 60 segundos",func() -> void:
			game.performance_capture.begin();game.set_paused(false)))
		menu_content.add_child(button("Abrir registros de rendimiento",func() -> void:
			OS.shell_open(OS.get_user_data_dir())))
		menu_content.add_child(button("Galería · seis apariencias Y2K",func() -> void:
			game.toggle_enemy_gallery(); game.set_paused(false)))
		menu_content.add_child(button("Cambiar apariencias del grupo",func() -> void:
			game.randomize_enemy_appearances(game.appearance_seed+1)))
		menu_content.add_child(button("Dominio · inspeccionar exterior [F8]",func() -> void:
			game.set_paused(false); game.domain_inspector.toggle()))
		for item in [["Crouch_To_Stand","Vista de animación · agachado a de pie"],["left_turn_90","Vista de animación · giro izquierdo"],["right_turn_90","Vista de animación · giro derecho"]]:
			var clip: String = item[0]
			menu_content.add_child(button(item[1],func() -> void: game.preview_clip("mixamo/"+clip)))
		menu_content.add_child(button("Fotograma de The Proyected · 5 segundos",func() -> void:
			game.set_paused(false)
			game.moves.freeze_player(5.0)))
		menu_content.add_child(button("Fotograma del NPC cercano · 5 segundos",func() -> void:
			game.set_paused(false)
			var target: Dictionary = nearest_enemy()
			if not target.is_empty(): game.moves.freeze_enemy(target,5.0)))
		for i in range(game.enemies.size()):
			var enemy: Dictionary = game.enemies[i]
			var row := HBoxContainer.new()
			menu_content.add_child(row)
			row.add_child(label("NPC %02d" % (i+1),13,MUTED))
			var behavior := OptionButton.new()
			for name in game.DUMMY_NAMES: behavior.add_item(name)
			behavior.selected = int(enemy.kind)
			behavior.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			behavior.add_theme_font_size_override("font_size",14)
			behavior.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			row.add_child(behavior)
			behavior.item_selected.connect(func(index: int) -> void: game.set_dummy_mode(enemy,index))
	elif tab == "map":
		menu_content.add_child(label("PUNCHLINE / CIUDAD EN RUINAS" if game.arena.punchline != null else "ESTACIÓN 24 / DISTRITO DE PROYECCIÓN",16,ACCENT))
		var help := label("Ruined City: edificios y calles del nuevo GLB. Robots: agachado automático bajo techos; los huecos deben ser más anchos que su cápsula. Ctrl camina; V primera persona." if game.arena.punchline != null else "E interactúa con las estaciones, la puerta y la plataforma de impulso. Rompe los vidrios del paso con M1. Ctrl camina; la rueda acerca la cámara.",13,MUTED)
		help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; menu_content.add_child(help)
		menu_content.add_child(button("ECO DE RUTA · correr contra tu mejor recorrido",func() -> void: game.route_trial.start()))
		menu_content.add_child(button("Terminar desafío",func() -> void: game.route_trial.cancel()))
		menu_content.add_child(button("Borrar récord del eco",func() -> void: game.route_trial.clear_record()))
		menu_content.add_child(button("Luz del distrito · noche / atardecer",func() -> void: game.arena.urban.set_lighting(not game.arena.urban.night)))
		menu_content.add_child(button("Rearmar vidrios rompibles",func() -> void: game.arena.urban.reset_glass()))
		var visits: Array = [["plaza","Plaza abierta · combate y esquiva"],["boulevard","Bulevar · calle de aceleración"],["district_roof","Distrito · azoteas conectadas"],["ramp","Rampa y azotea"],["roof","Saltos entre plataformas"],["pit","Foso · 6 metros de profundidad"],["lift","Ascensor · plataforma móvil"],["fall","Prueba de caída prolongada · 220 metros"]]
		if game.arena.punchline != null: visits = [["plaza","Ruined City · centro"],["boulevard","Ruined City · calle"],["fall","Caída prolongada · 220 metros"]]
		menu_content.add_child(button("Cambiar a PunchLine" if game.arena.laboratory else "Abrir laboratorio anterior",func() -> void:
			game.preferences.set_value("legacy_map",not game.arena.laboratory); game.get_tree().reload_current_scene()))
		for pair in visits:
			var id: String = pair[0]; menu_content.add_child(button(pair[1],func() -> void: game.arena.visit_zone(id)))
		menu_content.add_child(button("Emotes · selector radial [B]",func() -> void:
			game.set_paused(false); toggle_emotes()))
	elif tab in ["settings","controls"]:
		var settings=preload("res://scripts/settings_panel.gd").new();settings.preferences=game.preferences;settings.category="controls" if tab=="controls" else "video";menu_content.add_child(settings)
	scroll.scroll_vertical = 0
	if content_transition != null: content_transition.kill()
	var duration: float = .14*float(game.preferences.values.get("ui_motion",1.0))
	menu_content.modulate.a = .25 if duration > 0 else 1.0
	menu_content.scale = Vector2.ONE*(.98 if duration > 0 else 1.0)
	content_transition = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	content_transition.tween_property(menu_content,"modulate:a",1.0,duration+.001)
	content_transition.tween_property(menu_content,"scale",Vector2.ONE,duration+.08)
	if menu_grid != null: resize()

func slider(key: String, title: String, minimum: float, maximum: float, step: float) -> void:
	var row := HBoxContainer.new()
	menu_content.add_child(row)
	var caption := label(title,12,MUTED)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(caption)
	var number := label("",12)
	row.add_child(number)
	var control := HSlider.new()
	control.name = key
	control.min_value = minimum
	control.max_value = maximum
	control.step = step
	control.value = float(game.preferences.values[key])
	number.text = "%.0f%%" % (control.value * 100) if maximum <= 1 else "%.2f" % control.value
	menu_content.add_child(control)
	control.value_changed.connect(func(value: float) -> void:
		game.preferences.set_value(key,value)
		number.text = "%.0f%%" % (value * 100) if maximum <= 1 else "%.2f" % value)

func check(key: String, title: String) -> void:
	var node := CheckButton.new()
	node.text = title
	node.add_theme_font_size_override("font_size",14)
	node.button_pressed = bool(game.preferences.values[key])
	menu_content.add_child(node)
	node.toggled.connect(func(enabled: bool) -> void: game.preferences.set_value(key,enabled))

func _input(event: InputEvent) -> void:
	if emote_wheel != null and emote_wheel.visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.is_action_pressed("emote"): close_emotes(); get_viewport().set_input_as_handled(); return
		if event.keycode >= KEY_1 and event.keycode < KEY_1+game.presentation.emote_entries().size(): choose_emote(event.keycode-KEY_1); get_viewport().set_input_as_handled(); return
	if character_popup != null and character_popup.visible and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_point: Vector2 = identity.get_global_transform_with_canvas().affine_inverse()*event.position
		if not character_popup.get_global_rect().has_point(event.position) and not identity._has_point(local_point):
			close_character()
			get_viewport().set_input_as_handled()
			return
	if awaiting_action == "" or not event is InputEventKey or not event.pressed or event.echo: return
	var code: int = event.keycode
	if code == KEY_ESCAPE:
		awaiting_button.text = game.preferences.key_name(awaiting_action)
		awaiting_action = ""
	elif code in [KEY_R,KEY_ALT]:
		awaiting_button.text = "Tecla reservada"
	elif game.preferences.bindings.values().has(code) and int(game.preferences.bindings[awaiting_action]) != code:
		awaiting_button.text = "Tecla ocupada"
	else:
		game.preferences.install_key(awaiting_action,code)
		game.preferences.save()
		awaiting_button.text = game.preferences.key_name(awaiting_action)
		awaiting_action = ""
	get_viewport().set_input_as_handled()

func confirm_hit(damage: float) -> void:
	if combo_life <= 0:
		combo_hits = 0
		combo_damage = 0
	combo_hits += 1
	combo_damage += damage
	combo_life = 1.4
	hit_life = 0.14

func tick(delta: float) -> void:
	health_text.text = "%d / %d" % [maxi(0,int(game.hp)),int(game.max_hp)]
	if identity.holographic != game.robots.active:
		identity.set_holographic(game.robots.active)
		for card in cards: card.panel.set_holographic(game.robots.active,screen.size.x < 850)
		for element in menu.find_children("*","Button",true,false):
			if element.has_method("set_holographic"): element.set_holographic(game.robots.active)
		menu_button.set_holographic(game.robots.active)
		for tab_id in menu_tabs:
			menu_tabs[tab_id].text = {"character":"PERSONAJE","test":"COMBATE","map":"EXPLORAR","settings":"AJUSTES","controls":"CONTROLES","online":"MULTIJUGADOR"}[tab_id]
		menu_title.add_theme_color_override("font_color",Color("9cefff") if game.robots.active else Color("e7d2a3"))
		var skin: StyleBoxFlat = menu_panel.get_theme_stylebox("panel")
		skin.border_color = Color("3b9bb4") if game.robots.active else Color("b19a66")
		resize()
	for card in cards:card.panel.visible=true;card.panel.set_holographic(game.robots.active,screen.size.x < 850)
	phase_text.text = {"BASE":"THE PROYECTED · PROYECCIÓN","FORM1":"THE PROYECTED · FASE 1","FORM2":"THE PROYECTED · FASE 2"}[game.form]
	var energy: float = (100.0 if game.fusion.fused else game.charge) if game.form == "BASE" else game.ult_time/game.ult_duration*100
	var flags := [game.player_ragdoll or game.stun > 0 or game.wakeup_anim > 0,game.dash_time > 0 or (game.skill_active == "extra" and game.moves.stage in ["approach","commit","rush"]),game.form != "BASE" or game.charge >= 100,game.block or game.player_wakeup_protection > 0 or (game.moves.key == "b2" and game.moves.stage == "window")]
	identity.update_state(game.hp/maxf(1,game.max_hp)*100,energy,game.form,flags,game.preferences.key_name("character"),delta)
	stability.tick(delta);health_text.visible=not game.fusion.fused or game.fusion.spider.active()
	if identity.holo_health!=null:identity.holo_health.visible=game.robots.active and (not game.fusion.fused or game.fusion.spider.active())
	for i in range(4): state_captions[i].modulate = MINT if flags[i] else Color.WHITE
	var transform_key: String = game.preferences.key_name("transform")
	if game.form == "BASE":
		energy_text.text = "ENERGÍA %d%% · %s TRANSFORMAR" % [int(game.charge),transform_key]
	elif game.form == "FORM1":
		energy_text.text = "%.1f s · EVOLUCIÓN %d%% · %s" % [game.ult_time,int(game.moves.phase_charge),transform_key]
	else:
		energy_text.text = "FASE 2  /  %.1f s" % game.ult_time
	if not game.robots.active and not game.fusion.busy():
		var titles := ["Proyección","Counter","Golpe veloz","Patada"] if game.form == "BASE" else ["Embestida","Tentáculos","Aceleración","Dominio"]
		var icons: Array = {"BASE":["projection","counter","rush","kick"],"FORM1":["worm_charge","worm_tendrils","worm_speed","worm_domain"],"FORM2":["evolved_charge","evolved_tendrils","evolved_speed","evolved_domain"]}[game.form]
		var times: Array = [game.moves.cooldowns.b1,game.moves.cooldowns.b2,game.skill3_cd,game.skill4_cd] if game.form == "BASE" else [game.moves.cooldowns.u1,game.moves.cooldowns.u2,game.moves.cooldowns.u3,game.moves.cooldowns.u4]
		var maxima := [game.tuning.projection_cooldown,game.tuning.counter_cooldown,7.0,6.0] if game.form == "BASE" else [game.tuning.evolved_dash_cooldown,9.0,12.0,14.0]
		var tips := ["Autoapunta · final esquivable","Frame 5 s · ventana frontal","Avance y ráfaga","Patada de barrido"] if game.form == "BASE" else ["Autoapunta · final esquivable","Agarra y lanza","Rompe guardia","Moverse penaliza"]
		for i in range(4):
			var card: Dictionary = cards[i]
			var locked: bool = game.form == "FORM1" and i > 0
			var used: bool = game.form == "FORM2" and i == 3 and game.domain_used
			var short_time: bool = game.form == "FORM2" and i == 3 and game.ult_time < 14.8
			var detail := "FASE 2" if locked else ("USADO" if used else ("14.8 s" if short_time else ("%.1f s" % times[i] if float(times[i]) > 0 else "LISTO")))
			var executing: bool = (game.skill_active == "extra" and game.moves.key == ("b" if game.form == "BASE" else "u")+str(i+1)) or (i == 2 and game.skill_active == "skill3") or (i == 3 and game.skill_active == "skill4")
			var key_name: String = game.preferences.key_name("ability"+str(i+1))
			card.panel.set_state(titles[i],key_name,icons[i],float(times[i]),maxima[i],locked or used or short_time,detail,executing)
			card.panel.tooltip_text = card.panel.tooltip_text+"\n"+tips[i]
	hint.visible = bool(game.preferences.values.hints) and screen.size.y >= 500
	var movement_keys := ""
	for action in ["forward","left","back","right"]: movement_keys += game.preferences.key_name(action)
	hint.text = "%s · %s caminar · %s dash · %s emotes · %s Kogane · Esc Menú" % [movement_keys,game.preferences.key_name("walk"),game.preferences.key_name("dash"),game.preferences.key_name("emote"),game.preferences.key_name("kogane")]
	hit_life = maxf(0,hit_life-delta)
	hit_marker.modulate.a = hit_life/0.14
	if game.robots.active and not game.fusion.busy(): update_robot_hud()
	if game.fusion.busy():
		phase_text.text = "JUNKYARD SENTINEL / FUSIÓN" if game.fusion.cinematic else "JUNKYARD SENTINEL"
		energy_text.text = "G / %.1f de 11.5 s" % game.fusion.elapsed if game.fusion.cinematic else "M1 SUELO · F GUARDIA · Q PROPULSIÓN"
		for card_index in range(4):
			var move: Dictionary = preload("res://scripts/mecha_move_catalog.gd").mega(card_index+1)
			cards[card_index].panel.set_state("FUERA DE SERVICIO" if game.fusion.fused and not game.fusion.damage.allowed(card_index+1) else ("Montaje" if game.fusion.cinematic else move.title),game.preferences.key_name("ability"+str(card_index+1)),move.icon,game.fusion.combat.cooldowns[card_index],move.cooldown,game.fusion.cinematic or not game.fusion.damage.allowed(card_index+1),preload("res://scripts/mecha_move_catalog.gd").description(card_index+1),game.fusion.combat.current.get("id","") == move.id)
	combo_life = maxf(0,combo_life-delta)
	if game.fusion.spider.active():
		var spider:Node3D=game.fusion.spider
		phase_text.text="RUSTCRAWLER"
		energy_text.text="%d / 50 HP · %s RECONECTAR CERCA DEL MECHA" % [int(game.hp),game.preferences.key_name("interact")]
		cards[0].panel.set_state("Escaneo",game.preferences.key_name("ability1"),"spider_scan",spider.scan_cd,10.0,spider.mode!="spider","Detecta señales a 25 m durante 6 s",spider.scan_time>0)
		cards[1].panel.set_state("Camuflaje",game.preferences.key_name("ability2"),"spider_cloak",spider.cloak_cd,16.0,spider.mode!="spider","8 s de camuflaje; se rompe con daño o escaneo",spider.cloak_time>0)
		cards[2].panel.hide();cards[3].panel.hide()
		hint.text="WASD · caminar por superficies · %s reconectar · 1 escaneo · 2 camuflaje · Esc Menú" % game.preferences.key_name("interact")
	status.text = "%d IMPACTOS  /  %.0f DAÑO" % [combo_hits,combo_damage] if combo_life > 0 else ("GUARDIA" if game.block else ("RECUPERANDO" if game.stun > 0 else "DASH  "+("LISTO" if game.dash_cd <= 0 else "%.1f s" % game.dash_cd)))
	if game.ult_msg_time > 0: status.text = game.ult_msg
	elif game.fusion.spider.active():status.text="RUSTCRAWLER / cabeza separada · %s para reconectar cerca del mecha" % game.preferences.key_name("interact")
	if game.skill_active == "extra" and game.moves.key in ["b1","u1"]:
		status.text = {"windup":"PREPARACIÓN", "approach":"APROXIMACIÓN · AUTOAPUNTADO", "commit":"IMPACTO COMPROMETIDO · RUMBO FIJO", "barrage":"RÁFAGA CERCANA" if game.moves.projection.close_variant else "RÁFAGA", "recover":"RECUPERACIÓN"}.get(game.moves.stage,"")
	metric.text = "%d FPS" % Engine.get_frames_per_second() if bool(game.preferences.values.fps) else "PUNCHLINE · "+BuildInfo.version
	if game.route_trial.active or not game.route_trial.result_text.is_empty(): status.text = game.route_trial.hud_text()
	menu_portrait.visible=menu.visible and selected_tab not in ["settings","controls"]
	menu_title.text = "RUSTCRAWLER" if game.fusion.spider.active() else ("JUNKYARD SENTINEL" if game.fusion.fused else ("ROBOT / "+game.robots.NAMES[game.robots.index] if game.robots.active else "THE PROYECTED"))
	if menu_context != null: menu_context.text = "PUNCHLINE / %s · %s · %d HP · TIEMPO DETENIDO" % [BuildInfo.version,game.form,int(game.hp)]
	var nearest: Dictionary = {}
	var distance := 12.0
	for enemy in game.enemies:
		var d: float = enemy.body.position.distance_to(game.player.position)
		if float(enemy.hp) > 0 and d < distance:
			nearest = enemy
			distance = d
	target_label.text = "" if nearest.is_empty() else "%s  /  %d HP" % [game.DUMMY_NAMES[int(nearest.kind)],int(nearest.hp)]

func nearest_enemy() -> Dictionary:
	var nearest: Dictionary = {}
	var distance := 15.0
	for enemy in game.enemies:
		var candidate: float = enemy.body.global_position.distance_to(game.player.global_position)
		if float(enemy.hp) > 0 and candidate < distance:
			nearest = enemy
			distance = candidate
	return nearest

func refresh_characters() -> void:
	for i in range(character_rows.size()):
		character_rows[i].tooltip_text = "Seleccionado" if i == (1 if game.robots.active else 0) else ("Elegir personaje" if i < 2 else "Próximamente")
	if not game.robots.active: identity.clear_robot_portrait()

func update_robot_hud() -> void:
	phase_text.text = "ROBOT · "+game.robots.NAMES[game.robots.index].to_upper()
	energy_text.text = "ULTIMATE %d%% · %s FUSIÓN%s" % [int(game.charge),game.preferences.key_name("transform")," LISTA" if game.charge >= 100 else ""]
	for i in range(4):
		var exists: bool = game.robots.available(i+1)
		var icon := "kick" if game.robots.index == 0 else ("counter" if game.robots.index == 3 else ("punch" if game.robots.index == 1 or (game.robots.index == 2 and i == 0) else ("kick" if game.robots.index == 2 and i == 2 else "rush")))
		cards[i].panel.set_state(game.robots.title(i+1),game.preferences.key_name("ability"+str(i+1)),game.robots.NAMES[game.robots.index].to_lower()+str(i+1),game.robots.cooldowns[i],[6.0,8.0,7.0,1.0][i],not exists,preload("res://scripts/mecha_move_catalog.gd").base_description(game.robots.index,i+1),(game.skill_active == "robot" and game.robots.attack.get("slot",-1) == i+1) or (game.robots.index == 3 and ((i == 0 and game.robots.guard_time > 0) or (i == 1 and game.robots.counter_time > 0))))

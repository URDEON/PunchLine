extends SceneTree
# Exporta geometría/estado del Control real para revisar un diseño estático.
# No captura la pantalla ni renderiza/simula gameplay.
var game: Node3D
var destination := ""

func _initialize() -> void: call_deferred("run")
func pack(value: Variant) -> Variant:
	if value is Vector2: return [value.x,value.y]
	if value is Color: return "#"+value.to_html(true)
	if value is PackedVector2Array:
		var result := []
		for p in value: result.append(pack(p))
		return result
	if value is Dictionary:
		var result := {}
		for key in value: result[key] = pack(value[key])
		return result
	if value is Array:
		var result := []
		for item in value: result.append(pack(item))
		return result
	return value

func matrix(node: CanvasItem) -> Array:
	var t := node.get_global_transform_with_canvas()
	return [t.x.x,t.x.y,t.y.x,t.y.y,t.origin.x,t.origin.y]

func collect_labels(node: Node, labels: Array) -> void:
	if node is Label and node.is_visible_in_tree() and node.modulate.a > 0.01:
		labels.append({"text":node.text,"matrix":matrix(node),"size":pack(node.size),"font_size":node.get_theme_font_size("font_size"),"ascent":node.get_theme_font("font").get_ascent(node.get_theme_font_size("font_size")),"color":pack(node.get_theme_color("font_color")),"align":node.horizontal_alignment})
	for child in node.get_children(): collect_labels(child,labels)

func run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): destination = argument.trim_prefix("--output=")
	if destination == "": quit(1); return
	DirAccess.make_dir_recursive_absolute(destination)
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.hp = 73
	game.charge = 62
	game.moves.cooldowns.b2 = 6.2
	for enemy in game.enemies: enemy.body.position = Vector3(35,0.1,30)
	game.set_paused(true)
	game.interface.menu.hide()
	for variant in ["base","selector","fase1","fase2","50"]:
		game.end_form()
		game.charge = 62
		game.ult_msg_time = 0
		if variant == "fase1": game.start_form("FORM1",true)
		elif variant == "fase2": game.start_form("FORM2",true)
		game.preferences.set_value("hud_scale",0.5 if variant == "50" else 0.8)
		if variant == "selector": game.interface.toggle_character()
		elif game.interface.character_popup.visible: game.interface.close_character()
		game.set_paused(true)
		game.interface.menu.hide()
		var resolutions := [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1024,768),Vector2i(360,640),Vector2i(640,360),Vector2i(360,360)] if variant == "base" else [Vector2i(1280,720)]
		for resolution in resolutions:
			await export_view(resolution,variant)
	game.feedback.stop_all()
	OS.delay_msec(100)
	game.queue_free()
	await process_frame
	await process_frame
	quit()

func export_view(resolution: Vector2i, variant: String) -> void:
	root.size = resolution
	for i in range(5): await process_frame
	game.interface.tick(1.0)
	await process_frame
	var ui: CanvasLayer = game.interface
	var models := [{"matrix":matrix(ui.identity),"commands":pack(ui.identity.draw_model())}]
	for card in ui.cards: models.append({"matrix":matrix(card.panel),"commands":pack(card.panel.draw_model())})
	var labels := []
	collect_labels(ui.screen,labels)
	var popup := {}
	if ui.character_popup.visible:
		popup = {"position":pack(ui.character_popup.position),"size":pack(ui.character_popup.size),"rows":[]}
		for row in ui.character_rows:
			popup.rows.append({"position":pack(row.get_global_rect().position),"size":pack(row.get_global_rect().size),"text":row.text,"disabled":row.disabled})
	var data := {"kind":"static_design_export_not_gameplay_capture","variant":variant,"resolution":[resolution.x,resolution.y],"models":models,"labels":labels,"character_popup":popup,"menu_button":{"position":pack(ui.menu_button.position),"size":pack(ui.menu_button.size),"text":ui.menu_button.text}}
	var file := FileAccess.open(destination+"/hud_%s_%dx%d.json" % [variant,resolution.x,resolution.y],FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

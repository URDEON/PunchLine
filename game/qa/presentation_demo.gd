extends SceneTree
# Solo QA: posiciona actores y carga la ulti para mostrarla. F5 no usa este script.
var game: Node3D
var title: Label
func _initialize() -> void:
	call_deferred("run")
func frames(n: int) -> void:
	for i in range(n):
		await process_frame
func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	game._unhandled_input(event)
func snapshot(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		root.get_texture().get_image().save_png("user://naoya081_"+name+".png")
func reset_position() -> void:
	game.player.position = Vector3(0, 0.05, 5)
	game.model.rotation.y = 0
	game.yaw = 0.65
	game.pitch = -0.22
	game.zoom = 5.5
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for enemy in game.enemies:
		enemy.body.position = Vector3(35, 0, 35)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var panel := PanelContainer.new()
	layer.add_child(panel)
	panel.position = Vector2(775, 20)
	title = Label.new()
	panel.add_child(title)
	title.add_theme_font_size_override("font_size", 21)
	title.modulate = Color("cebcff")
	reset_position()
	title.text = " GODOT 4.4.1 · EJECUCIÓN REAL\n Demo automatizada · v0.8.2 "
	await frames(20)
	key(KEY_K)
	title.text = " KOGANE · NAOYA\n K invoca / alas y cola animadas "
	game.yaw = PI-0.4
	game.zoom = 3.5
	await frames(40)
	snapshot("kogane")
	title.text = " B · RUNNING MAN\n Baile retargeteado + música "
	key(KEY_B)
	await frames(23)
	snapshot("emote")
	await frames(30)
	reset_position()
	title.text = " 1 · PROYECCIONES\n Siluetas violetas de la pose real "
	await frames(10)
	key(KEY_1)
	await frames(19)
	snapshot("rastro")
	await frames(60)
	title.text = " Q · DASH\n Velocidad normal "
	key(KEY_Q)
	await frames(25)
	reset_position()
	title.text = " G · METAMORFOSIS\n Humano → primera fase "
	game.charge = 100
	key(KEY_G)
	await frames(14)
	snapshot("fase1")
	await frames(36)
	title.text = " 1 · EMBESTIDA\n Rastro también en forma maldita "
	key(KEY_1)
	await frames(40)
	reset_position()
	title.text = " G · EVOLUCIÓN\n Compresión y despliegue de fase 2 "
	game.moves.phase_charge = 100
	key(KEY_G)
	await frames(15)
	snapshot("fase2")
	await frames(40)
	title.text = " KOGANE · PERFILES PREPARADOS\n Nanami / Gojo · prueba técnica "
	game.end_form()
	game.yaw = PI-0.4
	game.zoom = 3.5
	game.presentation.set_character("nanami")
	await frames(25)
	game.presentation.set_character("gojo")
	await frames(25)
	game.presentation.set_character("naoya")
	title.text = " NAOYA · v0.8.2\n B baile · K Kogane · G evolución "
	await frames(25)
	quit()

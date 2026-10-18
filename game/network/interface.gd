extends "res://scripts/interface.gd"
func select_tab(tab: String) -> void:
	if tab in ["settings","controls","character"]: super.select_tab(tab); return
	selected_tab = tab
	for child in menu_content.get_children(): menu_content.remove_child(child); child.queue_free()
	menu_content.add_child(label("PARTIDA ONLINE",22,ACCENT))
	menu_content.add_child(label("El mundo continúa mientras abres el menú. Las habilidades y la vida las controla el anfitrión.",14,MUTED))
	menu_content.add_child(button("CONEXIÓN · NOMBRE · JUGADORES",func() -> void: game.set_paused(false); game.session.arena.toggle_menu()))
	menu_content.add_child(button("LABORATORIO INDIVIDUAL · PRUEBAS COMPLETAS",func() -> void: game.leave_to_scene("res://main.tscn")))
	if menu_grid != null: resize()
func choose_emote(index: int) -> void:
	close_emotes(); game.session.local_action("emote:"+str(index))
func tick(delta: float) -> void:
	super.tick(delta)
	metric.text = "PUNCHLINE · 0.9.24 · ONLINE %d/3" % game.session.roster.size()
	if menu_context != null: menu_context.text = "ONLINE / %s · %s · PARTIDA EN CURSO" % [game.metadata.nickname,("ESTABILIDAD %.0f%%" % (100*game.hp/maxf(1,game.max_hp))) if game.fusion.fused else ("%d HP" % int(game.hp))]
	var nearest := nearest_enemy()
	target_label.text = "" if nearest.is_empty() else "%s / %d HP" % [game.session.roster[int(nearest.peer)].nickname,int(nearest.hp)]

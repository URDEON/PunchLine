extends SceneTree
var checks:=0
var failures:=0
func _initialize()->void:run.call_deferred()
func frames(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func find_button(menu:Control,label:String)->Button:
	for b in menu.buttons:
		if b.text==label:return b
	return null
func run()->void:
	var menu:Control=load("res://launcher.tscn").instantiate()
	root.add_child(menu);current_scene=menu;await frames(25)
	check(menu.title.text=="PUNCHLINE" and menu.buttons.size()==4,"original launcher menu loads with four entries")
	var version: String=str(ProjectSettings.get_setting("application/config/version"))
	check(menu.status.text.begins_with(version) and root.title.contains(version),"launcher and window show the current project version")
	find_button(menu,"AJUSTES").pressed.emit();await frames(3)
	check(menu.current_page=="settings" and menu.content.get_child_count()>1,"settings button opens original settings panel")
	check(menu.find_child("graphics_preset",true,false)!=null,"launcher exposes graphics presets")
	find_button(menu,"VOLVER").pressed.emit();await frames(3)
	find_button(menu,"EXTRAS").pressed.emit();await frames(3)
	check(menu.current_page=="extras" and is_instance_valid(menu.extras),"extras button loads original browser")
	menu.extras.close_requested.emit();await frames(3)
	check(menu.current_page=="home","closing extras restores original home menu")
	var previous:Dictionary=preload("res://scripts/world_config.gd").remembered()
	find_button(menu,"DEMO").pressed.emit();await frames(3)
	check(menu.current_page=="world" and is_instance_valid(menu.world_setup.seed_edit),"DEMO opens editable world settings before starting")
	menu.world_setup.seed_edit.text="Frontend 104";menu.world_setup.density.selected=0;menu.world_setup.night.button_pressed=true;menu.world_setup.destructible.button_pressed=false
	for button in menu.world_setup.get_children():
		if button is Button and button.text=="CREAR MUNDO Y JUGAR":button.pressed.emit();break
	await frames(65)
	var game:Node3D=current_scene
	check(game!=null and game.player!=null and game.rig_scene!=null,"DEMO button enters complete game with player rig")
	check(game.interface.menu_context.text.contains(version),"in-game menu uses the same release version")
	var config=preload("res://scripts/world_config.gd")
	var sparse:Dictionary=config.make_plan(config.current());var dense:Dictionary=config.make_plan({"seed":"Frontend 104","density":2})
	check(game.arena.punchline.housing.get_meta("world_settings").seed=="Frontend 104" and sparse.buildings.size()<dense.buildings.size(),"selected text seed and density create the chosen runtime layout")
	check(not game.arena.punchline.destruction.enabled,"DEMO destructibility checkbox reaches actual physics manager")
	check(game.get_node("ArenaEnvironment").environment.sky.sky_material.panorama.resource_path.ends_with("skybox-night.png"),"selected night setting reaches the actual game environment")
	check(game.interface.character_rows.size()==3 and not game.interface.character_rows[1].disabled,"original character selector exposes player and Robot")
	for e in game.enemies:game.set_dummy_mode(e,0)
	var before:Vector3=game.player.global_position
	Input.action_press("forward");await frames(40);Input.action_release("forward");await frames(5)
	check(game.player.global_position.distance_to(before)>.5,"original movement controls move player in District500")
	game.robots.forced=1
	game.interface.character_rows[1].pressed.emit();await frames(25)
	check(game.robots.active and game.rig_holder.visible and game.robots.current.meshes.size()>0,"Robot selector button loads original animated robot")
	game.punch();await frames(2)
	check(not game.robots.attack.is_empty() and game.rig_anim.is_playing(),"original robot combat starts real attack animation")
	await frames(50)
	game.interface.character_rows[0].pressed.emit();await frames(20)
	check(not game.robots.active and game.rig_holder.visible,"original selector restores The Proyected character")
	print("RESULT ",checks-failures,"/",checks," launcher, menu navigation, character selector and gameplay")
	preload("res://scripts/world_config.gd").select(previous)
	game.queue_free();await frames(8);quit(1 if failures else 0)

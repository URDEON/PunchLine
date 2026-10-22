extends SceneTree
const Command=preload("res://units/soldiers/soldier_command.gd")
var destination: String
func _initialize()->void:run.call_deferred()
func frames(count:int)->void:
	for i in range(count):await process_frame
func capture(label:String)->void:
	await frames(3);await RenderingServer.frame_post_draw
	var error:=root.get_texture().get_image().save_png(destination.path_join(label+".png"))
	if error!=OK:push_error("Capture failed "+label);quit(1)
	print("CAPTURE ",label)
func run()->void:
	if DisplayServer.get_name()=="headless":push_error("Use a graphical renderer");quit(1);return
	destination=OS.get_environment("WARFARE_EVIDENCE_DIR")
	if destination.is_empty():push_error("Set WARFARE_EVIDENCE_DIR");quit(1);return
	DirAccess.make_dir_recursive_absolute(destination)
	Engine.set_meta("warfare_unit","soldier")
	var menu:Control=load("res://ui/warfare_menu.tscn").instantiate();root.add_child(menu);current_scene=menu
	await frames(8);await capture("restored_menu")
	menu.start_practice();await frames(25)
	var game:Node3D=current_scene;var player:CharacterBody3D=game.player
	player.view.pitch=-.08;await capture("soldier_tps")
	player.view.set_first_person(true)
	var command:=Command.new();command.yaw=player.view.yaw;player.command_override=command
	await capture("m4a1_fps_hud")
	player.view.pitch=-1.4;await capture("animated_full_body")
	player.view.pitch=-.08;command.weapon_slot=1;await frames(1);command.weapon_slot=-1
	command.aim=true;await frames(8);await capture("mp5a5_aim")
	command.fire=true;await frames(2);command.fire=false;command.reload=true;await frames(1);command.reload=false
	await capture("soldier_reload")
	game.return_to_menu();await frames(8);menu=current_scene;menu.select_unit("sentinel")
	await capture("sentinel_selection")
	menu.start_practice();await frames(25);game=current_scene;player=game.player
	await capture("sentinel_sci_holo")
	command=Command.new();command.yaw=player.view.yaw;command.aim=true;player.command_override=command
	await frames(12);await capture("sentinel_cannon")
	print("RENDER_SHOOTER_DONE ",RenderingServer.get_current_rendering_method()," / ",RenderingServer.get_video_adapter_name())
	game.queue_free();await frames(4);quit()

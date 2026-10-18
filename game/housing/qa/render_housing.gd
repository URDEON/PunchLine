extends SceneTree
## Actual OpenGL rendering under a desktop or Xvfb; never run with --headless.
var stage:="after"
func _initialize()->void:run.call_deferred()
func frame()->void:
	await process_frame
	await RenderingServer.frame_post_draw
func capture(camera:Camera3D,position:Vector3,target:Vector3,label:String)->void:
	camera.global_position=position;camera.look_at(target)
	for i in range(5):await frame()
	var path:="res://housing/docs/evidence/"+stage+"_"+label+".png"
	var status:=root.get_texture().get_image().save_png(path)
	print("CAPTURE ",path," status=",status)
	if status!=OK:quit(1)
func run()->void:
	if DisplayServer.get_name()=="headless":
		push_error("Rendering checks require a desktop or Xvfb; --headless cannot validate pixels.");quit(1);return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stage="):stage=arg.trim_prefix("--stage=")
	var world:=Node3D.new();root.add_child(world)
	world.add_child(load("res://housing/scenes/District500.tscn").instantiate())
	var housing:Node3D=load("res://housing/scenes/GeneratedHousing.tscn").instantiate();world.add_child(housing)
	for geometry in world.find_children("*","GeometryInstance3D",true,false):geometry.visibility_range_end=0
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("a9c7d5");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("d2e1ed");env.environment.ambient_light_energy=.45
	env.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;world.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-35,0);sun.light_color=Color("fff0d8");sun.light_energy=1.05;sun.shadow_enabled=true;world.add_child(sun)
	var camera:=Camera3D.new();camera.current=true;camera.far=1200;camera.near=.08;camera.fov=65;world.add_child(camera)
	var plan:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/generated_plan.json"))
	var selected:Dictionary=plan.buildings[0]
	var nearest:=INF
	for b in plan.buildings:
		var distance:float=Vector2(b.center[0],b.center[1]).length_squared()
		if b.archetype=="small_residential" and bool(b.style.get("porch",false)) and distance<nearest:selected=b;nearest=distance
	var building:Node3D=housing.get_node("GeneratedBuildings/"+selected.lot+"/"+selected.id)
	print("RENDERER ",RenderingServer.get_video_adapter_name()," ",RenderingServer.get_video_adapter_api_version())
	camera.near=1.0
	await capture(camera,Vector3(30,310,250),Vector3(0,0,-15),"district")
	camera.near=.08
	await capture(camera,building.to_global(Vector3(9,6.5,13)),building.to_global(Vector3(0,1.8,0)),"house")
	await capture(camera,building.to_global(Vector3(0,1.65,1.5)),building.to_global(Vector3(selected.width/2,1.65,selected.depth*.24)),"window")
	print("RENDER_DONE ",stage);world.queue_free();await process_frame;quit(0)

extends SceneTree
var checks:=0
var failures:=0
var game:Node3D
func _initialize()->void:run.call_deferred()
func frames(n:int)->void:
	for i in range(n):await physics_frame
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func visible_count(ambience:Node3D)->int:
	var result:=0
	for batch in ambience.grass:
		if batch.visible:result+=batch.multimesh.visible_instance_count
	return result
func fingerprint(data:RefCounted)->String:
	var digest:=HashingContext.new();digest.start(HashingContext.HASH_SHA256)
	for cell in data.chunks:digest.update(data.chunks[cell].to_byte_array())
	return digest.finish().hex_encode()
func run()->void:
	var config=preload("res://scripts/world_config.gd")
	Engine.set_meta("punchline_world",config.DEFAULTS.duplicate())
	game=load("res://main.tscn").instantiate();root.add_child(game);await frames(25)
	for enemy in game.enemies:game.set_dummy_mode(enemy,0)
	var ambience:Node3D=game.arena.punchline.ambience
	var previous:Dictionary=game.preferences.values.duplicate(true)
	game.preferences.values.grass_quality=2;game.preferences.values.fog_amount=.35;game.preferences.apply()
	print("GREENERY_STATS total=",ambience.placement.count," chunks=",ambience.grass.size()," banks=",ambience.mist.size()," generation_ms=",ambience.ready_ms)
	check(ProjectSettings.get_setting("rendering/renderer/rendering_method")=="forward_plus","project selects Forward+ for native volumetric fog")
	check(ambience.environment==game.get_node("ArenaEnvironment").environment and ambience.environment.volumetric_fog_enabled,"real gameplay environment enables native volumetrics")
	check(ambience.placement.count>50000 and ambience.grass.size()>100,"playable district receives grass across its green lots")
	check(ambience.mist.size()>0 and ambience.mist[0] is FogVolume,"mist uses actual FogVolume nodes with fog shaders")
	check(ambience.find_children("*","CollisionObject3D",true,false).is_empty(),"decoration adds no colliders to movement or climbing")
	var total:=0;var valid_bounds:=true
	for batch in ambience.grass:
		total+=batch.multimesh.instance_count
		valid_bounds=valid_bounds and batch.visibility_range_end<=90 and batch.multimesh.custom_aabb.size.x<=17.01
	check(total==ambience.placement.count and total>ambience.get_child_count()*50,"grass is instanced in bounded chunks without per-blade Nodes")
	check(valid_bounds,"grass drawing distance and chunk bounds stay limited")
	var output:=FileAccess.open("user://greenery_qa.json",FileAccess.WRITE)
	var positions:Array=[]
	for cell in ambience.placement.chunks:
		for point in ambience.placement.chunks[cell]:positions.append([point.x,point.y])
	output.store_string(JSON.stringify({"seed":"923","points":positions,"plan":config.make_plan(config.DEFAULTS)}));output.close()
	print("AUDIT_INPUT ",ProjectSettings.globalize_path("user://greenery_qa.json"))
	var expected_data=preload("res://scripts/district_greenery.gd").new()
	expected_data.prepare(config.make_plan(config.DEFAULTS),"923");expected_data.generate()
	# The visual builder shuffles within chunks, so compare sorted sets rather than iteration order.
	var consistent:bool=expected_data.count==ambience.placement.count
	for cell in expected_data.chunks:
		var actual:Array=Array(ambience.placement.chunks[cell]);actual.sort_custom(func(a:Vector2,b:Vector2)->bool:return a.x<b.x if a.x!=b.x else a.y<b.y)
		var expected:Array=Array(expected_data.chunks[cell]);expected.sort_custom(func(a:Vector2,b:Vector2)->bool:return a.x<b.x if a.x!=b.x else a.y<b.y)
		consistent=consistent and actual==expected
	check(consistent,"same seed reproduces the complete grass placement")
	var first_hash:String=fingerprint(expected_data)
	expected_data.prepare(config.make_plan(config.DEFAULTS),"Otra semilla");expected_data.generate()
	check(fingerprint(expected_data)!=first_hash,"different seed changes grass distribution")
	var medium:int=visible_count(ambience)
	game.preferences.values.grass_quality=1;game.preferences.apply();var low:int=visible_count(ambience)
	game.preferences.values.grass_quality=3;game.preferences.apply();var high:int=visible_count(ambience)
	check(low>0 and low<medium and medium<high,"live quality controls change actual instance density")
	game.preferences.values.grass_quality=0;game.preferences.apply()
	check(visible_count(ambience)==0,"grass can be disabled during gameplay")
	game.preferences.values.fog_amount=0;game.preferences.apply()
	check(not ambience.environment.fog_enabled and not ambience.environment.volumetric_fog_enabled and not ambience.mist[0].visible,"zero intensity disables global and local fog together")
	game.preferences.values.fog_amount=.7;game.preferences.apply()
	check(ambience.environment.volumetric_fog_enabled and ambience.mist[0].visible,"fog can be reenabled without restarting")
	var day:Color=ambience.environment.volumetric_fog_albedo
	ambience.configure_environment(ambience.environment,true)
	check(ambience.environment.volumetric_fog_albedo!=day,"night gets a distinct fog colour")
	ambience.configure_environment(ambience.environment,false)
	var panel:Control=load("res://scripts/settings_panel.gd").new();panel.preferences=game.preferences;root.add_child(panel);await frames(2)
	check(panel.find_child("grass_quality",true,false)!=null and panel.find_child("fog_amount",true,false)!=null,"actual image settings expose grass quality and fog intensity")
	panel.queue_free()
	# Find an unobstructed green route and use the real player controller over grass.
	var route:Vector2=Vector2.ZERO;var found:=false
	for lot in ambience.placement.lots:
		for point in ambience.placement.chunks.get(ambience.placement.key(lot.bounds.get_center()),[]):
			if ambience.placement.safe_in_lot(point,lot,3) and ambience.placement.safe_in_lot(point+Vector2(0,-5),lot,3) and not ambience.placement.blocked(point,3) and not ambience.placement.blocked(point+Vector2(0,-5),3):route=point;found=true;break
		if found:break
	check(found,"test locates an open walking route in a planted lot")
	if found:
		game.preferences.values.grass_quality=2;game.preferences.apply()
		game.player.global_position=Vector3(route.x,.15,route.y);game.player.velocity=Vector3.ZERO;game.yaw=0
		await frames(8);var start:Vector3=game.player.global_position
		Input.action_press("forward");await frames(40);Input.action_release("forward");await frames(4)
		check(game.player.global_position.distance_to(start)>1.5 and absf(game.player.global_position.y-start.y)<.2,"actual player walks through planted grass on original lot collision")
	game.preferences.values=previous;game.preferences.apply()
	print("RESULT ",checks-failures,"/",checks," greenery, settings and real gameplay checks")
	game.queue_free();await frames(8);quit(1 if failures else 0)

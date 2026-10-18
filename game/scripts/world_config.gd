extends RefCounted
## Session settings are also persisted for the next visit to the launcher.
const DEFAULTS={"seed":"923","density":2,"night":false}
static func current()->Dictionary:
	return Engine.get_meta("punchline_world",DEFAULTS).duplicate(true)
static func remembered()->Dictionary:
	var result:=DEFAULTS.duplicate();var file:=ConfigFile.new()
	if file.load("user://world.cfg")==OK:
		for key in result:result[key]=file.get_value("world",key,result[key])
	return result
static func select(settings:Dictionary)->void:
	var result:=DEFAULTS.duplicate();result.merge(settings,true)
	result.seed=String(result.seed).strip_edges().left(48)
	if result.seed.is_empty():result.seed="923"
	result.density=clampi(int(result.density),0,2);result.night=bool(result.night)
	Engine.set_meta("punchline_world",result)
	var file:=ConfigFile.new()
	for key in result:file.set_value("world",key,result[key])
	file.save("user://world.cfg")
static func make_plan(settings:Dictionary)->Dictionary:
	var plan:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/generated_plan.json"))
	var text:String=String(settings.get("seed","923"));var density:int=clampi(int(settings.get("density",2)),0,2)
	var rng:=RandomNumberGenerator.new();rng.seed=text.sha256_text().substr(0,15).hex_to_int()
	var selected:Array=[]
	for original in plan.buildings:
		var b:Dictionary=original.duplicate(true)
		var mecha:bool=String(b.access).begins_with("mecha")
		if not mecha and rng.randf()>[.45,.72,1.0][density]:continue
		if text!="923":
			# Smaller envelopes inside the already validated original rectangle.
			# The six measured mecha routes retain their dimensions and positions.
			if not mecha:
				var old_width:float=b.width;var old_depth:float=b.depth
				b.width=maxf(b.door_width+3,old_width*rng.randf_range(.89,1.0))
				b.depth=maxf(b.door_width+3,old_depth*rng.randf_range(.89,1.0))
			b.style={"palette":rng.randi_range(0,7),"roof_palette":rng.randi_range(0,4),"roof":"gable" if mecha or rng.randf()<.5 else "hip","roof_rise":rng.randf_range(.9,1.3) if mecha else rng.randf_range(1.25,1.95),"porch":rng.randf()<.65,"shutters":rng.randf()<.8,"chimney":rng.randf()<.65,"furniture_side":rng.randi_range(0,1),"sign":rng.randi_range(0,3)}
		b.validated_envelope=original.support_footprint.duplicate(true)
		b.footprint=[];b.support_footprint=[]
		var w:float=b.width/2;var d:float=b.depth/2;var door:float=b.door_width/2
		for p in [Vector2(-w,-d),Vector2(w,-d),Vector2(w,d),Vector2(-w,d)]:b.footprint.append(world_point(b,p))
		for p in [Vector2(-w,-d),Vector2(w,-d),Vector2(w,d),Vector2(door,d),Vector2(door,d+1.2),Vector2(-door,d+1.2),Vector2(-door,d),Vector2(-w,d)]:b.support_footprint.append(world_point(b,p))
		b.entry=world_point(b,Vector2(0,d))
		selected.append(b)
	plan.buildings=selected;plan.seed=text;plan.seed_text=text;plan.density=density
	return plan
static func world_point(b:Dictionary,p:Vector2)->Array:
	return [b.center[0]+cos(b.rotation)*p.x+sin(b.rotation)*p.y,b.center[1]-sin(b.rotation)*p.x+cos(b.rotation)*p.y]

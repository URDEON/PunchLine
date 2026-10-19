extends RefCounted
## Session settings are also persisted for the next visit to the launcher.
const DEFAULTS={"seed":"923","density":2,"night":false,"destructible":true}
static func current()->Dictionary:
	return Engine.get_meta("punchline_world",DEFAULTS).duplicate(true)
static func remembered()->Dictionary:
	var result:=DEFAULTS.duplicate();var file:=ConfigFile.new()
	if file.load("user://world.cfg")==OK:
		for key in result:result[key]=file.get_value("world",key,result[key])
	return result
static func normalized(settings:Dictionary)->Dictionary:
	var result:=DEFAULTS.duplicate()
	for key in result:
		if settings.has(key):result[key]=settings[key]
	result.seed=String(result.seed).strip_edges().left(48)
	if result.seed.is_empty():result.seed="923"
	result.density=clampi(int(result.density),0,2);result.night=bool(result.night);result.destructible=bool(result.destructible)
	return result
static func select(settings:Dictionary)->void:
	var result:=normalized(settings)
	Engine.set_meta("punchline_world",result)
	var file:=ConfigFile.new()
	for key in result:file.set_value("world",key,result[key])
	file.save("user://world.cfg")
static func make_plan(settings:Dictionary)->Dictionary:
	var source:Dictionary=preload("res://housing/scripts/DistrictHousingGenerator.gd").load_plan("res://housing/data/generated_plan.json")
	return preload("res://scripts/seeded_district.gd").new().make(settings,source)
static func world_point(b:Dictionary,p:Vector2)->Array:
	return [b.center[0]+cos(b.rotation)*p.x+sin(b.rotation)*p.y,b.center[1]-sin(b.rotation)*p.x+cos(b.rotation)*p.y]

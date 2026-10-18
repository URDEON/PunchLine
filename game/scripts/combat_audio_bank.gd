extends RefCounted
const ROOT := "res://assets/audio/v098/"
var variants := 0
var sources := {
	"m1_1":preload(ROOT+"m1_1.wav"),"m1_2":preload(ROOT+"m1_2.wav"),
	"m1_3":preload(ROOT+"m1_3.wav"),"m1_4":preload(ROOT+"m1_4.wav"),
	"rush":preload(ROOT+"rush.wav"),"dash":preload(ROOT+"dash.wav"),
	"block":preload(ROOT+"block.wav"),"glass_enter":preload(ROOT+"glass_enter.wav"),
	"evolved_accel":preload(ROOT+"evolved_accel.wav"),"domain_open":preload(ROOT+"domain_open.wav")
}
var bodies: Array[AudioStream] = [preload(ROOT+"body_1.wav"),preload(ROOT+"body_2.wav"),preload(ROOT+"body_3.wav"),preload(ROOT+"body_4.wav")]

func choose(id: String, references: bool) -> Dictionary:
	if references and sources.has(id): return {"stream":sources[id],"pitch":1.0,"reference":true}
	if references and id == "hit":
		variants = (variants+1)%3
		return {"stream":sources["m1_"+str(variants+1)],"pitch":1.0,"reference":true}
	if id in ["heavy","kick","uppercut","downslam","landing"]:
		variants = (variants+1)%bodies.size()
		return {"stream":bodies[variants],"pitch":1.0,"reference":false}
	if id.begins_with("m1_") or id in ["glass_enter","rush","evolved_accel","domain_open"]:
		variants = (variants+1)%bodies.size()
		return {"stream":bodies[variants],"pitch":1.0,"reference":false}
	return {}

extends Node
## Decoupled equivalent of the legacy bounded recorder. No fighter state required.
var samples: Array[Dictionary] = []
var remaining := 0.0
var interval := 0.0
var last_path := ""

func begin(seconds: float = 60.0) -> void:
	samples.clear()
	remaining = clampf(seconds,10,600)
	interval = 0

func snapshot() -> Dictionary:
	return {"time_ms":Time.get_ticks_msec(),"fps":Engine.get_frames_per_second(),
		"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,
		"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,
		"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"objects":Performance.get_monitor(Performance.OBJECT_COUNT),
		"orphans":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"static_memory_bytes":OS.get_static_memory_usage(),
		"physics_bodies":Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS),
		"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}

func _process(delta: float) -> void:
	if remaining<=0: return
	remaining -= delta
	interval -= delta
	if interval<=0:
		interval = 1
		samples.append(snapshot())
	if remaining<=0: save()

func save() -> void:
	if samples.is_empty(): return
	last_path = "user://warfare_performance_"+str(Time.get_ticks_msec())+".json"
	var file := FileAccess.open(last_path,FileAccess.WRITE)
	if file==null:
		push_error("Cannot save performance capture")
		return
	file.store_string(JSON.stringify({"version":BuildInfo.version,
		"renderer":RenderingServer.get_current_rendering_method(),
		"device":RenderingServer.get_video_adapter_name(),"samples":samples},"\t"))
	print("WARFARE_CAPTURE ",ProjectSettings.globalize_path(last_path))
	samples.clear()

func _exit_tree() -> void:
	save()

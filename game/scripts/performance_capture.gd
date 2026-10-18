extends Node
## Optional, bounded recorder. No reference to QA files in shipped builds.
var game: Node3D
var samples: Array[Dictionary] = []
var remaining := 0.0
var interval := 0.0
var last_path := ""
func setup(host: Node3D) -> void: game = host
func begin(seconds: float = 60) -> void:
	samples.clear();remaining = clampf(seconds,10,600);interval = 0
	game.ult_msg = "REGISTRO DE RENDIMIENTO ACTIVO";game.ult_msg_time = 3
func _process(delta: float) -> void:
	if remaining <= 0: return
	remaining -= delta;interval -= delta
	if interval <= 0:
		interval = 1
		samples.append({"time_ms":Time.get_ticks_msec(),"fps":Engine.get_frames_per_second(),"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),"memory_bytes":OS.get_static_memory_usage(),"fusion":game.fusion.fused,"paused":game.paused,"physics_bodies":Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
	if remaining <= 0: save()
func save() -> void:
	if samples.is_empty(): return
	last_path = "user://rendimiento_"+str(Time.get_unix_time_from_system()).replace(".","_")+".json"
	var file := FileAccess.open(last_path,FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify({"version":BuildInfo.version,"renderer":RenderingServer.get_current_rendering_method(),"samples":samples},"\t"))
	print("PERFORMANCE_CAPTURE ",ProjectSettings.globalize_path(last_path))
	samples.clear()
func _exit_tree() -> void: save()

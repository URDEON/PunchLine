extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=2:quit(1);return
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0].path_join("PunchLine_0.9.24_archivos.json")))
	for pack in manifest.packs:
		var path:String=args[0].path_join(pack.name)
		if FileAccess.get_sha256(path)!=pack.sha256 or not ProjectSettings.load_resource_pack(path):push_error("Bad pack "+pack.name);quit(1);return
	var entries:Array=JSON.parse_string(FileAccess.get_file_as_string(args[1]));var checked:=0
	for entry in entries:
		var source:String="res://"+String(entry.path).trim_prefix("res://")
		if FileAccess.get_md5(source)!=entry.md5:push_error("Changed exported file "+source);quit(1);return
		checked+=1
	print("PASS ",checked," archivos exportados idénticos en los paquetes nativos")
	print("RESULTADO 1/1");quit(0)

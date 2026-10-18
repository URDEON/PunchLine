extends SceneTree
## Repackages an already exported pack through Godot's official PCKPacker API.
## It never modifies archive bytes or source scripts.
func _initialize() -> void: build.call_deferred()
func build() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=2:push_error("Expected exported-entry-list.json output-directory");quit(1);return
	var entries:Variant=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not entries is Array:push_error("Invalid exported entries");quit(1);return
	var directory:String=args[1];DirAccess.make_dir_recursive_absolute(directory)
	var groups:Array=[];var group:Array=[];var size:=0
	for entry in entries:
		if size+int(entry.size)>90*1024*1024 and not group.is_empty():groups.append(group);group=[];size=0
		group.append(entry);size+=int(entry.size)
	if not group.is_empty():groups.append(group)
	var manifest:Dictionary={"version":"0.9.24","godot":"4.4.1","packs":[]}
	for index in range(groups.size()):
		var filename: String="PunchLine_0.9.24_Contenido_%02d.pck"%(index+1)
		var path:=directory.path_join(filename);var packer:=PCKPacker.new()
		if packer.pck_start(path)!=OK:push_error("Cannot create "+path);quit(1);return
		for entry in groups[index]:
			var source:String="res://"+String(entry.path).trim_prefix("res://")
			if packer.add_file(source,source)!=OK:push_error("Cannot pack "+source);quit(1);return
		if packer.flush()!=OK:push_error("Cannot flush "+path);quit(1);return
		manifest.packs.append({"name":filename,"sha256":FileAccess.get_sha256(path)})
		print("PACK_CREATED ",filename," entries=",groups[index].size())
	var file:=FileAccess.open(directory.path_join("PunchLine_0.9.24_archivos.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"));file.close();quit(0)

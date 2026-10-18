extends Control
## The Drive distribution uses complete native resource packs, never split bytes.
func _ready() -> void:
	var directory:=OS.get_executable_path().get_base_dir()
	# Allows headless validation with the matching Linux engine.
	if OS.has_feature("editor") and not OS.get_environment("PUNCHLINE_CONTENT_DIR").is_empty():
		directory=OS.get_environment("PUNCHLINE_CONTENT_DIR")
	var path:=directory.path_join("PunchLine_0.9.24_archivos.json")
	var manifest:Variant=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not manifest is Dictionary or manifest.get("version","")!="0.9.24" or manifest.get("packs",[]).is_empty():
		show_error("Falta PunchLine_0.9.24_archivos.json. Extrae toda la carpeta del juego.");return
	for item in manifest.packs:
		var filename:String=item.get("name","")
		if filename.get_file()!=filename or not filename.ends_with(".pck"):
			show_error("La lista de recursos no corresponde a esta entrega.");return
		var content:=directory.path_join(filename)
		if not FileAccess.file_exists(content):show_error("Falta "+filename+". Extrae todos los archivos juntos.");return
		if FileAccess.get_sha256(content)!=item.get("sha256",""):
			show_error("La descarga de "+filename+" está incompleta. Vuelve a descargar ese archivo.");return
		if not ProjectSettings.load_resource_pack(content):show_error("No se pudo abrir "+filename);return
	print("PUNCHLINE_CONTENT_READY 0.9.24 / ",manifest.packs.size()," packs")
	var args:=OS.get_cmdline_user_args()
	var scene:="res://launcher.tscn"
	if args.has("--individual"):scene="res://main.tscn"
	elif args.has("--online"):scene="res://network/online.tscn"
	launch.call_deferred(scene)
func launch(scene:String) -> void:
	if get_tree().change_scene_to_file(scene)!=OK:show_error("No se pudo iniciar PunchLine. Conserva todos los archivos de esta versión juntos.")
func show_error(message:String) -> void:
	push_error(message)
	var background:=ColorRect.new();background.color=Color("131e26");add_child(background);background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var label:=Label.new();add_child(label);label.text="PUNCHLINE 0.9.24\n\n"+message;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);label.offset_left=45;label.offset_top=50;label.offset_right=-45
	var button:=Button.new();add_child(button);button.text="Cerrar";button.position=Vector2(45,220);button.size=Vector2(160,45);button.pressed.connect(func()->void:get_tree().quit())

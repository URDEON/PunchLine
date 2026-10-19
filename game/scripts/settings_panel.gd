extends VBoxContainer
## Los mismos controles persistentes en el inicio y dentro de la partida.
var preferences:Node
var category:="video"
var preview:SubViewportContainer
var fields:VBoxContainer
var navigation:GridContainer
var awaiting:=""
var key_button:Button
var notice:Label
var fade:Tween
const LABELS:={"spider_vision":"Visión de la araña","forward":"Avanzar","back":"Retroceder","left":"Izquierda","right":"Derecha","jump":"Saltar","walk":"Caminar","block":"Bloquear","dash":"Dash","character":"Personaje","ability1":"Habilidad 1","ability2":"Habilidad 2","ability3":"Habilidad 3","ability4":"Habilidad 4","transform":"Transformación","emote":"Emotes","kogane":"Kogane","interact":"Interactuar","lock":"Lock / mirada independiente"}
func skin()->StyleBoxFlat:
 var box:=StyleBoxFlat.new();box.bg_color=Color("102632");box.border_color=Color("467987");box.set_border_width_all(1);box.border_width_bottom=4;box.shadow_color=Color(0,0,0,.35);box.shadow_size=6;box.shadow_offset=Vector2(3,4);box.set_corner_radius_all(5);box.set_content_margin_all(10);return box
func button(text:String,callback:Callable)->Button:
 var node:=Button.new();node.text=text;node.custom_minimum_size.y=34;node.add_theme_stylebox_override("normal",skin());node.pressed.connect(callback);return node
func _ready()->void:
 size_flags_horizontal=Control.SIZE_EXPAND_FILL;add_theme_constant_override("separation",10)
 preview=preload("res://scripts/settings_preview.gd").new();preview.preferences=preferences;preview.custom_minimum_size.y=125;add_child(preview)
 navigation=GridContainer.new();navigation.columns=3;navigation.add_theme_constant_override("h_separation",6);navigation.add_theme_constant_override("v_separation",6);add_child(navigation)
 for pair in [["video","IMAGEN"],["audio","AUDIO"],["camera","CÁMARA"],["interface","INTERFAZ"],["controls","TECLAS"]]:
  var id:String=pair[0];var node:=button(pair[1],func()->void:show_category(id));node.size_flags_horizontal=Control.SIZE_EXPAND_FILL;navigation.add_child(node)
 notice=Label.new();notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;notice.add_theme_font_size_override("font_size",12);notice.modulate=Color("97cbd5");add_child(notice)
 fields=VBoxContainer.new();fields.add_theme_constant_override("separation",9);add_child(fields);show_category(category)
func caption(text:String)->void:
 var label:=Label.new();label.text=text;label.add_theme_font_size_override("font_size",13);label.modulate=Color("b7d3da");fields.add_child(label)
func toggle(key:String,title:String)->void:
 var node:=CheckButton.new();node.name=key;node.text=title;node.button_pressed=bool(preferences.values[key]);node.add_theme_font_size_override("font_size",13);fields.add_child(node)
 node.toggled.connect(func(value:bool)->void:preferences.set_value(key,value))
func slider(key:String,title:String,lo:float,hi:float,step_value:float)->void:
 var row:=HBoxContainer.new();fields.add_child(row);var label:=Label.new();label.text=title;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.add_theme_font_size_override("font_size",13);row.add_child(label)
 var value_label:=Label.new();value_label.add_theme_font_size_override("font_size",12);row.add_child(value_label)
 var node:=HSlider.new();node.name=key;node.min_value=lo;node.max_value=hi;node.step=step_value;node.value=float(preferences.values[key]);node.custom_minimum_size.y=24;fields.add_child(node)
 var display:=func(value:float)->void:value_label.text="%.0f%%"%(value*100) if hi<=1 else "%.2f"%value
 display.call(node.value);node.value_changed.connect(func(value:float)->void:preferences.set_value(key,value);display.call(value))
func show_category(id:String)->void:
 category=id;awaiting="";preview.category=id
 for child in fields.get_children():fields.remove_child(child);child.queue_free()
 notice.text={"video":"Luz, suavizado y presentación. Vista 3D interactiva.","audio":"Mezcla por canales; las barras representan el volumen elegido.","camera":"La lente corporal es exclusiva de la primera persona del Sentinel.","interface":"Escala, animación y ayudas; los cambios se guardan al instante.","controls":"Selecciona una acción y pulsa una tecla. C / clic central: lock por defecto."}[id]
 match id:
  "video":
   caption("Calidad general · luz, vegetación y efectos")
   var preset:=OptionButton.new();preset.name="graphics_preset";fields.add_child(preset)
   for title in ["Rendimiento","Equilibrado","Alto"]:preset.add_item(title)
   preset.selected=int(preferences.values.graphics_preset);preset.item_selected.connect(func(value:int)->void:preferences.set_preset(value);show_category("video"))
   toggle("debris_enabled","Escombros visuales")
   toggle("fullscreen","Pantalla completa");toggle("vsync","Sincronización vertical");toggle("fps","Mostrar FPS")
   var quality:=OptionButton.new();quality.name="quality";fields.add_child(quality)
   for title in ["Sin MSAA","MSAA 2×","MSAA 4×"]:quality.add_item(title)
   quality.selected=int(preferences.values.quality);quality.item_selected.connect(func(value:int)->void:preferences.set_value("quality",value))
   toggle("effects","Partículas y estelas")
   caption("Pasto en zonas verdes")
   var grass:=OptionButton.new();grass.name="grass_quality";fields.add_child(grass)
   for title in ["Desactivado","Bajo / 36 m","Medio / 58 m","Alto / 78 m"]:grass.add_item(title)
   grass.selected=int(preferences.values.grass_quality);grass.item_selected.connect(func(value:int)->void:preferences.set_value("grass_quality",value))
   slider("grass_wind","Viento en el pasto",0,1,.05)
   slider("fog_amount","Niebla volumétrica",0,1,.05)
  "audio":
   for pair in [["master","Volumen general"],["combat","Impactos de combate"],["sfx","Efectos"],["music","Música"],["ambient","Ambiente del dominio"]]:slider(pair[0],pair[1],0,1,.01)
   toggle("reference_audio","Sonidos de tus referencias")
  "camera":
   slider("sensitivity","Sensibilidad",.25,2.5,.05);slider("fov","Campo de visión",60,95,1);slider("camera_distance","Distancia / 0 = primera persona",0,10,.1);slider("body_lens","Ojo de pez / cámara corporal",0,.35,.01);slider("shake","Impactos en cámara",0,1,.05)
   slider("chromatic","Aberración cromática / cámara corporal",0,1,.05);slider("bloom","Bloom / cámara corporal",0,1,.05);slider("lens_dirt","Suciedad de lente",0,1,.05)
   toggle("procedural_gait","Apoyos del Sentinel");toggle("human_grounding","Apoyos de The Proyected");toggle("robot_grounding","Apoyos de robots base")
  "interface":
   slider("hud_scale","Escala del HUD",.5,1,.05);slider("ui_motion","Movimiento de menús",0,1,.05);toggle("hints","Ayuda de controles");toggle("kogane_comments","Comentarios de Kogane");toggle("hold_attack","Encadenar M1 al mantener clic")
  "controls":
   for action in preferences.bindings:
    var id_action:String=action;var row:=HBoxContainer.new();fields.add_child(row);var label:=Label.new();label.text=LABELS.get(action,action);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.add_theme_font_size_override("font_size",12);row.add_child(label)
    var node:=button(preferences.key_name(action),func()->void:pass);node.custom_minimum_size.x=90;row.add_child(node)
    node.pressed.connect(func()->void:awaiting=id_action;key_button=node;node.text="Pulsa tecla…")
 if fade!=null:fade.kill()
 var motion:float=float(preferences.values.ui_motion);fields.modulate.a=.2 if motion>0 else 1
 fade=create_tween();fade.tween_property(fields,"modulate:a",1.0,.18*motion+.001)
func _input(event:InputEvent)->void:
 if awaiting.is_empty() or not is_visible_in_tree() or not event is InputEventKey or not event.pressed or event.echo:return
 get_viewport().set_input_as_handled()
 if event.keycode==KEY_ESCAPE:key_button.text=preferences.key_name(awaiting);awaiting="";return
 for action in preferences.bindings:
  if action!=awaiting and preferences.bindings[action]==event.keycode:notice.text="Esa tecla está asignada a "+LABELS.get(action,action);return
 if event.keycode in [KEY_R,KEY_ALT]:notice.text="R y Alt están reservadas para reiniciar y cursor.";return
 preferences.install_key(awaiting,event.keycode);preferences.save();key_button.text=preferences.key_name(awaiting);notice.text="Control guardado";awaiting=""

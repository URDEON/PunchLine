extends Control
signal close_requested
signal demo_requested(path:String)
var entries:Array=[]
var filtered:Array[int]=[]
var selected:=-1
var filter:="Todo"
var root_box:VBoxContainer
var grid:GridContainer
var list:VBoxContainer
var list_scroll:ScrollContainer
var viewer:SubViewportContainer
var video:VideoStreamPlayer
var detail:Label
var stage:Control
var buttons:Array[Button]=[]
var prototypes:GridContainer
const VIDEOS:=[
 {"title":"ARCHIVO / FUSIÓN 0.9.14","path":"res://assets/media/mechas_v0914.ogv","type":"Videos","caption":"Grabación histórica real de Godot · 0.9.14 · no representa los cambios actuales"},
 {"title":"ARCHIVO / PROYECCIÓN 0.9.8","path":"res://assets/media/proyeccion_v098.ogv","type":"Videos","caption":"Grabación histórica real de Godot · 0.9.8 · no representa los cambios actuales"}]
func button(text:String,callback:Callable)->Button:
 var b:=preload("res://scripts/ink_button.gd").new();b.text=text;b.custom_minimum_size.y=36;b.add_theme_font_size_override("font_size",13);b.pressed.connect(callback);return b
func _ready()->void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var backdrop:=preload("res://scripts/menu_backdrop.gd").new();add_child(backdrop);backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var margin:=MarginContainer.new();add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,18)
 root_box=VBoxContainer.new();root_box.add_theme_constant_override("separation",10);margin.add_child(root_box)
 var header:=HBoxContainer.new();root_box.add_child(header);header.add_child(button("← VOLVER",func()->void:close_requested.emit()))
 var title:=Label.new();title.text="EXTRAS / ARCHIVO PUNCHLINE";title.add_theme_font_size_override("font_size",19);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(title)
 var tabs:=HBoxContainer.new();root_box.add_child(tabs)
 for label in ["Todo","Arte","Modelos","Videos"]:
  var type:String=label;tabs.add_child(button(label,func()->void:filter=type;refresh()))
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;root_box.add_child(scroll)
 grid=GridContainer.new();grid.columns=2;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",18);grid.add_theme_constant_override("v_separation",12);scroll.add_child(grid)
 list_scroll=ScrollContainer.new();list_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;grid.add_child(list_scroll)
 list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list_scroll.add_child(list)
 var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(column)
 stage=Control.new();stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_child(stage)
 viewer=preload("res://scripts/menu_portrait.gd").new();viewer.auto_cycle=false;viewer.interactive=true;stage.add_child(viewer);viewer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);viewer.mouse_filter=Control.MOUSE_FILTER_STOP
 video=VideoStreamPlayer.new();video.loop=true;video.expand=true;video.mouse_filter=Control.MOUSE_FILTER_IGNORE;stage.add_child(video);video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);video.hide()
 detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.add_theme_font_size_override("font_size",12);detail.modulate=Color("a9c5ce");column.add_child(detail)
 var navigation:=HBoxContainer.new();column.add_child(navigation);navigation.add_child(button("← ANTERIOR",func()->void:step(-1)));navigation.add_child(button("SIGUIENTE →",func()->void:step(1)))
 prototypes=GridContainer.new();prototypes.columns=2;root_box.add_child(prototypes)
 prototypes.add_child(button("PROTOTIPO / FUSIÓN G",func()->void:demo_requested.emit("res://FusionDemo.tscn")))
 prototypes.add_child(button("TALLER / CAÑÓN",func()->void:demo_requested.emit("res://CannonDemo.tscn")))
 for i in range(viewer.SUBJECTS.size()):
  var subject:Array=viewer.SUBJECTS[i];entries.append({"title":subject[0],"type":"Arte" if subject[2]=="art" else "Modelos","index":i})
 entries.append_array(VIDEOS);get_viewport().size_changed.connect(resize);resize();refresh()
func resize()->void:
 var extent:=get_viewport_rect().size;var compact:=extent.x<740;grid.columns=1 if compact else 2
 prototypes.columns=1 if compact else 2
 list_scroll.custom_minimum_size=Vector2(0 if compact else 280,125 if compact else maxf(260,extent.y-185))
 stage.custom_minimum_size=Vector2(0 if compact else 360,220 if compact else maxf(280,extent.y-245))
func refresh()->void:
 filtered.clear();buttons.clear()
 for child in list.get_children():list.remove_child(child);child.queue_free()
 for i in range(entries.size()):
  if filter!="Todo" and entries[i].type!=filter:continue
  filtered.append(i);var index:int=i;var node:=button(entries[i].title,func()->void:show_entry(index));node.alignment=HORIZONTAL_ALIGNMENT_LEFT;node.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_child(node);buttons.append(node)
 if not filtered.is_empty():show_entry(filtered[0])
func show_entry(index:int)->void:
 selected=index;video.stop();var entry:Dictionary=entries[index]
 video.visible=entry.type=="Videos";viewer.visible=not video.visible
 if video.visible:video.stream=load(entry.path);video.play();detail.text=entry.caption
 else:
  viewer.show_subject(int(entry.index));detail.text=entry.title+("\nBotón derecho + arrastrar: girar · rueda: acercar" if entry.type=="Modelos" else "\nEstudio visual del juego · recurso original conservado")
 for i in range(buttons.size()):buttons[i].modulate=Color("76e0df") if filtered[i]==index else Color.WHITE
func step(direction:int)->void:
 if filtered.is_empty():return
 show_entry(filtered[posmod(filtered.find(selected)+direction,filtered.size())])
func _exit_tree()->void:
 if is_instance_valid(video):video.stop()

extends "res://launcher.gd"
## Restores the original launcher layout, backdrop, Ink buttons, sounds and portrait.
const Options=preload("res://ui/warfare_options.gd")
func _ready()->void:
 warfare_mode=true
 super._ready()
 WarfareSettings.apply_display()
 var destination:String=Engine.get_meta("warfare_menu_page","home")
 Engine.remove_meta("warfare_menu_page")
 page(destination)

func page(id:String)->void:
 current_page=id
 for child in content.get_children():content.remove_child(child);child.queue_free()
 buttons.clear()
 if is_instance_valid(extras):extras.queue_free();extras=null
 column.show()
 var unit:String=Engine.get_meta("warfare_unit","soldier")
 if id=="home":
  choice("JUGAR",start_practice)
  choice("PRÁCTICA",start_practice)
  choice("SELECCIÓN DE UNIDAD",show_units)
  choice("AJUSTES",show_options)
  choice("EXTRAS / ANIMACIONES",func()->void:page("extras"))
  choice("SALIR",request_quit)
  status.text=BuildInfo.version+" / "+("JUNKYARD SENTINEL" if unit=="sentinel" else "SOLDADO · M4A1 / MP5A5")
  portrait.show_subject(1 if unit=="sentinel" else 0)
 elif id=="units":
  choice("SOLDADO · M4A1 / MP5A5",func()->void:select_unit("soldier"))
  choice("MEGA MECHA · JUNKYARD SENTINEL",func()->void:select_unit("sentinel"))
  choice("DESPLEGAR UNIDAD",start_practice)
  choice("VOLVER",show_home)
  status.text="SELECCIONADO: "+("JUNKYARD SENTINEL" if unit=="sentinel" else "SOLDADO")
  portrait.show_subject(1 if unit=="sentinel" else 0)
 elif id=="extras":
  portrait.show_subject(0)
  var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.custom_minimum_size.y=maxf(140,get_viewport_rect().size.y-390);content.add_child(scroll)
  var rows:=VBoxContainer.new();scroll.add_child(rows);rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  for pair in [["APUNTADO","idle"],["CAMINAR","walk"],["CORRER","run"],["RECARGAR","reload"],["DISPARAR","fire"],["REACCIÓN","hit"],["PASO ATRÁS","step_back"],["GIRO IZQUIERDO","turn_left"],["GIRO DERECHO","turn_right"]]:
   choice(pair[0],preview_animation.bind(pair[1]),rows)
  choice("VOLVER",show_home);status.text="Vista previa de los clips de animación del soldado."
 elif id=="settings":
  var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.custom_minimum_size.y=maxf(100,get_viewport_rect().size.y-300);content.add_child(scroll)
  scroll.add_child(Options.new());choice("VOLVER",show_home)
  status.text="Cámara, accesibilidad y ambiente · ajustes guardados."
 else:page("home");return
 resize_menu()
 if fade!=null:fade.kill()
 content.modulate.a=0;fade=create_tween();fade.tween_property(content,"modulate:a",1.0,.18*motion+.001)
 if not buttons.is_empty():buttons[0].grab_focus()

func resize_menu()->void:
 super.resize_menu()
 title.add_theme_font_size_override("font_size",22 if get_viewport_rect().size.x<720 else 32)
 portrait.visible=current_page in ["home","units","extras"] and get_viewport_rect().size.x>720 and get_viewport_rect().size.y>=500

func select_unit(id:String)->void:
 Engine.set_meta("warfare_unit",id);page("units")
func show_home()->void:page("home")
func show_units()->void:page("units")
func show_options()->void:page("settings")
func preview_animation(label:String)->void:
 if portrait.model!=null:portrait.model.animations.preview_clip(label)
func start_practice()->void:enter("res://game_modes/warfare_practice.tscn")

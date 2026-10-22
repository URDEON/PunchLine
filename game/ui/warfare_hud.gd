extends CanvasLayer
const Options=preload("res://ui/warfare_options.gd")
const Identity=preload("res://scripts/hud_identity.gd")
var game:Node3D
var pause_panel:PanelContainer
var metrics:Label
var identity:Control
var interval:=0.0
var screen:Control
func _ready()->void:
 layer=5;process_mode=Node.PROCESS_MODE_ALWAYS
 screen=Control.new();screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);screen.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(screen)
 var overlay=preload("res://ui/military_overlay.gd").new();overlay.game=game;screen.add_child(overlay)
 if game.player.unit_id=="sentinel":
  identity=Identity.new();screen.add_child(identity);identity.set_holographic(true)
  identity.set_robot_portrait(game.player.visual.model,game.player.visual.model.scale.x,-1,4.0)
  identity.selector_pressed=open_units
 metrics=Label.new();metrics.position=Vector2(24,55);metrics.hide();screen.add_child(metrics)
 pause_panel=PanelContainer.new();pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 pause_panel.offset_left=-210;pause_panel.offset_right=210;pause_panel.offset_top=-320;pause_panel.offset_bottom=320;screen.add_child(pause_panel)
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;pause_panel.add_child(scroll)
 var rows:=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(rows)
 var title:=Label.new();title.text="WARFARE:DISTRICT500 · PAUSA";rows.add_child(title)
 add_button(rows,"CONTINUAR",toggle_pause)
 rows.add_child(Options.new())
 add_button(rows,"REAPARECER",func()->void:game.respawn();toggle_pause())
 add_button(rows,"CAMBIAR UNIDAD",open_units)
 add_button(rows,"MENÚ PRINCIPAL",game.return_to_menu)
 pause_panel.hide()
func add_button(parent:Node,text:String,callback:Callable)->void:
 var button=preload("res://scripts/ink_button.gd").new();button.text=text;button.custom_minimum_size.y=34;parent.add_child(button);button.pressed.connect(callback)
 if game.player.unit_id=="sentinel":button.set_holographic(true)
func toggle_pause()->void:
 get_tree().paused=not get_tree().paused;pause_panel.visible=get_tree().paused
 game.player.equipment.require_trigger_release=true
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if get_tree().paused else Input.MOUSE_MODE_CAPTURED
func open_units()->void:
 Engine.set_meta("warfare_menu_page","units");game.return_to_menu()
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.physical_keycode==KEY_ESCAPE:toggle_pause();get_viewport().set_input_as_handled()
  elif event.physical_keycode==KEY_F3:metrics.visible=not metrics.visible
  elif event.physical_keycode==KEY_F9:game.recorder.begin()
  elif event.physical_keycode==KEY_P:open_units()
func _process(delta:float)->void:
 var pause_width:=minf(420,maxf(260,screen.size.x-32));var pause_height:=minf(660,maxf(220,screen.size.y-48))
 pause_panel.offset_left=-pause_width*.5;pause_panel.offset_right=pause_width*.5;pause_panel.offset_top=-pause_height*.5;pause_panel.offset_bottom=pause_height*.5
 if identity!=null:
  identity.position=Vector2(24,screen.size.y-190);identity.scale=Vector2.ONE*minf(1.0,screen.size.x/1200.0)
  var p:CharacterBody3D=game.player
  identity.update_state(p.health.current/p.health.maximum*100,float(p.equipment.magazines[0])/p.equipment.data.magazine_size*100,"SENTINEL",[p.is_on_floor(),p.movement.locomotion_speed>.1,p.equipment.reload_remaining>0,p.equipment.aiming],"P",delta)
 interval-=delta
 if interval>0:return
 interval=.15
 if metrics.visible:
  var sample:Dictionary=game.recorder.snapshot()
  metrics.text="%s · %d FPS\nProceso %.2f ms · física %.2f ms\nNodos %d · memoria estática %.1f MB\nF9 · captura 60 s" % [BuildInfo.version,sample.fps,sample.process_ms,sample.physics_ms,sample.nodes,sample.static_memory_bytes/1048576.0]

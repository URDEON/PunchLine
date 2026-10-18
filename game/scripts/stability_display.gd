extends Control
## El número y el umbral se derivan exclusivamente de hp/max_hp.
var game:Node3D
var value:=100.0
var clock:=0.0
var alert:Control
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE;size=Vector2(384,52)
 alert=Control.new();game.interface.screen.add_child(alert);alert.mouse_filter=Control.MOUSE_FILTER_IGNORE;alert.draw.connect(draw_alert)
func tick(delta:float)->void:
 clock+=delta;visible=game.fusion.fused
 value=clampf(game.hp/maxf(1,game.max_hp)*100,0,100)
 alert.visible=visible and value<20
 alert.position=Vector2(maxf(8,(game.interface.screen.size.x-310)*.5),12);alert.size=Vector2(310,62)
 if visible:queue_redraw()
 if alert.visible:alert.queue_redraw()
func _draw()->void:
 var critical:=value<20;var color:=Color("ff725b") if critical else Color("71e5df")
 var rect:=Rect2(Vector2.ZERO,Vector2(384,40));draw_style_box(game.interface.style(Color("0b202a"),color*.6,4),rect)
 draw_string(ThemeDB.fallback_font,Vector2(10,14),"ESTABILIDAD DEL NÚCLEO",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("a9c9cf"))
 draw_string(ThemeDB.fallback_font,Vector2(286,20),"%05.1f%%" % value,HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
 for section in range(40):
  var x:=10+float(section)*8.9
  draw_rect(Rect2(x,24,6.2,8),color if float(section)<value*.4 else Color("25424d"))
 draw_line(Vector2(81,22),Vector2(81,35),Color("ffb86d"),1)
func draw_alert()->void:
 var critical:=Color("ff6c50");var alpha:=.72+.15*sin(clock*5)
 var rect:=Rect2(Vector2.ZERO,alert.size)
 alert.draw_style_box(game.interface.style(Color(.08,.018,.012,.9),Color(critical,alpha),5),rect)
 var title:="SEÑAL PERDIDA" if value<=0 else "WARNING / ESTABILIDAD CRÍTICA"
 alert.draw_string(ThemeDB.fallback_font,Vector2(12,23),title,HORIZONTAL_ALIGNMENT_LEFT,-1,14,critical)
 var detail:="ESPERANDO RETIRADA DE RESTOS" if value<=0 else "NÚCLEO %.1f%% · SISTEMAS COMPROMETIDOS" % value
 alert.draw_string(ThemeDB.fallback_font,Vector2(12,46),detail,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f9c4a5"))
func _exit_tree()->void:
 if is_instance_valid(alert):alert.queue_free()

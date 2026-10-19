extends CanvasLayer
## Progress is reported by completed generation stages; the sweep animates every frame.
var progress:ProgressBar
var status:Label
var detail:Label
var sweep:ColorRect
var clock:=0.0
var stages:Array[String]=[]
func _ready()->void:
 layer=100
 var panel:=ColorRect.new();panel.color=Color("09151e");panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(panel)
 var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.add_child(center)
 var column:=VBoxContainer.new();column.custom_minimum_size=Vector2(440,180);column.add_theme_constant_override("separation",18);center.add_child(column)
 var title:=Label.new();title.text="PUNCHLINE";title.add_theme_font_size_override("font_size",38);column.add_child(title)
 status=Label.new();status.text="Preparando el mundo…";status.add_theme_font_size_override("font_size",19);column.add_child(status)
 progress=ProgressBar.new();progress.custom_minimum_size.y=10;progress.show_percentage=false;column.add_child(progress)
 detail=Label.new();detail.text="Calculando el distrito y sus accesos";detail.modulate=Color("a7c1ca");column.add_child(detail)
 sweep=ColorRect.new();sweep.color=Color("e6bc7d");sweep.custom_minimum_size=Vector2(32,3);column.add_child(sweep)
 var version:=Label.new();version.text=BuildInfo.version;version.modulate=Color("738f9e");column.add_child(version)
func report(value:float,text:String)->void:
 progress.value=clampf(value,0,1)*100;status.text=text;stages.append(text)
func _process(delta:float)->void:
 clock+=delta
 sweep.modulate.a=.4+.6*(sin(clock*4)*.5+.5)
 detail.text="El mundo se está preparando"+[" ·"," · ·"," · · ·"][int(clock*3)%3]
func finish()->void:
 report(1,"Mundo listo · preparando la cámara")
 await get_tree().process_frame
 await get_tree().process_frame
 var tween:=create_tween();tween.tween_property(get_child(0),"modulate:a",0,.28);tween.tween_callback(queue_free)

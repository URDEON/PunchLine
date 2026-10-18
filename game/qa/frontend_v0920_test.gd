extends SceneTree
var checks:=0
var passed:=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,title:String)->void:
 checks+=1
 if ok:passed+=1
 print("PASS " if ok else "FAIL ",title)
func frames(n:int)->void:
 for i in range(n):await process_frame
func run()->void:
 var menu:Control=load("res://launcher.tscn").instantiate();root.add_child(menu);await frames(8)
 var labels:Array=[]
 for b in menu.buttons:labels.append(b.text)
 check(labels==["DEMO","MULTIJUGADOR","AJUSTES","EXTRAS"],"inicio tiene exactamente las cuatro opciones solicitadas")
 check(menu.power_button.position.x<30 and menu.power_button.position.y<30,"apagado en esquina superior izquierda")
 menu.request_quit();await frames(3);check(menu.quit_dialog.visible and not auto_accept_quit,"salir solicita confirmación sin cerrar la prueba");menu.quit_dialog.hide()
 menu.page("settings");await frames(8)
 var settings:Node=menu.content.get_child(0).get_child(0)
 check(settings.navigation.get_child_count()==5 and is_instance_valid(settings.preview),"cinco secciones comparten una previsualización 3D real")
 for id in ["video","audio","camera","interface","controls"]:
  settings.show_category(id);await frames(4)
  check(settings.fields.get_child_count()>0 and settings.preview.category==id,"controles y escena responden a sección "+id)
 settings.awaiting="lock";settings.key_button=settings.fields.get_child(settings.fields.get_child_count()-1).get_child(1)
 var key:=InputEventKey.new();key.keycode=KEY_L;key.pressed=true;settings._input(key)
 check(int(menu.profile.preferences.bindings.lock)==KEY_L and settings.awaiting=="","reasignación del lock desde ajustes")
 var config:=ConfigFile.new();config.load("user://preferences_v09.cfg")
 check(int(config.get_value("keys","lock",0))==KEY_L,"tecla lock se guarda en preferencias")
 menu.profile.preferences.install_key("lock",KEY_C);menu.profile.preferences.save()
 for extent in [Vector2i(360,360),Vector2i(360,640),Vector2i(640,360),Vector2i(1280,720)]:
  root.size=extent;await frames(6);menu.page("home");await frames(6)
  check(menu.status.get_global_rect().end.y<=extent.y+1,"inicio cabe en "+str(extent))
  menu.page("settings");await frames(8)
  check(menu.buttons[-1].get_global_rect().end.y<=extent.y+1,"volver de ajustes accesible en "+str(extent))
 root.size=Vector2i(1280,720);menu.page("extras");await frames(12)
 var extras:Control=menu.extras;var kinds:Dictionary={}
 for entry in extras.entries:kinds[entry.type]=true
 check(extras.entries.size()>=25 and kinds.size()==3,"extras incluye arte, modelos y videos existentes")
 var valid:=true
 for subject in extras.viewer.SUBJECTS:valid=valid and ResourceLoader.exists(subject[1])
 for subject in extras.VIDEOS:valid=valid and ResourceLoader.exists(subject.path)
 check(valid,"catálogo completo apunta a recursos disponibles")
 for type in ["Arte","Modelos","Videos"]:
  extras.filter=type;extras.refresh();await frames(6)
  check(not extras.filtered.is_empty() and extras.entries[extras.selected].type==type,"filtro de extras "+type)
 check(extras.video.is_playing() and extras.video.stream!=null,"video histórico inicia reproducción real")
 extras.filter="Modelos";extras.refresh();await frames(8)
 check(extras.viewer.interactive and not extras.viewer.auto_cycle and not extras.video.is_playing(),"visor de modelos permite explorar sin cambiar solo")
 menu.page("home");await frames(6);check(not is_instance_valid(menu.extras),"cerrar extras libera visor y video")
 menu.queue_free();await frames(8)
 print("RESULTADO ",passed,"/",checks);quit(0 if passed==checks else 1)

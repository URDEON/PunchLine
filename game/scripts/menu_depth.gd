extends SubViewportContainer
## Placas y luces 3D reales bajo los controles; no recibe clics ni teclado.
var ui: CanvasLayer
var viewport: SubViewport
var rig: Node3D
var camera: Camera3D
var edges: Array[StandardMaterial3D] = []
var reveal := 1.0
var time := 0.0
var refresh_time:=0.0
var cards:Array[MeshInstance3D]=[]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE; stretch = true; stretch_shrink = 1
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport = SubViewport.new(); viewport.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF; viewport.own_world_3d = true; viewport.transparent_bg = true
	viewport.size = Vector2i(960,540); viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport.gui_disable_input = true; add_child(viewport)
	viewport.msaa_3d=Viewport.MSAA_2X
	rig = Node3D.new(); viewport.add_child(rig)
	for i in range(5):
		var slab := MeshInstance3D.new(); var box := BoxMesh.new()
		box.size = Vector3(10.6-float(i)*.08,5.8-float(i)*.05,.055); slab.mesh = box
		var mat := StandardMaterial3D.new(); mat.albedo_color = Color(.025,.07,.09,.10 if i < 4 else .23)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.metallic = .6; mat.roughness = .28
		slab.material_override = mat; slab.position = Vector3(.05*i,-.035*i,-.16*i)
		rig.add_child(slab)
		for side in [-1,1]:
			var rail := MeshInstance3D.new(); var bar := BoxMesh.new(); bar.size = Vector3(.025,5.65,.07)
			rail.mesh = bar; rail.position = Vector3(side*5.3,.0,slab.position.z)
			var glow := StandardMaterial3D.new(); glow.albedo_color = Color("57c9e4"); glow.emission_enabled = true; glow.emission = Color("225363")
			rail.material_override = glow; rig.add_child(rail); edges.append(glow)
	var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-35,-25,0); light.light_energy = .8; viewport.add_child(light)
	for i in range(3):
		var card:=MeshInstance3D.new();var plate:=BoxMesh.new();plate.size=Vector3(3.1,4.55,.16);card.mesh=plate
		var finish:=StandardMaterial3D.new();finish.albedo_color=Color("153442");finish.metallic=.75;finish.roughness=.28;card.material_override=finish;rig.add_child(card);cards.append(card)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0,0,0,0)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(.4,.6,.7)
	env.environment.ambient_light_energy = .7; viewport.add_child(env)
	camera = Camera3D.new(); camera.fov = 46; camera.position = Vector3(0,0,8.0); camera.current = true; viewport.add_child(camera)
	camera.look_at(Vector3.ZERO)

func _process(delta: float) -> void:
	if viewport == null:return
	if not is_visible_in_tree():viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;return
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	var motion: float = float(ui.game.preferences.values.get("ui_motion",1.0))
	time += delta*motion
	var cursor := get_local_mouse_position()/size.max(Vector2.ONE)*2-Vector2.ONE
	cursor = cursor.clamp(Vector2(-1,-1),Vector2.ONE)*motion
	var target := Vector3(cursor.y*.028,-cursor.x*.045,sin(time*.4)*.004)
	rig.rotation = rig.rotation.lerp(target,1-exp(-delta*8))
	rig.position.z = -1.0*(1-reveal)
	camera.position = camera.position.lerp(Vector3(cursor.x*.16,-cursor.y*.10,8.0),1-exp(-delta*8)); camera.look_at(Vector3.ZERO)
	var tint := Color("59ddf4") if ui.game.robots.active else Color("d1b47b")
	for mat in edges: mat.albedo_color = tint; mat.emission = tint*.28
	for i in range(cards.size()):
		cards[i].visible=ui.selected_tab in ["settings","controls"]
		cards[i].position=Vector3((float(i)-1)*3.3,.05*sin(time*.7+float(i)),.18+float(i)*.035+.35*(1-reveal))
		cards[i].rotation=Vector3(.025*sin(time*.4+float(i)),(float(i)-1)*.065+cursor.x*.025,0)

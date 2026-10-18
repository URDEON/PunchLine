extends Node3D
# Barrio de pruebas: geometría compartida, recorrido legible e interacciones reales.
var game: Node3D
var arena: Node3D
var stations: Array[Dictionary] = []
var expansion: Node3D
var breakables: Array[Dictionary] = []
var nearest := -1
var prompt: Label
var gate: AnimatableBody3D
var gate_open := false
var night := false
var launch_cooldown := 0.0
var message_time := 0.0
var message := ""
var steam: Array[CPUParticles3D] = []
var district := "PLAZA / PROYECCIÓN"
var clock := 0.0
var window_instances := 0
func setup(host: Node3D, terrain: Node3D) -> void:
	game = host; arena = terrain; name = "District24"
	build_skyline(); build_station(); build_details(); build_interactions()
	expansion = preload("res://scripts/district_expansion.gd").new(); add_child(expansion); expansion.setup(game,arena,self)
	var layer := CanvasLayer.new(); layer.layer = 2; add_child(layer)
	prompt = Label.new(); layer.add_child(prompt)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -270; prompt.offset_right = 270; prompt.offset_top = -85; prompt.offset_bottom = -62
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size",16)
	prompt.add_theme_color_override("font_color",Color("dfebea"))
	prompt.add_theme_color_override("font_shadow_color",Color(.01,.02,.03,.9))
	prompt.add_theme_constant_override("shadow_offset_x",1); prompt.add_theme_constant_override("shadow_offset_y",2)
	prompt.hide()
func district_sign(text: String, position: Vector3, color: Color, font_size: int = 40) -> Label3D:
	var label := Label3D.new(); add_child(label); label.text = text; label.position = position
	label.font_size = font_size; label.pixel_size = .009; label.modulate = color
	label.outline_size = 3
	return label
func column(parent: Node3D, position: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new(); parent.add_child(node)
	var mesh := CylinderMesh.new(); mesh.top_radius = radius; mesh.bottom_radius = radius; mesh.height = height; mesh.radial_segments = 12
	node.mesh = mesh; node.position = position; node.material_override = game.get_box_material(color)
	return node
func skyline(position: Vector3, width: float, depth: float, height: float, color: Color, seed_value: int) -> void:
	var building: StaticBody3D = arena.platform(position+Vector3.UP*height*.5,Vector3(width,height,depth),color)
	game.box(building,Vector3(width+.4,.3,depth+.4),Vector3(0,height*.5,0),Color("292e39"))
	var multimesh := MultiMesh.new(); var window_mesh := BoxMesh.new(); window_mesh.size = Vector3(.65,.85,.035)
	multimesh.mesh = window_mesh; multimesh.transform_format = MultiMesh.TRANSFORM_3D; multimesh.use_colors = true
	var rows := int(height/2.2)-1; var columns := int(width/1.8)
	multimesh.instance_count = rows*columns
	var rng := RandomNumberGenerator.new(); rng.seed = seed_value
	for row in range(rows):
		for col in range(columns):
			var index := row*columns+col
			multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY,Vector3((col-(columns-1)*.5)*1.8,-height*.5+2+row*2.2,depth*.5+.025)))
			multimesh.set_instance_color(index,Color("efbe86") if rng.randf() > .62 else (Color("6da9b7") if rng.randf() > .4 else Color("252c39")))
	var windows := MultiMeshInstance3D.new(); building.add_child(windows); windows.multimesh = multimesh
	var material := StandardMaterial3D.new(); material.vertex_color_use_as_albedo = true; material.roughness = .7
	material.emission_enabled = true; material.emission = Color(.07,.10,.13); material.emission_energy_multiplier = .6
	windows.material_override = material; window_instances += multimesh.instance_count
	for side in [-1,1]: game.box(building,Vector3(.18,height,.08),Vector3(side*(width*.5-.3),0,depth*.5+.08),color.lightened(.12))
func build_skyline() -> void:
	for entry in [[Vector3(-38,0,-70),10,10,17],[Vector3(-24,0,-70),12,8,25],[Vector3(-9,0,-70),11,8,19],[Vector3(7,0,-70),13,8,28],[Vector3(23,0,-70),10,8,21],[Vector3(38,0,-70),11,10,16]]:
		skyline(entry[0],entry[1],entry[2],entry[3],Color("343946") if window_instances % 2 else Color("3d3e4a"),window_instances+24)
	# Las casas modulares del distrito sustituyen los dos bloques provisionales
	# de los laterales; sus colisiones antiguas invadían los accesos a las azoteas.

func build_station() -> void:
	arena.platform(Vector3(0,3.75,-26),Vector3(58,.5,5),Color("4e4e56"))
	for x in [-24,-12,12,24]:
		arena.platform(Vector3(x,1.75,-26),Vector3(.9,3.5,.9),Color("484853"))
		game.glow_box(self,Vector3(.055,2,.06),Vector3(x+.46,2,-25.54),Color("d4b984"))
	arena.ramp(Vector3(-33,.04,-13),Vector3(-33,4.04,-27),3.2)
	arena.ramp(Vector3(33,.04,-13),Vector3(33,4.04,-27),3.2)
	# Cubierta curva low-poly, con el hueco de tránsito real por debajo.
	var mesh := ImmediateMesh.new(); mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(24):
		var a := PI*i/24; var b := PI*(i+1)/24
		var p := Vector3(cos(a)*29,5+sin(a)*3,-28.7); var q := Vector3(cos(b)*29,5+sin(b)*3,-28.7)
		for v in [p,q,p+Vector3(0,0,5.4),q,q+Vector3(0,0,5.4),p+Vector3(0,0,5.4)]: mesh.surface_add_vertex(v)
	mesh.surface_end()
	var roof := MeshInstance3D.new(); add_child(roof); roof.mesh = mesh
	var material := game.get_box_material(Color("48414c")).duplicate() as StandardMaterial3D; material.cull_mode = BaseMaterial3D.CULL_DISABLED; roof.material_override = material
	district_sign("ESTACIÓN 24",Vector3(0,6.2,-22.9),Color("f0d6a4"),70)
	district_sign("PROYECCIÓN / DISTRITO DE PRUEBAS",Vector3(0,5.4,-22.85),Color("a5cfd4"),26)
	for x in [-27,-19,-11,11,19,27]:
		game.box(self,Vector3(.06,1,4.6),Vector3(x,4.5,-26),Color("79717d"))
		game.glow_box(self,Vector3(1.4,.04,.3),Vector3(x,4.02,-24.4),Color("8dc5c3"))
	gate = AnimatableBody3D.new(); gate.name = "TransitGate"; add_child(gate); gate.position = Vector3(30,1.7,-15)
	game.box(gate,Vector3(5.2,3.4,.2),Vector3.ZERO,Color("555968"))
	for i in range(6): game.glow_box(gate,Vector3(.04,3.1,.22),Vector3(-2+i*.8,0,0),Color("9dbfcd"))
	var collision := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = Vector3(5.2,3.4,.2)
	collision.shape = shape; gate.add_child(collision)
func build_details() -> void:
	# Soportes y barandas vinculan las azoteas existentes con el barrio.
	for x in [-21.7,-12.3]:
		arena.platform(Vector3(x,2.25,29.5),Vector3(.45,4.5,.45),Color("505263"))
		game.box(self,Vector3(.1,.1,5.6),Vector3(x,5.8,27),Color("767a88"))
		for z in [24.5,27,29.5]: game.box(self,Vector3(.09,.95,.09),Vector3(x,5.3,z),Color("767a88"))
	for p in [Vector3(-34,0,16),Vector3(-34,0,38),Vector3(34,0,38),Vector3(37,0,12),Vector3(-37,0,9)]:
		column(self,p+Vector3.UP*.35,.68,.7,Color("6b6b70"))
		var shrub := column(self,p+Vector3.UP*1.05,.58,.8,Color("4e695e")); shrub.scale.x = 1.25; shrub.rotation.z = .08
	for p in [Vector3(-35,0,12),Vector3(35,0,12),Vector3(-24,0,-18),Vector3(24,0,-18)]:
		game.box(self,Vector3(2.6,.18,.75),p+Vector3.UP*.52,Color("85757c"))
		game.box(self,Vector3(2.6,.55,.15),p+Vector3(0,.95,.3),Color("85757c"))
		for side in [-1,1]: arena.platform(p+Vector3(side*1,.23,0),Vector3(.18,.46,.55),Color("424852"))
	for x in [-29,29]:
		for z in [-20,8,26]:
			column(self,Vector3(x,2.5,z),.065,5,Color("494e59"))
			game.box(self,Vector3(1,.12,.3),Vector3(x+.35,5,z),Color("81818d"))
			game.glow_box(self,Vector3(.75,.03,.24),Vector3(x+.35,4.93,z),Color("edcf98"))
	# Señales peatonales en el suelo, sin cuadrícula de editor sobre toda la plaza.
	for z in [-17,10]:
		for i in range(7): game.box(self,Vector3(.65,.012,3),Vector3(-2.4+i*.8,.014,z),Color("aca6a4"))
	for x in [-32,32]:
		for z in [-7,1,9,25]: game.box(self,Vector3(.09,.015,2.5),Vector3(x,.015,z),Color("b19974"))
	for p in [Vector3(-22,.4,29),Vector3(35,.4,-30)]:
		var smoke := CPUParticles3D.new(); add_child(smoke); smoke.position = p
		smoke.amount = 9; smoke.lifetime = 2.5; smoke.direction = Vector3.UP; smoke.spread = 12
		smoke.gravity = Vector3(.15,.1,0); smoke.initial_velocity_min = .4; smoke.initial_velocity_max = .7
		smoke.scale_amount_min = .18; smoke.scale_amount_max = .35; smoke.color = Color(.7,.78,.8,.17)
		var quad := QuadMesh.new(); var mat := StandardMaterial3D.new(); mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; mat.vertex_color_use_as_albedo = true
		mat.albedo_texture = preload("res://assets/vfx/smoke_01.png"); quad.material = mat; smoke.mesh = quad
		steam.append(smoke)
func station(id: String, caption: String, point: Vector3) -> void:
	stations.append({"id":id,"caption":caption,"point":point})
	game.box(self,Vector3(.5,.85,.4),point+Vector3.UP*.42,Color("414b58"))
	var screen: MeshInstance3D = game.glow_box(self,Vector3(.42,.24,.02),point+Vector3(0,.72,.22),Color("9bcdd0"))
	screen.rotation.x = -.2
	var icon := "shield" if id in ["guard","duel"] else ("flag_square" if id == "route" else ("arrow_rotate" if id == "reset_glass" else "arrow_right"))
	var symbol := Sprite3D.new(); add_child(symbol)
	symbol.texture = load("res://assets/ui/v098/"+icon+".png")
	symbol.pixel_size = .006; symbol.position = point+Vector3(0,.72,.24)
	symbol.modulate = Color("e7cf98"); symbol.shaded = false
	var text := district_sign(caption,point+Vector3.UP*1.13,Color("cde1dc"),20)
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
func build_interactions() -> void:
	station("guard","GUARDIA",Vector3(-9,0,8))
	station("duel","DUELO",Vector3(9,0,8))
	station("route","ECO DE RUTA",Vector3(-5,0,15))
	station("gate","PUERTA DE TRÁNSITO",Vector3(26,0,-12))
	station("lighting","LUZ DEL DISTRITO",Vector3(-26,0,-18))
	station("reset_glass","REARMAR VIDRIOS",Vector3(32,0,6))
	stations.append({"id":"launch","caption":"PLATAFORMA DE IMPULSO","point":Vector3(7,0,22)})
	arena.platform(Vector3(7,.06,22),Vector3(3,.12,3),Color("45616d"))
	for i in range(3): game.glow_box(self,Vector3(1.7,.016,.12),Vector3(7,.13,21.4+i*.5),Color("8ce1da"))
	district_sign("↑ / IMPULSO",Vector3(7,.15,22),Color("bbe4dd"),25).rotation.x = -PI*.5
	for point in [Vector3(28,1.15,2),Vector3(28,1.15,-4),Vector3(28,1.15,-10)]:
		var body := StaticBody3D.new(); add_child(body); body.position = point; body.name = "BreakableGlass"
		var pane := preload("res://scripts/projection_frame.gd").new(); body.add_child(pane); pane.setup()
		var shape := BoxShape3D.new(); shape.size = Vector3(pane.PHOTO_SIZE.x,2.3,.12)
		var collision := CollisionShape3D.new(); collision.shape = shape; body.add_child(collision)
		breakables.append({"body":body,"pane":pane,"broken":false})
	district_sign("M1 / VIDRIO ROMPIBLE",Vector3(28,2.6,4),Color("bcdde9"),22)
func tick(delta: float) -> void:
	if game.player == null: return
	clock += delta; launch_cooldown = maxf(0,launch_cooldown-delta); message_time = maxf(0,message_time-delta)
	if is_instance_valid(gate): gate.position.y = move_toward(gate.position.y,5.3 if gate_open else 1.7,delta*2.5)
	for cloud in steam: cloud.emitting = bool(game.preferences.values.effects)
	nearest = -1; var distance := 2.7
	for i in range(stations.size()):
		var offset: Vector3 = stations[i].point-game.player.global_position
		if absf(offset.y) > 1.8: continue
		offset.y = 0
		if offset.length() < distance: distance = offset.length(); nearest = i
	var p: Vector3 = game.player.position
	district = "BULEVAR / DISTRITO 24" if absf(p.x) > 45 or p.z > 48 else ("ESTACIÓN 24" if p.z < -17 else ("AZOTEAS" if p.x < -10 and p.z > 11 else ("PASO DE VIDRIO" if p.x > 25 else "PLAZA / PROYECCIÓN")))
	prompt.visible = bool(game.preferences.values.hints) and not game.paused and game.moves.domain_time <= 0 and (nearest >= 0 or message_time > 0)
	prompt.text = message if message_time > 0 else (game.preferences.key_name("interact")+" · "+str(stations[nearest].caption) if nearest >= 0 else "")
func notice(text: String) -> void: message = text; message_time = 2.5
func interact() -> bool:
	if nearest < 0 or not game.can_start_action() or game.moves.domain_time > 0: return false
	match stations[nearest].id:
		"gate": gate_open = not gate_open; notice("Tránsito abierto" if gate_open else "Tránsito cerrado")
		"lighting": set_lighting(not night); notice("Distrito · noche" if night else "Distrito · atardecer")
		"launch":
			if not game.player.is_on_floor() or launch_cooldown > 0: return false
			game.player.velocity.y = 15; game.jump_buffer = 0; game.coyote_time = 0; launch_cooldown = 2
			game.feedback.sound("jump",game.player.position); notice("Impulso · controla el aterrizaje")
		"route": game.route_trial.start()
		"reset_glass": reset_glass(); notice("Tres vidrios rearmados")
		"guard","duel":
			var enemy: Dictionary = game.enemies[0]
			game.moves.clear_enemy_frame(enemy); enemy.physics.cancel()
			enemy.hp = 100; enemy.stun = 0; enemy.ragdoll = false; enemy.ragdoll_time = 0; enemy.wakeup_protection = 0
			enemy.body.position = game.player.position+game.facing_forward()*4
			enemy.body.velocity = Vector3.ZERO; enemy.body.reset_physics_interpolation()
			game.set_dummy_mode(enemy,1 if stations[nearest].id == "guard" else 2)
			notice("Prueba guardia: cambia el ángulo" if stations[nearest].id == "guard" else "Duelo: observa, bloquea y responde")
	game.feedback.ui_sound(); return true
func set_lighting(value: bool) -> void:
	night = value
	var sun: DirectionalLight3D = game.get_node("ArenaSun")
	var world: WorldEnvironment = game.get_node("ArenaEnvironment")
	sun.light_energy = .5 if night else 1.05
	sun.light_color = Color("adcde9") if night else Color("fff0dc")
	world.environment.ambient_light_energy = .32 if night else .42
	if expansion != null: expansion.set_sky(night)
func hit_props(origin: Vector3, forward: Vector3) -> int:
	var hits := 0
	for entry in breakables:
		if entry.broken: continue
		var offset: Vector3 = entry.body.global_position-origin-Vector3.UP*1.15
		if absf(offset.y) > 1.5: continue
		offset.y = 0
		if offset.length() > 2.6 or (offset.length() > .01 and offset.normalized().dot(forward) < .35): continue
		var ray := PhysicsRayQueryParameters3D.create(origin+Vector3.UP,entry.body.global_position,1)
		ray.exclude = [game.player.get_rid()]
		var collision := game.get_world_3d().direct_space_state.intersect_ray(ray)
		if not collision.is_empty() and collision.collider != entry.body: continue
		entry.broken = true; entry.body.collision_layer = 0; entry.body.collision_mask = 0; entry.body.hide()
		game.feedback.crystal_break(entry.body.global_transform,entry.pane.PHOTO_SIZE,true); hits += 1
	return hits
func reset_glass() -> void:
	for entry in breakables:
		entry.broken = false; entry.body.collision_layer = 1; entry.body.collision_mask = 1; entry.body.show()

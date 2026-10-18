extends Node3D
# Presentación separada del daño y de los cooldowns.
var game: Node3D
var emote_time := 0.0
var emote_elapsed := 0.0
var transition_time := 0.0
var transition_total := 1.2
var source_form := "BASE"
var swapped := false
var aura: Node3D
var companion: Node3D
var wings: Array[Node3D] = []
var tail: Array[Node3D] = []
var character_id := "naoya"
var ghosts: Array[Dictionary] = []
var ghost_timer := 0.0
var ghost_count := 0
var ghost_position := Vector3.ZERO
var ghost_tracking := false
const GHOST_LIMIT := 4
const GHOST_LIFE := 0.42
const GHOST_ALPHA := 0.22
const GHOST_INTERVAL := 0.10
const GHOST_SPACING := 0.65
var label: Label
var form_models: Array[Node3D] = []
var form_skeletons: Array[Skeleton3D] = []
var shell: MeshInstance3D
var kogane_invoked := false
var dance_name := "dance/RunningMan"
var transition_speed := 1.0
var creature_phase := 0.0
var creature_frequency := 4.5
var creature_amplitude := 0.04
var phase2_tilt := PI/2
var phase2_moving := false
var companion_notice: Label3D
var companion_message := ""
var kogane_skeleton: Skeleton3D
var flap_phase := 0.0
var flap_speed := 18.0
var kogane_reaction := 0.0
# Revisión visual del GLB: la cabeza está en -Z; +Z era la cola.
# Mantener el eje frontal (-Z) de la malla apuntando donde gira la raíz curse.
# La inclinación al correr es local y no da un giro de 90 grados a los golpes.
## The imported mesh's head is -Z and its face is +X.
## Idle: head -> +Y, face -> -Z. Travel: head -> -Z, face -> -Y.
const PHASE2_IDLE := Basis(Vector3.FORWARD,Vector3.RIGHT,Vector3.DOWN)
const PHASE2_TRAVEL := Basis(Vector3.DOWN,Vector3.RIGHT,Vector3.BACK)
const EMOTES := [
	{"name":"Running Man","clip":"dance/RunningMan","speed":1.0,"music":true},
	{"name":"Ven si te atreves","clip":"emotes/Idle_Rail_Call","speed":1.0,"music":false},
	{"name":"Sí, claro","clip":"extras/Yes","speed":1.0,"music":false},
	{"name":"Ni de broma","clip":"extras/Idle_No_Loop","speed":1.0,"music":false},
	{"name":"Brazos cruzados","clip":"extras/Idle_FoldArms_Loop","speed":1.0,"music":false},
	{"name":"Tengo una llamada","clip":"extras/Idle_TalkingPhone_Loop","speed":1.0,"music":false},
	{"name":"Modo zombi","clip":"emotes/Zombie_Idle_Loop","speed":1.0,"music":false},
	{"name":"Mi presentación","clip":"UnarmedActivate","speed":.85,"music":false}
]
var emote_index := 0
var kogane_state := "HIDDEN"
var kogane_transition := 0.0
var comment_life := 0.0
var comment_text := ""
var comment_cooldowns := {}
var comment_revision := 0
const COMMENTS := {
	"damage":["¿Ese golpe era parte de tu estrategia? Qué generoso.","El rival te está leyendo. Y tú ni abriste el libro."],
	"blocked":["Le regalaste otro golpe a la guardia. De nada.","Una pared con piernas. Prueba algo distinto."],
	"projection_miss":["La pared no era el rival, genio.","Velocidad impecable. Dirección… discutible."],
	"counter_miss":["Cinco segundos de exposición. Por fin una pose que te sale.","Buen counter. Solo faltó el enemigo."],
	"counter_hit":["¡Hasta parece que lo tenías calculado!","Qué bonito. Ahora intenta hacerlo dos veces."],
	"enemy_attack":["Ahí viene el puño. Puedes mirar… o bloquear.","Está preparando otro golpe. Te doy esa pista gratis."],
	"enemy_dash":["Se fue de lado. ¿Tus ojos también tienen cooldown?","Mueve los pies: él sí se acordó."],
	"low_hp":["Poca vida. Muchísima confianza.","Te queda una oportunidad. Haz que parezca una estrategia."],
	"emote_hit":["Bailar frente al rival: espectacular forma de perder."],
	"route_best":["Un récord. Qué fastidio: tendré que admitirlo."],
	"route_start":["Tu único rival eres tú. Al menos es un combate parejo."],
	"summon":["¿Otra vez necesitas supervisión? Aquí estoy."]
}
const PROFILES := {
	"naoya": {"body": Color("e5cf8c"), "eyes": Color("211529"), "accent": Color("ba9aff")},
	"nanami": {"body": Color("e8c96c"), "eyes": Color("527078"), "accent": Color("a8e0e1")},
	"gojo": {"body": Color("eee4be"), "eyes": Color("171c30"), "accent": Color("8de7ff")}
}

func setup(host: Node3D) -> void:
	game = host
	set_character("naoya")
	setup_forms()
	var layer := CanvasLayer.new()
	add_child(layer)
	label = Label.new()
	layer.add_child(label)
	label.position = Vector2(20, 670)
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = Color("cab9f4")
	label.hide()
	game.set_rig_loop("UnarmedDeath1", false)

func transparent_material(color: Color, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(color, alpha)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func orb(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	return game.moves.sphere(parent, pos, size, color)

func set_character(id: String) -> void:
	# El selector de personajes futuro solo debe llamar a esta función.
	character_id = id if PROFILES.has(id) else "naoya"
	if is_instance_valid(companion):
		companion.queue_free()
	wings.clear()
	tail.clear()
	companion = Node3D.new()
	add_child(companion)
	var profile: Dictionary = PROFILES[character_id]
	var gold: Color = profile.body
	orb(companion, Vector3.ZERO, Vector3(0.47, 0.34, 0.30), gold)
	for i in range(4):
		orb(companion, Vector3(0, -0.20-i*0.09, 0.05), Vector3(0.28-i*0.035, 0.14, 0.22-i*0.025), gold.darkened(i*0.035))
	for side in [-1, 1]:
		orb(companion, Vector3(side*0.135, 0.055, -0.135), Vector3(0.125, 0.145, 0.065), profile.eyes)
		var wing := Node3D.new()
		companion.add_child(wing)
		wing.position = Vector3(side*0.20, -0.03, 0.08)
		var mesh := ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		mesh.surface_add_vertex(Vector3.ZERO)
		mesh.surface_add_vertex(Vector3(side*0.44, 0.24, 0.03))
		mesh.surface_add_vertex(Vector3(side*0.27, -0.10, 0.14))
		mesh.surface_end()
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.material_override = transparent_material(Color("c9f4f5"), 0.70)
		wing.add_child(visual)
		wings.append(wing)
	if character_id == "naoya":
		# Mandíbula abierta, dientes, antenas y cola: referencia enviada por Edu.
		orb(companion, Vector3(0, -0.085, -0.15), Vector3(0.27, 0.12, 0.09), Color("281d34"))
		for i in range(6):
			game.box(companion, Vector3(0.025, 0.048 if i%2 else 0.07, 0.03), Vector3(-0.10+i*0.04, -0.055, -0.195), Color("fff2d4"))
		for side in [-1, 1]:
			var antenna: MeshInstance3D = game.box(companion, Vector3(0.016, 0.27, 0.02), Vector3(side*0.17, 0.25, 0), gold)
			antenna.rotation.z = side*-0.35
	elif character_id == "gojo":
		game.box(companion, Vector3(0.40, 0.12, 0.045), Vector3(0, 0.055, -0.17), Color("151728"))
	else:
		for side in [-1, 1]:
			game.moves.ring(companion, Vector3(side*0.135, 0.055, -0.174), 0.071, Color("806234")).rotation.x = PI/2
	for i in range(7):
		var segment := orb(companion, Vector3(0, -0.55-i*0.042, 0.05), Vector3(0.035, 0.065, 0.035), Color("322a42"))
		tail.append(segment)
	var tip: MeshInstance3D = game.box(companion, Vector3(0.09, 0.09, 0.018), Vector3(0, -0.88, 0.05), Color("322a42"))
	tip.rotation.z = PI/4
	tail.append(tip)
	if character_id == "naoya":
		for child in companion.get_children():
			if child is Node3D: child.hide()
		var skull: Node3D = preload("res://assets/companions/SkullWispRig.glb").instantiate()
		skull.name = "SkullWisp"
		companion.add_child(skull)
		skull.scale = Vector3.ONE*0.72
		skull.position.y = -0.36
		skull.rotation.y = PI
		kogane_skeleton = game.visual_motion.find_skeleton(skull)
	else:
		kogane_skeleton = null
	companion_notice = Label3D.new()
	companion.add_child(companion_notice)
	companion_notice.position.y = 0.55
	companion_notice.font_size = 28
	companion_notice.pixel_size = 0.005
	companion_notice.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	companion_notice.modulate = Color("e8d8ad")
	companion_notice.hide()
	companion.global_position = game.player.global_position + Vector3(0.95, 2.2, 0.45)
	companion.visible = kogane_invoked

func emote_entries() -> Array:
	if game.fusion.fused: return preload("res://scripts/mecha_emotes.gd").ENTRIES
	return game.robots.EMOTES if game.robots.active else EMOTES

func busy() -> bool:
	return transition_time > 0 or emote_time > 0 or game.preview_time > 0

func toggle_emote() -> void:
	if emote_time > 0:
		cancel_emote()
		return
	game.interface.toggle_emotes()

func start_emote(index: int) -> bool:
	if game.form != "BASE" or not game.can_start_action() or not game.player.is_on_floor():
		return false
	emote_index = clampi(index,0,emote_entries().size()-1)
	dance_name = emote_entries()[emote_index].clip
	if not game.fusion.fused:
		var resolved: StringName = game.resolve_rig_animation(dance_name)
		if resolved == StringName() or not game.rig_anim.has_animation(resolved): return false
	emote_time = 1.0
	emote_elapsed = 0.0
	game.player.velocity.x = 0
	game.player.velocity.z = 0
	if not game.fusion.fused:
		game.locomotion_tree.active = false
		if game.robots.active: game.robots.play(dance_name,emote_entries()[emote_index].speed,true)
		else:
			game.rig_anim.active = true
			game.play_rig_animation(dance_name,.15,emote_entries()[emote_index].speed,true)
	if emote_entries()[emote_index].music: game.feedback.music.play()
	return true

func cancel_emote() -> void:
	emote_time = 0.0
	if game != null and game.feedback.music != null:
		game.feedback.music.stop()

func show_form(form: String) -> void:
	var human := form == "BASE"
	game.rig_holder.visible = human and game.rig_enabled
	game.model.visible = human and not game.rig_enabled
	game.moves.curse.visible = not human
	for node in game.moves.evolution_parts:
		node.hide()
	for node in game.moves.feelers:
		node.visible = form == "FORM2"
	if form_models.size() == 2:
		form_models[0].visible = form == "FORM1"
		form_models[1].visible = form == "FORM2"

func begin_transition(old_form: String) -> void:
	reset()
	source_form = old_form
	transition_total = 2.0 if old_form == "BASE" else 1.6
	transition_time = transition_total
	swapped = false
	show_form(old_form)
	if old_form == "BASE":
		var clip: Animation = game.rig_anim.get_animation(game.resolve_rig_animation("UnarmedDeath1"))
		transition_speed = clip.length/(transition_total*0.55)
		game.play_rig_animation("UnarmedDeath1", 0.08, transition_speed, true)
	aura = Node3D.new()
	add_child(aura)
	game.feedback.sound("charge",game.player.position,-8.0)
	var color := Color("b9e5a2") if game.form == "FORM2" else Color("c3e4ac")
	for i in range(3):
		var hoop: MeshInstance3D = game.moves.ring(aura, Vector3(0, 0.3+i*0.6, 0), 0.65-i*0.08, color)
		hoop.rotation.x = i*0.35
	if old_form != "BASE":
		shell = orb(aura,Vector3(0,0.95,0),Vector3(1.3,1.3,2.1),Color("8eaa7c"))

func reset() -> void:
	cancel_emote()
	ghost_tracking = false
	ghost_timer = 0
	for ghost in ghosts:
		ghost.node.queue_free()
	ghosts.clear()
	transition_time = 0
	if is_instance_valid(aura):
		aura.queue_free()
	aura = null
	shell = null
	if game != null:
		game.moves.curse.scale = Vector3.ONE
		show_form(game.form)

func animate_rig() -> bool:
	if emote_time > 0:
		if game.fusion.fused: return true
		if game.robots.active: game.robots.play(dance_name,emote_entries()[emote_index].speed)
		else:
			game.rig_anim.active = true
			game.play_rig_animation(dance_name,.15,emote_entries()[emote_index].speed)
		return true
	if transition_time > 0 and source_form == "BASE" and not swapped:
		game.play_rig_animation("UnarmedDeath1",0.10,transition_speed)
		return true
	return false

func toggle_kogane() -> void:
	if not game.can_start_action():
		return
	kogane_invoked = not kogane_invoked
	if kogane_invoked:
		companion.show(); companion.scale = Vector3.ONE*.12
		kogane_state = "ENTER"; kogane_transition = 0.0
		companion.global_position = game.player.global_position+Vector3.UP*1.4
		game.feedback.sound("kogane",companion.global_position,-13.0)
		comment("summon")
	else:
		kogane_state = "EXIT"; kogane_transition = 0.0
		companion_notice.hide()
		game.feedback.sound("dash",companion.global_position,-20.0)

func comment(event: String) -> void:
	if not kogane_invoked or not bool(game.preferences.values.kogane_comments) or not COMMENTS.has(event): return
	if float(comment_cooldowns.get(event,0)) > 0 or comment_life > 2.5: return
	var choices: Array = COMMENTS[event]
	comment_text = choices[comment_revision%choices.size()]; comment_revision += 1
	comment_life = 4.0; comment_cooldowns[event] = 6.0 if event != "enemy_attack" else 10.0

func setup_forms() -> void:
	for node in game.moves.curse.get_children():
		node.hide()
	for path in ["res://assets/forms/worm_rig.tscn","res://assets/forms/evolved_rig.tscn"]:
		var model: Node3D = load(path).instantiate()
		game.moves.curse.add_child(model)
		model.position.y = 1.0
		model.hide()
		form_models.append(model)
		form_skeletons.append(model.get_node("Skeleton3D"))
	form_models[1].basis = PHASE2_IDLE
	form_models[1].position.y = 1.65
	for feeler in game.moves.feelers: feeler.reparent(form_models[1],true)

func animate_phase2(delta: float, speed: float) -> void:
	if game.form != "FORM2" or game.moves.player_freeze > 0: return
	if speed > 0.35: phase2_moving = true
	elif speed < 0.12: phase2_moving = false
	var target_basis: Basis = PHASE2_TRAVEL if phase2_moving else PHASE2_IDLE
	form_models[1].basis = Basis(form_models[1].quaternion.slerp(target_basis.get_rotation_quaternion(),1-exp(-delta*9)))
	form_models[1].position.y = lerpf(form_models[1].position.y,1.05 if phase2_moving else 1.65,1-exp(-delta*9))+sin(game.clock*2.4)*0.001

func kogane_status() -> String:
	if game.moves.player_freeze > 0: return "Fotograma · %.1f s" % game.moves.player_freeze
	if game.moves.domain_time > 0: return "Dominio · %d s" % ceili(game.moves.domain_time)
	if game.form == "FORM1" and game.moves.phase_charge >= 100: return "Evolución lista · G"
	if game.ult_ready(): return "Transformación lista · G"
	if game.hp <= 30: return "Vida baja"
	if kogane_reaction > 0: return "Counter confirmado"
	return ""

func collect_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and node.is_visible_in_tree() and node.mesh != null:
		result.append(node)
	for child in node.get_children():
		collect_meshes(child, result)

func afterimage() -> void:
	if not bool(game.preferences.values.effects) or ghosts.size() >= GHOST_LIMIT:
		return
	if game.moves.key == "b1" and game.form == "BASE" and game.rig_enabled:
		var echo := preload("res://scripts/projection_echo.gd").new()
		add_child(echo); echo.setup()
		echo.global_transform = Transform3D(Basis(Vector3.UP,game.model.rotation.y),game.player.global_position+Vector3.UP*1.15)
		var pose: ArrayMesh = game.moves.projection.pose_mesh
		if pose != null: echo.set_pose(pose)
		echo.set_opacity(.65)
		ghosts.append({"node":echo,"material":echo.ink,"life":GHOST_LIFE,"glass":true})
		ghost_count += 1
		return
	var root := Node3D.new()
	add_child(root)
	var material := transparent_material(Color("ad91ff"), GHOST_ALPHA)
	var meshes: Array[MeshInstance3D] = []
	collect_meshes(game.rig_holder if game.form == "BASE" and game.rig_enabled else (game.model if game.form == "BASE" else game.moves.curse), meshes)
	for source in meshes:
		var visual := MeshInstance3D.new()
		# Congela la pose actual; nunca duplica un AnimationPlayer ni el collider.
		if DisplayServer.get_name() != "headless" and source.skin != null and source.has_method("bake_mesh_from_current_skeleton_pose"):
			visual.mesh = source.bake_mesh_from_current_skeleton_pose()
		else:
			visual.mesh = source.mesh
		visual.material_override = material
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(visual)
		visual.global_transform = source.global_transform
	ghosts.append({"node": root, "material": material, "life": GHOST_LIFE})
	ghost_count += 1

func tick(delta: float) -> void:
	if game.preview_time > 0 and (game.movement().length() > .1 or game.stun > 0): game.preview_time = 0
	if emote_time > 0:
		if game.movement().length() > 0.1 or game.input_pressed("block") or game.stun > 0 or game.player_ragdoll or game.moves.player_freeze > 0 or game.hp <= 0 or not game.grounded_for_actions():
			cancel_emote()
		else:
			emote_elapsed += delta
			if game.fusion.fused:
				var duration: float = emote_entries()[emote_index].duration
				if duration > 0 and emote_elapsed >= duration: cancel_emote()
			else:
				var emote: Animation = game.rig_anim.get_animation(game.resolve_rig_animation(dance_name))
				if emote.loop_mode == Animation.LOOP_NONE and emote_elapsed > emote.length/emote_entries()[emote_index].speed+.15: cancel_emote()

	if transition_time > 0:
		if game.stun > 0 or game.player_ragdoll:
			reset()
		else:
			transition_time = maxf(0, transition_time-delta)
			var progress := 1.0-transition_time/transition_total
			aura.global_position = game.player.global_position
			aura.rotation.y += delta*6
			aura.scale = Vector3.ONE*(0.65+sin(progress*PI)*0.7)
			if progress >= 0.55 and not swapped:
				swapped = true
				show_form(game.form)
				if is_instance_valid(shell):
					shell.hide()
				game.feedback.shatter(game.player.position+Vector3.UP,Color("d0e6b7"),true)
				game.feedback.particles(game.player.position+Vector3.UP,Color("bcdfa0"),true,22)
				game.moves.pulse(game.player.position,Color("b9e69b"),1.5)
			if swapped:
				game.moves.curse.scale = Vector3.ONE*lerpf(0.40, 1.0, smoothstep(0.55, 1.0, progress))
			elif source_form != "BASE":
				game.moves.curse.scale = Vector3(1.0, 1.0-progress*0.6, 1.0+progress*0.35)
			if transition_time <= 0:
				reset()
	var speed: float = Vector2(game.player.velocity.x,game.player.velocity.z).length()
	animate_phase2(delta,speed)
	var frequency := 4.5 + minf(speed,40)*0.19
	creature_frequency = lerpf(creature_frequency,frequency,1-exp(-delta*6))
	creature_amplitude = lerpf(creature_amplitude,0.025+minf(speed,12)*0.0025,1-exp(-delta*7))
	creature_phase += delta*creature_frequency
	for skeleton in form_skeletons:
		if skeleton.is_visible_in_tree() and game.moves.player_freeze <= 0:
			for i in range(1,skeleton.get_bone_count()):
				var wave := sin(creature_phase-i*0.6)
				var yaw_pose := Quaternion(Vector3.UP,wave*creature_amplitude)
				var pitch_pose := Quaternion(Vector3.RIGHT,sin(creature_phase*0.5-i*0.35)*0.012)
				skeleton.set_bone_pose_rotation(i,yaw_pose*pitch_pose)
	ghost_timer -= delta
	var tracing: bool = game.moves.key in ["b1","u1"] and game.moves.stage in ["approach", "commit", "barrage"]
	if not tracing:
		ghost_tracking = false
	elif not ghost_tracking:
		ghost_tracking = true
		ghost_position = game.player.global_position
		ghost_timer = 0
	if tracing and ghost_timer <= 0 and game.player.global_position.distance_to(ghost_position) >= GHOST_SPACING:
		afterimage()
		ghost_position = game.player.global_position
		ghost_timer = GHOST_INTERVAL
	for i in range(ghosts.size()-1, -1, -1):
		ghosts[i].life -= delta
		if ghosts[i].life <= 0:
			ghosts[i].node.queue_free()
			ghosts.remove_at(i)
		else:
			if bool(ghosts[i].get("glass",false)): ghosts[i].node.set_opacity(.65*smoothstep(0,GHOST_LIFE,ghosts[i].life))
			else: ghosts[i].material.albedo_color.a = GHOST_ALPHA*ghosts[i].life/GHOST_LIFE
	kogane_reaction = maxf(0,kogane_reaction-delta)
	if game.moves.key == "b2" and game.moves.stage == "counter_hit": kogane_reaction = 1.0
	for event in comment_cooldowns: comment_cooldowns[event] = maxf(0,float(comment_cooldowns[event])-delta)
	comment_life = maxf(0,comment_life-delta)
	if game.hp <= 30: comment("low_hp")
	companion_message = kogane_status()
	companion_notice.text = comment_text if comment_life > 0 else companion_message
	companion_notice.font_size = 22
	companion_notice.width = 330
	companion_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	companion_notice.visible = kogane_invoked and (comment_life > 0 or not companion_message.is_empty())
	var offset := Vector3(1.5 if game.fusion.fused else 0.95, (4.1 if game.fusion.fused else 2.1)+sin(game.clock*2.8)*0.09+sin(kogane_reaction*PI)*0.10, 0.55).rotated(Vector3.UP, game.model.rotation.y)
	var destination: Vector3 = game.player.global_position+offset
	if kogane_state == "ENTER":
		kogane_transition = minf(1,kogane_transition+delta/1.25)
		var progress := smoothstep(0,1,kogane_transition)
		var angle: float = game.model.rotation.y+TAU*progress
		var orbit: Vector3 = game.player.global_position+Vector3(sin(angle)*1.35,1.5+progress*.6,cos(angle)*1.35)
		companion.global_position = orbit.lerp(destination,smoothstep(.65,1,progress))
		companion.scale = Vector3.ONE*lerpf(.12,1.0,smoothstep(0,.35,progress))
		if kogane_transition >= 1: kogane_state = "FOLLOW"
	elif kogane_state == "EXIT":
		kogane_transition = minf(1,kogane_transition+delta/.55)
		companion.scale = Vector3.ONE*(1-smoothstep(0,1,kogane_transition))
		companion.global_position = companion.global_position.lerp(game.player.global_position+Vector3.UP*1.7,delta*5)
		if kogane_transition >= 1:
			game.feedback.particles(companion.global_position,Color.WHITE,true,5)
			companion.hide(); companion.scale = Vector3.ONE; kogane_state = "HIDDEN"
	elif companion.global_position.distance_to(destination) > 8:
		companion.global_position = destination
	else:
		companion.global_position = companion.global_position.lerp(destination, 1-exp(-delta*8))
	companion.rotation.y = lerp_angle(companion.rotation.y, game.model.rotation.y, minf(1, delta*8))
	companion.rotation.x = lerp_angle(companion.rotation.x,clampf(game.player.velocity.z*0.006,-0.08,0.08)+sin(game.clock*2.7)*0.025,1-exp(-delta*5))
	companion.rotation.z = lerp_angle(companion.rotation.z,clampf(-game.player.velocity.x*0.006,-0.09,0.09)+sin(game.clock*2.1)*0.035,1-exp(-delta*5))
	flap_speed = lerpf(flap_speed,18.0+sin(game.clock*0.7)*2.2+minf(speed,12)*0.22,1-exp(-delta*3))
	flap_phase += delta*flap_speed
	if is_instance_valid(kogane_skeleton):
		for entry in [["WingL",1.0],["WingR",-1.0]]:
			var index := kogane_skeleton.find_bone(entry[0])
			var axis := kogane_skeleton.get_bone_global_rest(index).basis.inverse()*Vector3.FORWARD
			var angle: float = sin(flap_phase)*0.36*entry[1]
			kogane_skeleton.set_bone_pose_rotation(index,kogane_skeleton.get_bone_rest(index).basis.get_rotation_quaternion()*Quaternion(axis.normalized(),angle))
		var tail_index := kogane_skeleton.find_bone("Tail")
		var tail_axis := kogane_skeleton.get_bone_global_rest(tail_index).basis.inverse()*Vector3.FORWARD
		kogane_skeleton.set_bone_pose_rotation(tail_index,kogane_skeleton.get_bone_rest(tail_index).basis.get_rotation_quaternion()*Quaternion(tail_axis.normalized(),sin(flap_phase*0.18)*0.06))
	for i in range(wings.size()):
		wings[i].rotation.z = sin(game.clock*32)*(0.30 if i == 0 else -0.30)
	for i in range(tail.size()):
		tail[i].position.x = sin(game.clock*4-i*0.45)*0.035*i/7.0
	label.text = "B · RUNNING MAN  |  K · "+("Retirar" if kogane_invoked else "Invocar")+" Kogane"
	if emote_time > 0:
		label.text = "RUNNING MAN · B o movimiento para cancelar"
	elif transition_time > 0:
		label.text = "METAMORFOSIS · FASE 1" if game.form == "FORM1" else "EVOLUCIÓN · FASE 2"

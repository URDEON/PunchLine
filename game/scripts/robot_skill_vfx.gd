extends Node3D
# Efectos ligados a contactos y estados reales, sin decidir daño.
const ENERGY := preload("res://shaders/combat_energy.gdshader")
const PALETTES := [Color("65e3ef"),Color("ffae62"),Color("91bfff"),Color("94f0c2")]
var game: Node3D
var effects: Array[Dictionary] = []
var cast_token := -1
var emitted := 0
var trails: Array[Dictionary] = []
var dust: Node3D
var guard_shield: MeshInstance3D
var jets: Node3D
var clock := 0.0
var shots: Dictionary = {}
const MAX_EFFECTS := 72

func setup(host: Node3D) -> void:
	game = host
	dust = preload("res://scripts/mecha_dust.gd").new(); add_child(dust)

func enabled() -> bool: return bool(game.preferences.values.effects)

func cast(slot: int) -> void:
	var session: Node = game.online_session()
	if session != null: session.robot_skill_effect.rpc(game.peer_id,slot,game.player.global_position,false,game.robots.revision)
	else: cast_local(slot,game.robots.revision)

func contact(slot: int,point: Vector3) -> void:
	if slot < 0: return
	var session: Node = game.online_session()
	if session != null: session.robot_skill_effect.rpc(game.peer_id,slot,point,true,game.robots.revision)
	else: impact_local(slot,point)

func mega_event(stage: String,point: Vector3,direction: Vector3,move: String,token: int) -> void:
	var data := {"stage":stage,"point":point,"direction":direction,"move":move,"token":token}
	var session: Node = game.online_session()
	if session != null: session.mecha_skill_effect.rpc(game.peer_id,data)
	else: mega_local(data)

func energy(point: Vector3, dimensions: Vector2, tint: Color, mode: int, life: float, facing: Vector3 = Vector3.ZERO, grow: float = 0, bone: String = "") -> MeshInstance3D:
	if effects.size() >= MAX_EFFECTS or not enabled(): return null
	var node := MeshInstance3D.new(); var quad := QuadMesh.new(); quad.size = dimensions; node.mesh = quad
	var material := ShaderMaterial.new(); material.shader = ENERGY
	material.set_shader_parameter("tint",tint); material.set_shader_parameter("mode",mode); material.set_shader_parameter("age",.01)
	material.set_shader_parameter("billboard",facing == Vector3.ZERO)
	node.material_override = material; node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node); node.global_position = point
	if facing != Vector3.ZERO:
		node.look_at(point+facing,Vector3.FORWARD if absf(facing.dot(Vector3.UP)) > .95 else Vector3.UP)
	effects.append({"node":node,"life":life,"total":life,"grow":grow,"bone":bone,"velocity":Vector3.ZERO,"gravity":false}); emitted += 1
	return node

func socket(bone: String) -> Vector3:
	if game.fusion.fused and game.fusion.sequence != null and game.fusion.sequence.articulation != null:
		var mapping := {"PalmI.R":"Mano_Der","PalmI.L":"Mano_Izq","Foot.R":"Pie_Der","Foot.L":"Pie_Izq","Chest":"Torso_Pecho"}
		if mapping.has(bone): return game.fusion.sequence.articulation.pivots[mapping[bone]].global_position
	if not game.robots.current.is_empty():
		var sk: Skeleton3D = game.robots.current.skeleton
		var index := sk.find_bone(bone)
		if index >= 0: return (sk.global_transform*sk.get_bone_global_pose(index)).origin
	return game.player.global_position+Vector3.UP

func sparks(point: Vector3, tint: Color, strength: float) -> void:
	for i in range(7):
		var node := energy(point,Vector2(.09,.23)*strength,tint,0,.28+float(i%3)*.08)
		if node == null: break
		var angle := float(i)*2.39996
		effects[-1].velocity = Vector3(cos(angle),.5+float(i%3)*.3,sin(angle))*(1.8+strength)
		effects[-1].gravity = true

func ground_burst(point: Vector3, strength: float, tint: Color) -> void:
	dust.puff(point,strength)
	energy(point+Vector3.UP*.035,Vector2.ONE*strength*2.8,tint,4,.55,Vector3.UP,2)
	# Fragmentos pequeños y oscuros, con trayectorias finitas; no hay cuerpos físicos extra.
	for i in range(8):
		if effects.size() >= MAX_EFFECTS: break
		var node := MeshInstance3D.new(); var rock := BoxMesh.new(); rock.size = Vector3(.09,.07,.13)*strength
		var mat := StandardMaterial3D.new(); mat.albedo_color = Color("57514b"); mat.roughness = 1
		node.mesh = rock; node.material_override = mat; add_child(node); node.global_position = point+Vector3.UP*.08
		var angle := i*2.39996
		effects.append({"node":node,"life":.65,"total":.65,"grow":0,"bone":"","velocity":Vector3(cos(angle)*1.4,2.5+float(i%3)*.5,sin(angle)*1.4)*strength,"gravity":true})

func cast_local(slot: int,token: int) -> void:
	if not game.robots.active or not enabled(): return
	if token == cast_token: return
	cast_token = token
	var index: int = game.robots.index; var tint: Color = PALETTES[index]
	var bone := "Foot.R" if index == 0 else "PalmI.R"
	var lifetime: float = float(game.robots.attack.get("duration",.8))
	if slot == 0:
		energy(socket(bone),Vector2.ONE*.45,tint,0,lifetime,Vector3.ZERO,.1,bone)
		trails.append({"bone":bone,"tint":tint,"life":lifetime,"last":socket(bone),"clock":0.0,"width":.15})
		return
	if index == 3:
		if slot == 1:
			energy(game.player.global_position+Vector3.UP,Vector2(2.1,2.6),tint,2,1.6,game.facing_forward(),0,"shield")
		else:
			energy(socket("Chest"),Vector2.ONE*1.3,Color("ffd48d"),2,.45,Vector3.ZERO,0,"Chest")
	else:
		energy(socket(bone),Vector2.ONE*(.9 if index == 1 else .6),tint,0,lifetime,Vector3.ZERO,.35,bone)
		trails.append({"bone":bone,"tint":tint,"life":lifetime,"last":socket(bone),"clock":0.0,"width":.28 if index == 0 else .21})
		if index == 2 and slot == 1: trails.append({"bone":"PalmI.L","tint":tint,"life":lifetime,"last":socket("PalmI.L"),"clock":0.0,"width":.18})
		if index == 0 and slot == 2: dust.puff(game.player.global_position,.6,Color(.8,.85,.85),false)
	game.feedback.sound("mecha_servo_3" if index == 1 else "mecha_servo_1",game.player.global_position,-10)

func impact_local(slot: int,point: Vector3) -> void:
	if not game.robots.active or not enabled(): return
	var tint: Color = PALETTES[game.robots.index]
	energy(point,Vector2.ONE*1.3,Color.WHITE,0,.18,Vector3.ZERO,1.2)
	sparks(point,tint,1)
	energy(point,Vector2.ONE*1.8,tint,1,.35,Vector3.ZERO,1)
	if game.robots.index == 1 or (game.robots.index == 0 and slot == 3):
		var ground := point; ground.y = game.player.global_position.y+.03
		ground_burst(ground,.7,tint)

func mega_local(data: Dictionary) -> void:
	if data.stage=="critical_blast":
		var blast:=preload("res://scripts/critical_blast.gd").new()
		game.get_parent().add_child(blast);blast.global_position=data.point;blast.wave.position.y=-data.point.y+.12
		dust.crown(data.point-Vector3.UP*1.4,4.0);dust.puff(data.point,4.0)
		game.fusion.impulse(data.point,2.5);return
	if data.stage == "land":
		if enabled(): dust.crown(data.point,1.05); dust.puff(data.point,1.1)
		return
	if not enabled(): return
	var point: Vector3 = data.point; var direction: Vector3 = data.direction
	var tint := Color("ffbd79") if data.move == "cannon" else Color("88daff")
	match String(data.stage):
		"prepare":
			var bone := "PalmI.R" if data.move in ["cannon","hammer","m1_hammer"] else "Foot.R"
			energy(socket(bone),Vector2.ONE*1.6,tint,0,.95,Vector3.ZERO,.45,bone)
			if data.move in ["hammer","seismic"]:
				var center := point+(direction*2.3 if data.move == "hammer" else Vector3.ZERO)
				energy(center+Vector3.UP*.04,Vector2.ONE*(8.8 if data.move == "hammer" else 11),Color(.4,.75,.9,.18),4,1.05 if data.move == "hammer" else .7,Vector3.UP,0)
		"ground":
			var strong: bool = data.move in ["hammer","seismic"]
			ground_burst(point,1.7 if strong else 1.05,tint)
			if strong: dust.crown(point,1.2)
			sparks(point+Vector3.UP*.2,tint,1.3)
		"fire":
			energy(point,Vector2.ONE*2.5,Color.WHITE,0,.16,Vector3.ZERO,1.4)
			energy(point,Vector2.ONE*2,tint,4,.25,direction,1.4)
			var shot := energy(point,Vector2.ONE*.75,tint,0,.6,Vector3.ZERO,0)
			if shot != null:
				shots[int(data.token)] = shot
				effects[-1].velocity = direction*70
		"explosion":
			remove_shot(int(data.token))
			energy(point,Vector2.ONE*3.5,Color.WHITE,0,.24,Vector3.ZERO,1.5)
			energy(point,Vector2.ONE*5,tint,4,.55,Vector3.ZERO,1.2)
			ground_burst(point,1.4,tint); sparks(point,tint,1.8)
		"fizzle": remove_shot(int(data.token))
		"launch":
			dust.crown(point,1.25); dust.puff(point,1.5,Color(.84,.85,.84))
			energy(point+Vector3.UP*.4,Vector2.ONE*3,Color.WHITE,0,.2,Vector3.ZERO,1.4)
		"smoke": dust.puff(point-direction*.45+Vector3.UP*.4,1.2,Color(.83,.85,.87),false)
		"boost": energy(point+Vector3.UP*1.5,Vector2(4,2),tint,3,.6)
		"crash": ground_burst(point,1.25,tint); sparks(point+Vector3.UP,tint,1.4)
		"cancel":
			for effect in effects:
				if not String(effect.bone).is_empty(): effect.life = minf(effect.life,.12)

func remove_shot(token: int) -> void:
	if not shots.has(token): return
	var node: Node = shots[token]
	for effect in effects:
		if effect.node == node: effect.life = 0
	shots.erase(token)

func tick(delta: float) -> void:
	clock += delta; dust.paused = game.paused
	for i in range(effects.size()-1,-1,-1):
		var effect: Dictionary = effects[i]; effect.life -= delta
		if effect.life <= 0:
			for token in shots.keys():
				if shots[token] == effect.node: shots.erase(token)
			effect.node.queue_free(); effects.remove_at(i); continue
		var progress: float = 1-effect.life/effect.total
		if effect.node.material_override is ShaderMaterial: effect.node.material_override.set_shader_parameter("age",progress)
		else: effect.node.transparency = smoothstep(.5,1,progress)
		if float(effect.grow) > 0: effect.node.scale = Vector3.ONE*(1+progress*float(effect.grow))
		var bone: String = effect.bone
		if bone == "shield":
			effect.node.global_position = game.player.global_position+Vector3.UP+game.facing_forward()*.7
			effect.node.look_at(effect.node.global_position+game.facing_forward())
		elif not bone.is_empty(): effect.node.global_position = socket(bone)
		else:
			if effect.gravity: effect.velocity += Vector3.DOWN*9.8*delta; effect.node.rotate_x(delta*4)
			effect.node.global_position += effect.velocity*delta
	for i in range(trails.size()-1,-1,-1):
		var trail: Dictionary = trails[i]; trail.life -= delta; trail.clock += delta
		if trail.life <= 0 or game.stun > 0 or game.player_ragdoll: trails.remove_at(i); continue
		var position := socket(trail.bone); var motion: Vector3 = position-trail.last
		if trail.clock >= .025 and motion.length() > .025:
			var node := energy((position+trail.last)*.5,Vector2(minf(motion.length()*2,.8),trail.width),trail.tint,3,.16)
			if node != null: node.rotation.z = sin(clock*7)*.5
			trail.last = position; trail.clock = 0
	update_jets()

func update_jets() -> void:
	var mega: bool = game.fusion.fused
	var powered: bool = mega and (game.fusion.boost_time > 0 or game.fusion.combat.ram_velocity().length() > 0)
	if not mega: powered = game.robots.active and game.dash_time > 0
	powered = powered and game.hp > 0 and game.moves.player_freeze <= 0 and not game.player_ragdoll
	if powered and enabled() and not is_instance_valid(jets):
		jets = preload("res://scripts/mecha_thruster.gd").new(); jets.seed = 13; add_child(jets)
	if is_instance_valid(jets):
		jets.visible = powered and enabled()
		# Fixed backpack sockets; aim changes do not move emitters between limbs.
		var anchor: Vector3 = game.player.global_position+Vector3.UP*(2.6 if mega else 1.25)-game.facing_forward()*(.45 if mega else .22)
		jets.global_transform = Transform3D(Basis(Vector3.UP,game.model.rotation.y),anchor)
		jets.scale = Vector3.ONE*(1.5 if mega else .65)
		jets.animate(clock,1.35 if powered and enabled() else 0)
	var guarding: bool = (mega or game.robots.active) and game.block and game.hp > 0 and game.moves.player_freeze <= 0
	if guarding and enabled() and not is_instance_valid(guard_shield):
		guard_shield = MeshInstance3D.new(); var quad := QuadMesh.new(); quad.size = Vector2(3.2,3.8)
		guard_shield.mesh = quad
		var mat := ShaderMaterial.new(); mat.shader = ENERGY; mat.set_shader_parameter("mode",2)
		mat.set_shader_parameter("tint",Color("a7efff")); mat.set_shader_parameter("billboard",false)
		guard_shield.material_override = mat; add_child(guard_shield)
	if is_instance_valid(guard_shield):
		guard_shield.visible = guarding and enabled()
		guard_shield.mesh.size = Vector2(3.2,3.8) if mega else Vector2(1.45,1.8)
		guard_shield.material_override.set_shader_parameter("tint",Color("a7efff") if mega else PALETTES[game.robots.index])
		guard_shield.global_position = game.player.global_position+Vector3.UP*(2.0 if mega else 1.0)+game.facing_forward()*(1.1 if mega else .65)
		guard_shield.look_at(guard_shield.global_position+game.facing_forward())
		guard_shield.material_override.set_shader_parameter("age",.25)

func clear() -> void:
	for effect in effects: effect.node.queue_free()
	effects.clear(); trails.clear(); shots.clear(); cast_token = -1
	if is_instance_valid(guard_shield): guard_shield.queue_free()
	guard_shield = null
	if dust != null: dust.clear()
	if is_instance_valid(jets): jets.stop(); jets.queue_free()
	jets = null

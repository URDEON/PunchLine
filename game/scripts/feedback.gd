extends Node3D
var game: Node3D
var pool: Array[AudioStreamPlayer3D] = []
var cursor := 0
var effects: Array[Dictionary] = []
var cooldowns := {}
var music: AudioStreamPlayer
var played := 0
var ui_voice: AudioStreamPlayer
var step_distance := 0.0
var last_step_position := Vector3.ZERO
var step_side := false
var duck := 0.0
var rng := RandomNumberGenerator.new()
var ambience: AudioStreamPlayer
var audio_bank := preload("res://scripts/combat_audio_bank.gd").new()
var audio_events: Array[Dictionary] = []
var ambient_reference := false
var foot_contacts:Dictionary={}
var contact_clock:=0.0
var robot_contacts:Dictionary={}
var mecha_dust: Node3D
var ui_streams := {"click":preload("res://assets/audio/v098/ui/click1.ogg"),"open":preload("res://assets/audio/v098/ui/switch1.ogg"),"close":preload("res://assets/audio/v098/ui/click2.ogg"),"hover":preload("res://assets/audio/v098/ui/rollover1.ogg")}
var streams := {
	"mecha_step_0":preload("res://assets/audio/mecha_v0914/step_heavy_0.wav"),
	"mecha_step_1":preload("res://assets/audio/mecha_v0914/step_heavy_1.wav"),
	"mecha_step_2":preload("res://assets/audio/mecha_v0914/step_heavy_2.wav"),
	"mecha_servo_1":preload("res://assets/audio/mecha_v0914/servo_sweep_01.ogg"),
	"mecha_servo_2":preload("res://assets/audio/mecha_v0914/servo_sweep_02.ogg"),
	"mecha_servo_3":preload("res://assets/audio/mecha_v0914/servo_sweep_03.ogg"),
	"mecha_armor":preload("res://assets/audio/mecha_v0914/armor_hit_01.ogg"),
	"mecha_crash":preload("res://assets/audio/mecha_v0914/armor_hit_01.ogg"),
	"mecha_power":preload("res://assets/audio/mecha_v0914/power_t3_loop.ogg"),
	"fusion_thruster":preload("res://assets/audio/thrusterFire_000.ogg"),
	"fusion_latch":preload("res://assets/audio/impactMetal_light_000.ogg"),
	"fusion_step":preload("res://assets/audio/fusion/step_sub.wav"),
	"hit":preload("res://assets/audio/impactPunch_medium_000.ogg"),
	"heavy":preload("res://assets/audio/impactPunch_heavy_000.ogg"),
	"block":preload("res://assets/audio/guard_tap.ogg"),
	"dash":preload("res://assets/audio/dash_swish.ogg"),
	"charge":preload("res://assets/audio/forceField_000.ogg"),
	"burst":preload("res://assets/audio/explosionCrunch_000.ogg"),
	"glass":preload("res://assets/audio/glass.wav"),
	"step":preload("res://assets/audio/footstep_concrete_000.ogg"),
	"step2":preload("res://assets/audio/footstep_concrete_001.ogg"),
	"jump":preload("res://assets/audio/v096/jump.wav"),
	"kogane":preload("res://assets/audio/v096/kogane.wav"),
	"checkpoint":preload("res://assets/audio/v096/checkpoint.wav"),
	"recover":preload("res://assets/audio/v096/recovery.wav")
}
const MECHA_REFERENCES={
 "mecha_step_0":preload("res://assets/audio/mecha_v0929/step_contact_0.wav"),
 "mecha_step_1":preload("res://assets/audio/mecha_v0929/step_contact_1.wav"),
 "mecha_step_2":preload("res://assets/audio/mecha_v0929/step_contact_2.wav"),
 "mecha_armor":preload("res://assets/audio/mecha_v0928/armor_impact_0.wav"),
 "mecha_crash":preload("res://assets/audio/mecha_v0928/armor_impact_1.wav"),
 "mecha_servo_1":preload("res://assets/audio/mecha_v0928/servo_assembly_0.wav"),
 "mecha_servo_2":preload("res://assets/audio/mecha_v0928/servo_assembly_1.wav"),
 "mecha_servo_3":preload("res://assets/audio/mecha_v0928/servo_assembly_2.wav")}
func setup(host: Node3D) -> void:
	game = host
	mecha_dust = preload("res://scripts/mecha_dust.gd").new(); add_child(mecha_dust)
	rng.randomize()
	last_step_position = game.player.position
	for i in range(12):
		var voice := AudioStreamPlayer3D.new()
		voice.unit_size = 4.0
		voice.bus = "SFX"
		voice.max_distance = 35.0
		voice.volume_db = -10.0
		add_child(voice)
		pool.append(voice)
	music = AudioStreamPlayer.new()
	add_child(music)
	music.bus = "Music"
	var track: AudioStreamOggVorbis = preload("res://assets/audio/v096/projection_groove.ogg").duplicate()
	track.loop = true
	music.stream = track
	music.volume_db = -14.0
	ui_voice = AudioStreamPlayer.new()
	add_child(ui_voice)
	ui_voice.bus = "UI"
	ui_voice.stream = preload("res://assets/audio/ui_click.wav")
	ui_voice.volume_db = -7.0
	ambience = AudioStreamPlayer.new(); add_child(ambience); ambience.bus = "SFX"
	var ambient_track: AudioStreamOggVorbis = preload("res://assets/audio/v096/domain_ambient.ogg").duplicate()
	ambient_track.loop = true
	var reference_ambient: AudioStreamWAV = preload("res://assets/audio/v098/domain_ambient.wav").duplicate()
	reference_ambient.loop_mode = AudioStreamWAV.LOOP_FORWARD
	reference_ambient.loop_begin = 0; reference_ambient.loop_end = reference_ambient.data.size()/2
	ambience.stream = reference_ambient if bool(game.preferences.values.reference_audio) else ambient_track
	ambient_reference = bool(game.preferences.values.reference_audio)
	ambience.volume_db = -45

func ui_sound(event: String = "click") -> void:
	if ui_voice != null:
		ui_voice.stream = ui_streams.get(event,ui_streams.click); ui_voice.play()

func damage_number(pos: Vector3, damage: float) -> void:
	if effects.size() >= 80: return
	var text := Label3D.new()
	add_child(text)
	text.global_position = pos+Vector3(rng.randf_range(-0.25,0.25),0,0)
	text.text = "%d" % int(damage)
	text.font_size = 42 if damage >= 12 else 32
	text.pixel_size = 0.004
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text.modulate = Color("e2c994") if damage >= 12 else Color("f0edf6")
	text.no_depth_test = false
	effects.append({"node":text,"life":0.55,"number":true})
func sound(id: String, pos: Vector3, volume: float = 0.0) -> void:
	var selected: Dictionary = audio_bank.choose(id,bool(game.preferences.values.reference_audio))
	if bool(game.preferences.values.reference_audio) and MECHA_REFERENCES.has(id):selected={"stream":MECHA_REFERENCES[id],"pitch":1.0,"reference":true}
	if (not streams.has(id) and selected.is_empty()) or float(cooldowns.get(id,0)) > 0:
		return
	cooldowns[id] = .18 if id=="block" else (.12 if id=="glass" else .06)
	var voice := pool[cursor]
	for candidate in pool:
		if not candidate.playing:
			voice = candidate
			break
	cursor = (cursor+1)%pool.size()
	voice.stop()
	voice.stream = selected.stream if not selected.is_empty() else streams[id]
	voice.global_position = pos
	var combat := not selected.is_empty()
	voice.bus = "Combat" if combat else "SFX"
	voice.unit_size = 8.0 if combat else 4.0
	voice.volume_db = (-8.0 if combat else -10.0)+volume+(-12.0 if id=="block" else 0.0)
	voice.pitch_scale = float(selected.pitch) if combat else rng.randf_range(0.97,1.03)
	voice.set_meta("event_id",id)
	var follow: Node3D
	if id in ["rush","evolved_accel","dash","domain_open"]:
		if pos.distance_to(game.player.global_position) < .2: follow = game.player
		else:
			for enemy in game.enemies:
				if pos.distance_to(enemy.body.global_position) < .2: follow = enemy.body; break
	voice.set_meta("follow_source",follow)
	voice.play()
	audio_events.append({"id":id,"stream":voice.stream.resource_path,"pitch":voice.pitch_scale,"bus":voice.bus,"position":pos,"volume_db":voice.volume_db,"time":contact_clock})
	if audio_events.size() > 64: audio_events.pop_front()
	played += 1
	if id in ["heavy","burst","glass"]: duck = 0.22
func particles(pos: Vector3, color: Color, smoke: bool = false, count: int = 12) -> void:
	if smoke:
		if mecha_dust != null: mecha_dust.puff(pos,clampf(float(count)/14,.35,1.0),color)
		return
	if not bool(game.preferences.values.effects) or effects.size() >= 40:
		return
	var p := CPUParticles3D.new()
	add_child(p)
	p.global_position = pos
	p.amount = count
	p.lifetime = 0.85 if smoke else 0.32
	p.one_shot = true
	p.explosiveness = 0.96
	p.direction = Vector3.UP
	p.spread = 150
	p.gravity = Vector3(0,0.4 if smoke else -4.0,0)
	p.initial_velocity_min = 0.4 if smoke else 1.8
	p.initial_velocity_max = 2.0 if smoke else 4.0
	p.scale_amount_min = 0.7 if smoke else 0.07
	p.scale_amount_max = 1.5 if smoke else 0.22
	p.color = color
	var ramp := Gradient.new()
	ramp.set_color(0,Color.WHITE)
	ramp.set_color(1,Color(1,1,1,0))
	p.color_ramp = ramp
	var quad := QuadMesh.new()
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = preload("res://assets/vfx/smoke_01.png") if smoke else preload("res://assets/vfx/spark_01.png")
	quad.material = mat
	p.mesh = quad
	p.emitting = true
	effects.append({"node":p,"life":p.lifetime+0.15})
func shatter(pos: Vector3, color: Color, shell: bool = false) -> void:
	sound("burst" if shell else "glass",pos,-3.0)
	var count := 18 if shell else 10
	for i in range(count):
		if effects.size() >= 96:
			break
		var node := MeshInstance3D.new()
		var mesh := ArrayMesh.new()
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		var size := randf_range(0.12,0.30) if shell else randf_range(0.08,0.18)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(-size,-size,0),Vector3(size,-size,0),Vector3(0,size,0)])
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		node.mesh = mesh
		var mat: StandardMaterial3D = game.presentation.transparent_material(color,0.65)
		node.material_override = mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		node.global_position = pos+Vector3(randf_range(-0.5,0.5),randf_range(-0.7,0.7),randf_range(-0.15,0.15))
		node.rotation = Vector3(randf()*PI,randf()*PI,randf()*PI)
		effects.append({"node":node,"life":0.70,"velocity":Vector3(randf_range(-3,3),randf_range(1,4),randf_range(-3,3)),"material":mat})
func crystal_break(panel_transform: Transform3D, size: Vector2, impact: bool) -> void:
	# Residuos visuales sin cuerpos físicos: cantidad y vida limitadas.
	sound("glass",panel_transform.origin,-3.0 if impact else -12.0)
	for i in range(14 if impact else 8):
		if effects.size() >= 96: break
		var shard := MeshInstance3D.new()
		var mesh := ArrayMesh.new()
		var arrays := []; arrays.resize(Mesh.ARRAY_MAX)
		var radius := rng.randf_range(0.06,0.16)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(-radius,-radius,0),Vector3(radius,-radius,0),Vector3(0,radius,0)])
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		shard.mesh = mesh
		var material: StandardMaterial3D = game.presentation.transparent_material(Color("c3e8ff"),0.62)
		shard.material_override = material
		shard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(shard)
		shard.global_transform = panel_transform
		shard.position += panel_transform.basis*Vector3(rng.randf_range(-size.x/2,size.x/2),rng.randf_range(-size.y/2,size.y/2),0)
		var spread := 1.0 if impact else 0.32
		effects.append({"node":shard,"life":0.8,"velocity":panel_transform.basis*Vector3(rng.randf_range(-3,3),rng.randf_range(0.5,3),rng.randf_range(-2,2))*spread,"spin":Vector3(rng.randf_range(-8,8),rng.randf_range(-8,8),0),"material":material})

func planted_step(side:String,point:Vector3,heavy:bool)->bool:
	if game.hp<=0 or game.player.velocity.slide(Vector3.UP).length()<.12:return false
	var last:Dictionary=foot_contacts.get(side,{})
	if not last.is_empty() and (contact_clock-float(last.time)<.30 or point.distance_to(last.point)<.12):return false
	foot_contacts[side]={"time":contact_clock,"point":point}
	var variant:int=played%3
	sound("mecha_step_"+str(variant) if heavy else ("step" if side=="L" else "step2"),point,-3.0 if heavy else -12.0)
	return true

func robot_contacts_without_ik()->void:
	if not game.player.is_on_floor() or game.dash_time>0 or game.attack_anim>0 or not game.robots.current.has("grounding"):robot_contacts.clear();return
	var grounding:Node=game.robots.current.grounding
	for side in grounding.feet:
		var point:Vector3=grounding.foot_point(grounding.feet[side])
		var query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.25,point-Vector3.UP*.4,1|512);query.exclude=[game.player.get_rid()]
		var hit:Dictionary=get_world_3d().direct_space_state.intersect_ray(query)
		var contact:bool=not hit.is_empty() and hit.normal.y>.65 and point.y-hit.position.y<.11
		if contact and not bool(robot_contacts.get(side,false)):planted_step(side,hit.position,true)
		robot_contacts[side]=contact

func tick(delta: float) -> void:
	contact_clock+=delta
	if game.robots.active and not game.fusion.busy() and not bool(game.preferences.values.robot_grounding):robot_contacts_without_ik()
	for voice in pool:
		if not voice.playing or not voice.has_meta("follow_source"): continue
		var follow: Node3D = voice.get_meta("follow_source")
		if voice.playing and is_instance_valid(follow): voice.global_position = follow.global_position
	var distance: float = game.player.position.distance_to(last_step_position)
	last_step_position = game.player.position
	if not game.robots.active and not game.fusion.busy() and distance < 1.0 and game.player.is_on_floor() and game.dash_time <= 0 and game.skill_active == "" and not game.presentation.busy():
		step_distance += distance
		var stride := 1.05 if game.input_pressed("walk") or game.block else 1.9
		if step_distance >= stride:
			step_distance = fmod(step_distance,stride)
			step_side = not step_side
			sound("step" if step_side else "step2",game.player.position,-12.0)
	else:
		step_distance = 0
	duck = maxf(0,duck-delta)
	var ambient_target := -18.0+linear_to_db(maxf(.0001,float(game.preferences.values.ambient))) if game.moves.domain_time > 0 else -65.0
	ambience.volume_db = lerpf(ambience.volume_db,ambient_target,1-exp(-delta*4))
	if game.moves.domain_time > 0 and not ambience.playing: ambience.play()
	elif game.moves.domain_time <= 0 and ambience.volume_db < -60: ambience.stop()
	music.volume_db = lerpf(music.volume_db,-19.0 if duck > 0 else -14.0,1-exp(-delta*10))
	apply_audio_profile()
	for id in cooldowns:
		cooldowns[id] = maxf(0,float(cooldowns[id])-delta)
	for i in range(effects.size()-1,-1,-1):
		var e: Dictionary = effects[i]
		e.life -= delta
		if e.life <= 0:
			e.node.queue_free()
			effects.remove_at(i)
		elif e.get("number",false):
			e.node.position.y += delta*0.9
			e.node.modulate.a = minf(1,e.life*4)
		elif e.has("velocity"):
			e.velocity.y -= 8.0*delta
			e.node.position += e.velocity*delta
			e.node.rotation += e.get("spin",Vector3(5,0,0))*delta
			e.material.albedo_color.a = minf(0.65,e.life)
func apply_audio_profile() -> void:
	if ambience == null or ambient_reference == bool(game.preferences.values.reference_audio): return
	ambient_reference = bool(game.preferences.values.reference_audio)
	if ambient_reference:
		var sample: AudioStreamWAV = preload("res://assets/audio/v098/domain_ambient.wav").duplicate()
		sample.loop_mode = AudioStreamWAV.LOOP_FORWARD; sample.loop_end = sample.data.size()/2
		ambience.stream = sample
	else:
		var sample: AudioStreamOggVorbis = preload("res://assets/audio/v096/domain_ambient.ogg").duplicate()
		sample.loop = true; ambience.stream = sample
	if game.moves.domain_time > 0: ambience.play()

func set_paused(value: bool) -> void:
	if mecha_dust != null: mecha_dust.paused = value
	music.stream_paused = value
	if ambience != null: ambience.stream_paused = value
	for voice in pool:
		voice.stream_paused = value
	for effect in effects:
		if effect.node is CPUParticles3D:
			effect.node.speed_scale = 0.0 if value else 1.0

func stop_all() -> void:
	music.stream_paused = false
	music.stop()
	if ambience != null: ambience.stream_paused = false; ambience.stop()
	if ui_voice != null: ui_voice.stream_paused = false; ui_voice.stop()
	for voice in pool:
		voice.stream_paused = false
		voice.stop()

func _exit_tree() -> void:
	stop_all()

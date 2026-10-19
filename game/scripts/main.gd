extends Node3D
@export var tuning: Resource = preload("res://balance_v091.tres")
var fusion: Node3D = preload("res://scripts/fusion_controller.gd").new()
var skill_vfx: Node3D = preload("res://scripts/robot_skill_vfx.gd").new()
var feedback: Node3D = preload("res://scripts/feedback.gd").new()
var presentation: Node3D = preload("res://scripts/presentation.gd").new()
var moves: Node3D = preload("res://scripts/combat_moves.gd").new()
var preferences: Node = preload("res://scripts/preferences.gd").new()
var interface: CanvasLayer = preload("res://scripts/interface.gd").new()
var arena: Node3D = preload("res://scripts/arena.gd").new()
var robots: Node = preload("res://scripts/robot_character.gd").new()
var robot_clearance: Node = preload("res://scripts/robot_clearance.gd").new()
var performance_capture: Node = preload("res://scripts/performance_capture.gd").new()
var route_trial: Node3D = preload("res://scripts/route_trial.gd").new()
var locomotion_tree: AnimationTree
var visual_motion: Node = preload("res://scripts/visual_motion.gd").new()
var locomotion_vector := Vector2.ZERO
var attack_buffer := 0.0
var ability_buffer := 0.0
var buffered_ability := 0
var jump_buffer := 0.0
var coyote_time := 0.0
var camera_target := Vector3.ZERO
var camera_initialized := false
var camera_kick := 0.0
var impact_freeze := 0.0
var rush_target: Dictionary = {}
var rush_hits := 0
var skill3_start_position := Vector3.ZERO
var projection_pose_revision := -1
const ATTACK_TIME := 0.32
const FINISHER_TIME := 0.38
# v0.9.1: autoapuntado, compromiso final, estados y balance en combat_tuning.gd.
# El personaje enviado usa el rig de combate existente, sin root motion.

const SPEED := 7.5
const GRAVITY := 24.0
const JUMP_FORCE := 9.0
const DASH_SPEED := 24.0
const DASH_DURATION := 0.18
const DASH_COOLDOWN := 1.2
const FOURTH_HIT_STUN := 1.8
const NORMAL_STUN := 0.35
const BLOCKSTUN_DURATION := 0.22
const WAKEUP_PROTECTION_DURATION := 0.50
# Progresión: BASE llena renace en FORM1; FORM2 exige evolución de FORM1.
const ULT_FORM1_DURATION := 60.0
const ULT_FORM2_DURATION := 45.0
const ULT_REBIRTH_HP := 60.0
const FORM1_SPEED_MULT := 1.10
const FORM2_SPEED_MULT := 1.15
# Balance base del moveset v0.6. Los M1 cargan poco; las skills cargan más por su cooldown.
const M1_CHARGE := 2.0
const FOURTH_M1_CHARGE := 3.5
const SKILL3_COOLDOWN := 7.0
const SKILL4_COOLDOWN := 6.0
const SKILL3_CHARGE := 14.0
const SKILL4_CHARGE := 12.0
const SKILL3_RUSH_SPEED := 19.0
const SKILL3_MISS_RECOVERY := 0.42
const SKILL3_HIT_RECOVERY := 0.24
const SKILL4_RECOVERY := 0.30
# Rig visual RPG Animations FREE (in-place). El CharacterBody3D sigue controlando movimiento.
const RIG_SCENE_PATH := "res://assets/rpg_animations/Unarmed.glb"
const ENEMY_RIG_SCENE_PATH := "res://assets/enemies/y2k/UrbanShadow_Rig.gltf"
var appearance = preload("res://scripts/enemy_appearance.gd").new()
var appearance_seed := 950
var gallery: Node3D
var domain_inspector = preload("res://scripts/domain_inspector.gd").new()
const PLAYER_RIG_SCENE_PATH := "res://assets/characters/alien/Alien_Naoya_Rig_Combat.glb"
const RIG_SCALE_ADJUST := 0.76
const RIG_YAW_OFFSET := 0.0
const RIG_BLEND_DEFAULT := 0.10
const PLAYER_RIG_COLOR := Color("d8ccb7")

var player: CharacterBody3D
var model: Node3D
var arm_left: Node3D
var arm_right: Node3D
var elbow_left: Node3D
var elbow_right: Node3D
var leg_left: Node3D
var leg_right: Node3D
var camera_view = preload("res://scripts/body_camera.gd").new()
var camera: Camera3D
# El maniquí procedural se conserva oculto como fallback/driver de orientación.
var rig_holder: Node3D
var rig_scene: Node3D
var rig_anim: AnimationPlayer
var rig_enabled := false
var rig_current_anim: StringName = &""
var rig_anim_names: Dictionary = {}

var yaw := 0.0
var pitch := -0.24
var zoom := 6.5
var hp := 100.0
var max_hp := 100.0
var charge := 0.0
var stun := 0.0
var block := false
var attack_cd := 0.0
var attack_anim := 0.0
var attack_variant := "normal"
var attack_hit_done := false
var combo := 0
var combo_timeout := 0.0
var dash_time := 0.0
var dash_cd := 0.0
var dash_dir := Vector3.ZERO
var dash_pose_blend := 0.0
var dash_frame_life := 0.0
var player_ragdoll := false
var player_ragdoll_time := 0.0
var player_ragdoll_impact: Dictionary = {}
var physical_ragdoll: Node
var descending_time := 0.0
var punch_visual := "combat/RightJab"
var kick_visual := "combat/Kick"
var preview_time := 0.0
var preview_animation := ""
var block_recoil_time := 0.0
var player_wakeup_protection := 0.0
var camera_lock := false
var human_motion: SkeletonModifier3D
var landing_anim := 0.0
var wakeup_anim := 0.0
var was_on_floor := true
# Skills base. 1 y 2 quedan reservadas; 3 y 4 se implementan en v0.6.
var skill3_cd := 0.0
var skill4_cd := 0.0
var skill_active := ""
var skill_phase := ""
var skill_timer := 0.0
var skill_hit_done := false
var skill_connected := false
var skill_dir := Vector3.ZERO
# Estados de la ultimate: "BASE" (carga/LISTA), "FORM1", "FORM2".
var form := "BASE"
var ult_time := 0.0
var ult_duration := 1.0
var ult_msg := ""
var ult_msg_time := 0.0
var domain_used := false # Prevista para el dominio (1 uso por transformación). Aún sin usar.
var enemies: Array[Dictionary] = []

var hud: Label
var notice: Label
var health_bar: ProgressBar
var ult_bar: ProgressBar
var skills_label: Label
var clock := 0.0
var paused := false
var pause_panel: PanelContainer
var dash_frame: Node3D
var crosshair: Label
var material_cache: Dictionary = {}
var glow_material_cache: Dictionary = {}

func get_box_material(color: Color) -> StandardMaterial3D:
	var key := color.to_html(true)
	if material_cache.has(key):
		return material_cache[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material_cache[key] = material
	return material

func get_glow_material(color: Color) -> StandardMaterial3D:
	var key := color.to_html(true)
	if glow_material_cache.has(key):
		return glow_material_cache[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.48)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.8
	glow_material_cache[key] = material
	return material

func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = get_box_material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func glow_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = get_glow_material(color)
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func create_training_ring(actor: Node3D, color: Color) -> void:
	# Aros bajos en el suelo para identificar claramente cada muñeco del campo.
	for spec in [Vector2(0.43, 0.47), Vector2(0.57, 0.60)]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = spec.x
		torus.outer_radius = spec.y
		torus.rings = 64
		torus.ring_segments = 8
		ring.mesh = torus
		ring.material_override = get_glow_material(color)
		ring.position.y = 0.025
		actor.add_child(ring)

func body(pos: Vector3) -> CharacterBody3D:
	var actor := CharacterBody3D.new()
	add_child(actor)
	actor.position = pos
	actor.floor_snap_length = .35
	actor.floor_max_angle = deg_to_rad(48)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.9
	collider.shape = capsule
	collider.position.y = 0.95
	actor.add_child(collider)
	return actor

func mannequin(actor: Node3D, color: Color, blond: bool) -> Dictionary:
	var visual := Node3D.new()
	actor.add_child(visual)
	box(visual, Vector3(0.72,0.76,0.4), Vector3(0,1.12,0), color)
	box(visual, Vector3(0.48,0.48,0.45), Vector3(0,1.76,0), Color("e8c3a0"))
	box(visual, Vector3(0.32,0.07,0.02), Vector3(0,1.79,-0.235), Color("252331"))
	if blond:
		box(visual, Vector3(0.52,0.18,0.49), Vector3(0,2.02,0), Color("e6be54"))
		box(visual, Vector3(0.2,0.22,0.1), Vector3(-0.17,1.9,-0.23), Color("e6be54"))

	var left_arm: Node3D
	var right_arm: Node3D
	var left_elbow: Node3D
	var right_elbow: Node3D
	var left_leg: Node3D
	var right_leg: Node3D

	for side in [-1,1]:
		var arm := Node3D.new()
		visual.add_child(arm)
		arm.position = Vector3(side*0.51,1.44,0)
		box(arm, Vector3(0.25,0.34,0.27), Vector3(0,-0.17,0), color)
		var elbow := Node3D.new()
		arm.add_child(elbow)
		elbow.position = Vector3(0,-0.34,0)
		box(elbow, Vector3(0.24,0.25,0.26), Vector3(0,-0.125,0), color)
		box(elbow, Vector3(0.25,0.23,0.27), Vector3(0,-0.365,0), Color("e8c3a0"))
		var leg := Node3D.new()
		visual.add_child(leg)
		leg.position = Vector3(side*0.2,0.76,0)
		box(leg, Vector3(0.31,0.69,0.34), Vector3(0,-0.34,0), Color("24232c"))
		if side == -1:
			left_arm = arm
			left_elbow = elbow
			left_leg = leg
		else:
			right_arm = arm
			right_elbow = elbow
			right_leg = leg

	return {
		"visual": visual,
		"arm_left": left_arm,
		"arm_right": right_arm,
		"elbow_left": left_elbow,
		"elbow_right": right_elbow,
		"leg_left": left_leg,
		"leg_right": right_leg
	}

func find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := find_animation_player(child)
		if found != null:
			return found
	return null


func apply_rig_color(root: Node, color: Color) -> void:
	# Paleta por vértices en la pose de reposo: ropa, piel y calzado conservan
	# sus colores durante el skinning. El GLB y sus animaciones no se alteran.
	for child in root.get_children():
		if child is MeshInstance3D:
			var mesh_instance := child as MeshInstance3D
			var source: Mesh = mesh_instance.mesh
			var colored := ArrayMesh.new()
			for surface in range(source.get_surface_count()):
				var arrays: Array = source.surface_get_arrays(surface)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var colors := PackedColorArray()
				for vertex in vertices:
					var palette := color
					if vertex.y < 1.30: palette = Color("303443")
					if vertex.y < 0.18: palette = Color("181d28")
					if vertex.y > 2.12 or (absf(vertex.x) > 1.16 and vertex.y > 1.45): palette = Color("d8b49b")
					if vertex.y > 2.43: palette = Color("baaa78")
					colors.append(palette)
				arrays[Mesh.ARRAY_COLOR] = colors
				colored.add_surface_from_arrays(source.surface_get_primitive_type(surface),arrays)
			mesh_instance.mesh = colored
			var material := StandardMaterial3D.new()
			material.albedo_color = Color.WHITE
			material.vertex_color_use_as_albedo = true
			material.roughness = 0.82
			material.metallic = 0.0
			mesh_instance.material_override = material
		apply_rig_color(child, color)

func resolve_animation_from(anim: AnimationPlayer, names: Dictionary, wanted: String) -> StringName:
	if anim == null:
		return &""
	var key := wanted.to_lower()
	if names.has(key):
		return StringName(names[key])
	for value in names.values():
		var candidate := String(value)
		if candidate.to_lower().ends_with(key):
			return StringName(candidate)
	return &""

func set_animation_loop_for(anim: AnimationPlayer, names: Dictionary, wanted: String, enabled: bool) -> void:
	var resolved := resolve_animation_from(anim, names, wanted)
	if resolved == &"" or not anim.has_animation(resolved):
		return
	var animation := anim.get_animation(resolved)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR if enabled else Animation.LOOP_NONE

func resolve_rig_animation(wanted: String) -> StringName:
	if rig_anim == null:
		return &""
	var key := wanted.to_lower()
	if rig_anim_names.has(key):
		return StringName(rig_anim_names[key])
	# Fallback por si Godot añade nombre de librería/prefijo al importar el GLB.
	for value in rig_anim_names.values():
		var candidate := String(value)
		if candidate.to_lower().ends_with(key):
			return StringName(candidate)
	return &""

func set_rig_loop(wanted: String, enabled: bool) -> void:
	if rig_anim == null:
		return
	var resolved := resolve_rig_animation(wanted)
	if resolved == &"" or not rig_anim.has_animation(resolved):
		return
	var animation := rig_anim.get_animation(resolved)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR if enabled else Animation.LOOP_NONE

func play_rig_animation(wanted: String, blend: float = RIG_BLEND_DEFAULT, speed: float = 1.0, force: bool = false) -> void:
	if not rig_enabled or rig_anim == null:
		return
	var resolved := resolve_rig_animation(wanted)
	if resolved == &"":
		return
	if is_instance_valid(locomotion_tree):
		locomotion_tree.active = false
	rig_anim.speed_scale = speed if impact_freeze <= 0 else 0.0
	if not force and rig_current_anim == resolved:
		return
	rig_anim.play(resolved, blend, 1.0)
	rig_current_anim = resolved

func setup_player_rig() -> void:
	var resource := load(PLAYER_RIG_SCENE_PATH)
	if not (resource is PackedScene):
		push_warning("No se pudo cargar el rig: %s. Se usará el maniquí fallback." % PLAYER_RIG_SCENE_PATH)
		return

	rig_holder = Node3D.new()
	rig_holder.name = "RigVisualHolder"
	player.add_child(rig_holder)
	rig_holder.scale = Vector3.ONE * RIG_SCALE_ADJUST

	rig_scene = (resource as PackedScene).instantiate() as Node3D
	if rig_scene == null:
		push_warning("El GLB no produjo un Node3D. Se usará el maniquí fallback.")
		rig_holder.queue_free()
		return
	rig_holder.add_child(rig_scene)
	# Conservamos los materiales y las texturas del GLB enviado.
	rig_anim = find_animation_player(rig_scene)
	if rig_anim == null:
		push_warning("El personaje no contiene AnimationPlayer. Se usará el maniquí fallback.")
		rig_holder.queue_free()
		return

	rig_anim.add_animation_library("ual2",load("res://assets/animation_sources/ual2/retargeted.tres"))
	rig_anim.add_animation_library("combat",load("res://assets/animation_sources/ual2/combat_timing.tres"))
	rig_anim.add_animation_library("mixamo",load("res://assets/animation_sources/mixamo/retargeted.tres"))
	rig_anim.add_animation_library("extras",load("res://assets/animation_sources/ual2/extras_v096.tres"))
	rig_anim.add_animation_library("dance",load("res://assets/dance/running_man.tres"))
	rig_anim.add_animation_library("emotes",load("res://assets/animation_sources/ual2/emotes_v097.tres"))
	var variants: AnimationLibrary = load("res://assets/animation_sources/mixamo/combat.tres")
	var combat_library := rig_anim.get_animation_library("combat").duplicate(true) as AnimationLibrary
	for clip in [&"Cross",&"Elbow"]: combat_library.add_animation("Mixamo"+str(clip),variants.get_animation(clip).duplicate(true))
	rig_anim.remove_animation_library("combat")
	rig_anim.add_animation_library("combat",combat_library)

	for anim_name in rig_anim.get_animation_list():
		var key := String(anim_name).to_lower()
		rig_anim_names[key] = anim_name

	for looped in [
		"UnarmedIdle", "UnarmedIdleAlert1", "UnarmedIdleInjured",
		"UnarmedRunForward", "UnarmedRunForwardLeft", "UnarmedRunForwardRight",
		"UnarmedRunBackward", "UnarmedRunBackwardLeft", "UnarmedRunBackwardRight",
		"UnarmedRunLeft", "UnarmedRunRight",
		"UnarmedStrafeForward", "UnarmedStrafeForwardLeft", "UnarmedStrafeForwardRight",
		"UnarmedStrafeBackward", "UnarmedStrafeBackwardLeft", "UnarmedStrafeBackwardRight",
		"UnarmedStrafeLeft", "UnarmedStrafeRight", "UnarmedSprint",
		"UnarmedFall", "UnarmedBlock", "UnarmedStunned"
	]:
		set_rig_loop(looped, true)

	# Clips de acción se mantienen one-shot.
	for oneshot in [
		"UnarmedJump", "UnarmedLand", "UnarmedBlockGetHit1", "UnarmedKnockdown1",
		"UnarmedGetup1", "UnarmedBoost1", "UnarmedDodgeBackward", "UnarmedDodgeLeft",
		"UnarmedDodgeRight", "UnarmedAttackR1", "UnarmedAttackL1", "UnarmedAttackR2",
		"UnarmedAttackL2", "UnarmedAttackR3", "UnarmedAttackL3",
		"UnarmedAttackKickR1", "UnarmedAttackKickL1"
	]:
		set_rig_loop(oneshot, false)

	rig_enabled = true
	# Ocultamos el cuerpo de cajas, pero lo conservamos para fallback y orientación.
	model.visible = false
	play_rig_animation("UnarmedIdleAlert1", 0.0, 1.0, true)
	setup_locomotion_tree()
	physical_ragdoll = preload("res://scripts/physical_ragdoll.gd").new()
	add_child(physical_ragdoll)
	physical_ragdoll.hull_profile = "alien"
	physical_ragdoll.setup(player,rig_holder,visual_motion.find_skeleton(rig_scene),rig_anim,locomotion_tree)

func setup_locomotion_tree() -> void:
	add_child(visual_motion)
	visual_motion.setup(self)
	human_motion = preload("res://scripts/human_grounding.gd").new()
	visual_motion.skeleton.add_child(human_motion); human_motion.setup(self,visual_motion.skeleton)

func sync_rig_transform() -> void:
	if robots.active: robots.sync_transform(); return
	if not rig_enabled or rig_holder == null:
		return
	if is_instance_valid(physical_ragdoll) and physical_ragdoll.active: return
	# Solo heredamos yaw. El Skeleton ya aporta inclinación corporal dentro de cada clip.
	rig_holder.rotation = Vector3(0.0, model.rotation.y + RIG_YAW_OFFSET, 0.0)

func select_rig_locomotion(dir: Vector3) -> String:
	if dir.length() <= 0.05:
		return "UnarmedIdleAlert1"
	if not camera_aim_locked():
		# Sin mira lock el personaje rota hacia su movimiento, por lo que correr hacia delante es suficiente.
		return "UnarmedRunForward"

	var local_dir := dir.rotated(Vector3.UP, -model.rotation.y)
	var x := local_dir.x
	var z := local_dir.z
	var ax := absf(x)
	var az := absf(z)
	if az > 0.35 and ax > 0.35:
		if z < 0.0 and x < 0.0:
			return "UnarmedStrafeForwardLeft"
		if z < 0.0 and x > 0.0:
			return "UnarmedStrafeForwardRight"
		if z > 0.0 and x < 0.0:
			return "UnarmedStrafeBackwardLeft"
		return "UnarmedStrafeBackwardRight"
	if az >= ax:
		return "UnarmedStrafeForward" if z < 0.0 else "UnarmedStrafeBackward"
	return "UnarmedStrafeLeft" if x < 0.0 else "UnarmedStrafeRight"

func rig_dash_animation() -> String:
	var local_dash := dash_dir.rotated(Vector3.UP, -model.rotation.y)
	if local_dash.z > 0.45:
		return "UnarmedDodgeBackward"
	if local_dash.x < -0.45:
		return "UnarmedDodgeLeft"
	if local_dash.x > 0.45:
		return "UnarmedDodgeRight"
	# La carrera común conserva mejor la silueta del personaje durante el dash frontal.
	return "UnarmedRunForward"

func update_rig_animation(dir: Vector3) -> void:
	if robots.active: robots.animate(dir); return
	if not rig_enabled:
		return

	if player_ragdoll:
		if is_instance_valid(physical_ragdoll) and physical_ragdoll.active: return
		play_rig_animation("UnarmedKnockdown1", 0.06, 1.35)
		return
	if preview_time > 0:
		play_rig_animation(preview_animation,.12,1.0)
		return
	if wakeup_anim > 0.0:
		# El clip original es largo; se acelera para ajustarse al recovery visual del prototipo.
		play_rig_animation("UnarmedGetup1", 0.08, 7.0)
		return
	if presentation.animate_rig():
		return
	if skill_active == "extra":
		var pose: String = moves.animation()
		var speed := 2.5
		var force := false
		if moves.key in ["b1","u1"]:
			var clip_length: float = rig_anim.get_animation(resolve_rig_animation(pose)).length
			if moves.stage == "barrage": speed = clip_length/tuning.barrage_interval
			elif moves.stage == "commit": speed = clip_length*0.45/tuning.commit_duration
			else: speed = 1.0
			force = projection_pose_revision != moves.projection.strike_revision
			projection_pose_revision = moves.projection.strike_revision
		play_rig_animation(pose, 0.04, speed, force)
		return
	if skill_active == "skill3":
		if skill_phase == "barrage":
			play_rig_animation("UnarmedAttackL1" if rush_hits % 2 == 0 else "UnarmedAttackR1",0.045,3.0)
		else:
			play_rig_animation("UnarmedRunForward" if skill_phase == "windup" else "UnarmedAttackR3", 0.07, 1.55)
		return
	if skill_active == "skill4":
		play_rig_animation(kick_visual, 0.05, 4.887 if kick_visual.begins_with("mixamo/") else 1.0)
		return
	if block_recoil_time > 0.0 or block:
		visual_motion.tick()
		return
	if dash_time > 0.0:
		var dash_anim := rig_dash_animation()
		var dash_speed := 2.5 if dash_anim == "UnarmedRunForward" else 3.8
		play_rig_animation(dash_anim, 0.06, dash_speed)
		return
	if attack_anim > 0.0:
		var attack_name := "combat/RightJab"
		match combo:
			1: attack_name = "combat/RightJab"
			2: attack_name = punch_visual
			3: attack_name = punch_visual
			4:
				if attack_variant == "uppercut":
					attack_name = "combat/Uppercut"
				elif attack_variant == "downslam":
					attack_name = "combat/Downslam"
				else:
					attack_name = "combat/Finisher"
		play_rig_animation(attack_name, 0.04, 1.0)
		return
	if stun > 0.0:
		play_rig_animation("UnarmedStunned", 0.08, 1.2)
		return
	if not player.is_on_floor():
		if player.velocity.y > 0.5:
			play_rig_animation("extras/NinjaJump_Start", 0.07, 1.4)
		else:
			play_rig_animation("mixamo/Falling" if descending_time >= 4.0 else "extras/NinjaJump_Idle_Loop", 0.10, 1.0)
		return
	if landing_anim > 0.0:
		play_rig_animation("extras/NinjaJump_Land", 0.06, 3.0)
		return

	visual_motion.tick()

func setup_enemy_rig(actor: CharacterBody3D, fallback_visual: Node3D, tint: Color) -> Dictionary:
	var result := {
		"enabled": false,
		"holder": null,
		"scene": null,
		"anim": null,
		"names": {},
		"current": StringName()
	}
	var resource := load(ENEMY_RIG_SCENE_PATH)
	if not (resource is PackedScene):
		return result

	var holder := Node3D.new()
	holder.name = "EnemyRigVisualHolder"
	actor.add_child(holder)
	holder.scale = Vector3.ONE * RIG_SCALE_ADJUST
	holder.rotation.y = RIG_YAW_OFFSET

	var scene := (resource as PackedScene).instantiate() as Node3D
	if scene == null:
		holder.queue_free()
		return result
	holder.add_child(scene)
	var look: Dictionary = appearance.apply(scene,appearance_seed,enemies.size())
	holder.scale *= float(look.height)
	result["appearance"] = look
	var anim := find_animation_player(scene)
	if anim == null:
		holder.queue_free()
		return result

	var names: Dictionary = {}
	for anim_name in anim.get_animation_list():
		names[String(anim_name).to_lower()] = anim_name

	for looped in [
		"UnarmedIdleAlert1", "UnarmedRunForward", "UnarmedBlock", "UnarmedStunned"
	]:
		set_animation_loop_for(anim, names, looped, true)
	for oneshot in [
		"UnarmedAttackR1", "UnarmedAttackL1", "UnarmedAttackR2", "UnarmedAttackL2",
		"UnarmedBlockGetHit1", "UnarmedKnockdown1", "UnarmedGetup1"
	]:
		set_animation_loop_for(anim, names, oneshot, false)

	fallback_visual.visible = false
	result.enabled = true
	result.holder = holder
	result.scene = scene
	result.anim = anim
	result.names = names
	var physics = preload("res://scripts/physical_ragdoll.gd").new()
	add_child(physics)
	physics.setup(actor,holder,visual_motion.find_skeleton(scene),anim)
	result["physics"] = physics
	var idle := resolve_animation_from(anim, names, "UnarmedIdleAlert1")
	if idle != &"":
		anim.play(idle, 0.0, 1.0)
		result.current = idle
	return result

func play_enemy_rig_animation(enemy: Dictionary, wanted: String, blend: float = 0.10, speed: float = 1.0) -> void:
	if not bool(enemy.get("rig_enabled", false)):
		return
	var anim: AnimationPlayer = enemy.rig_anim
	var names: Dictionary = enemy.rig_anim_names
	var resolved := resolve_animation_from(anim, names, wanted)
	if resolved == &"":
		return
	var current: StringName = enemy.rig_current_anim
	if current == resolved:
		return
	anim.play(resolved, blend, speed)
	enemy.rig_current_anim = resolved

func update_enemy_rig_animation(enemy: Dictionary) -> void:
	if not bool(enemy.get("rig_enabled", false)):
		return
	var holder: Node3D = enemy.rig_holder
	if is_instance_valid(enemy.get("physics")) and enemy.physics.active: return
	holder.rotation.y = RIG_YAW_OFFSET
	var flash_scale: float = 1.0
	holder.scale = Vector3.ONE * RIG_SCALE_ADJUST * flash_scale * float(enemy.get("appearance",{}).get("height",1.0))

	if bool(enemy.ragdoll):
		play_enemy_rig_animation(enemy, "UnarmedKnockdown1", 0.05, 1.35)
		return
	if float(enemy.get("wakeup_time",0)) > 0:
		play_enemy_rig_animation(enemy,"UnarmedGetup1",0.06,2.4)
		return
	if float(enemy.stun) > 0.0:
		play_enemy_rig_animation(enemy, "UnarmedStunned", 0.07, 1.25)
		return
	if int(enemy.kind) == 1:
		if float(enemy.flash) > 0.0:
			play_enemy_rig_animation(enemy, "UnarmedBlockGetHit1", 0.04, 2.2)
		else:
			play_enemy_rig_animation(enemy, "UnarmedBlock", 0.10, 1.0)
		return
	if str(enemy.attack_phase) != "idle":
		var attack_name := "UnarmedAttackR1"
		match int(enemy.combo):
			1: attack_name = "UnarmedAttackR1"
			2: attack_name = "UnarmedAttackL1"
			3: attack_name = "UnarmedAttackR2"
			4: attack_name = "UnarmedAttackL2"
		var total: float = (0.30 if int(enemy.combo) == 4 else 0.20) + (0.12 if int(enemy.combo) == 4 else 0.10) + (0.34 if int(enemy.combo) == 4 else 0.24)
		var clip_length := 0.833
		play_enemy_rig_animation(enemy, attack_name, 0.055, clip_length / total)
		return
	var actor: CharacterBody3D = enemy.body
	var horizontal_speed: float = Vector2(actor.velocity.x, actor.velocity.z).length()
	if horizontal_speed > 0.15:
		play_enemy_rig_animation(enemy, "UnarmedRunForward", 0.12, 1.0)
	else:
		play_enemy_rig_animation(enemy, "UnarmedIdleAlert1", 0.12, 1.0)

func _ready() -> void:
	tuning = tuning.duplicate(true)
	add_child(preferences)
	preferences.setup(self)
	var floor_body := StaticBody3D.new()
	add_child(floor_body)
	var floor_mesh := box(floor_body, Vector3(100,1,100), Vector3(0,-0.5,0), Color("424c5b"))
	var collider := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(100,1,100)
	collider.shape = floor_shape
	collider.position.y = -0.5
	floor_body.add_child(collider)

	add_child(arena)
	arena.setup(self,floor_mesh)

	var sun := DirectionalLight3D.new()
	sun.name = "ArenaSun"
	add_child(sun)
	sun.rotation_degrees = Vector3(-55,-30,0)
	sun.light_color = Color("fff0dc")
	sun.light_energy = 1.05
	sun.shadow_enabled = true

	var world := WorldEnvironment.new()
	world.name = "ArenaEnvironment"
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("141b31")
	sky_material.sky_horizon_color = Color("7d7b90")
	sky_material.ground_bottom_color = Color("202631")
	sky_material.ground_horizon_color = Color("7d7b90")
	sky.sky_material = sky_material
	world.environment.sky = sky
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("a7bbd4")
	world.environment.ambient_light_energy = 0.42
	add_child(world)
	arena.urban.expansion.set_sky(bool(preload("res://scripts/world_config.gd").current().night))
	arena.punchline.ambience.configure_environment(world.environment,bool(preload("res://scripts/world_config.gd").current().night))

	player = body(Vector3(0,0.1,5))
	var player_parts := mannequin(player, Color("ebe5d7"), true)
	model = player_parts.visual
	arm_left = player_parts.arm_left
	arm_right = player_parts.arm_right
	elbow_left = player_parts.elbow_left
	elbow_right = player_parts.elbow_right
	leg_left = player_parts.leg_left
	leg_right = player_parts.leg_right
	setup_player_rig()

	camera = Camera3D.new()
	# Se actualiza en _process siguiendo un blanco ya interpolado.
	# Evitar que Godot vuelva a interpolar sus transformaciones por física.
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(camera)
	camera.current = true
	camera.near = 0.12
	add_child(domain_inspector)
	domain_inspector.setup(self)
	add_child(route_trial); route_trial.setup(self)

	create_dash_frame()

	for i in range(3):
		var actor := body(Vector3((i-1)*6,0.1,-5))
		var colors = [Color("559db6"), Color("cfaa56"), Color("b85c67")]
		create_training_ring(actor, colors[i])
		var parts := mannequin(actor, colors[i], false)
		var enemy_rig := setup_enemy_rig(actor, parts.visual, colors[i])
		var label := Label3D.new()
		actor.add_child(label)
		label.position.y = 2.65
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.fixed_size = false
		label.font_size = 28
		label.pixel_size = 0.006
		enemies.append({
			"body": actor,
			"visual": parts.visual,
			"arm_left": parts.arm_left,
			"arm_right": parts.arm_right,
			"elbow_left": parts.elbow_left,
			"elbow_right": parts.elbow_right,
			"leg_left": parts.leg_left,
			"leg_right": parts.leg_right,
			"label": label,
			"rig_enabled": enemy_rig.enabled,
			"rig_holder": enemy_rig.holder,
			"rig_scene": enemy_rig.scene,
			"rig_anim": enemy_rig.anim,
			"rig_anim_names": enemy_rig.names,
			"rig_current_anim": enemy_rig.current,
			"appearance": enemy_rig.get("appearance",{}),
			"appearance_generation": 0,
			"physics": enemy_rig.get("physics"),
			"hp": 100.0,
			"stun": 0.0,
			"cd": 1.0,
			"respawn": 0.0,
			"spawn": actor.position,
			"kind": i,
			"flash": 0.0,
			"attack_anim": 0.0,
			"attack_phase": "idle",
			"attack_timer": 0.0,
			"combo": 0,
			"combo_timeout": 0.0,
			"ragdoll": false,
			"ragdoll_time": 0.0,
			"ragdoll_grounded": false,
			"slam_pending": false,
			"walk_clock": float(i)*0.7,
			"sequence_hold": 0.0,
			"wakeup_protection": 0.0,
			"wakeup_time": 0.0,
			"dash_time": 0.0,
			"dash_cd": 0.0,
			"dash_dir": Vector3.ZERO
		})

	var ui := CanvasLayer.new()
	add_child(ui)
	ui.hide()
	var panel := PanelContainer.new()
	ui.add_child(panel)
	panel.position = Vector2(20,20)
	var column := VBoxContainer.new()
	panel.add_child(column)
	hud = Label.new()
	column.add_child(hud)
	hud.add_theme_font_size_override("font_size",20)
	health_bar = ProgressBar.new()
	column.add_child(health_bar)
	health_bar.custom_minimum_size = Vector2(400,20)
	ult_bar = ProgressBar.new()
	column.add_child(ult_bar)
	skills_label = Label.new()
	column.add_child(skills_label)
	skills_label.add_theme_font_size_override("font_size",16)
	notice = Label.new()
	ui.add_child(notice)
	notice.anchor_top = 1.0
	notice.anchor_bottom = 1.0
	notice.offset_left = 24.0
	notice.offset_top = -112.0
	notice.offset_right = 940.0
	notice.offset_bottom = -18.0
	notice.text = "WASD Mover · Mouse Cámara · Espacio Saltar\nClic izq. M1 · 4.º: suelo Normal / subiendo Uppercut / cayendo Downslam\nQ Dash · 1–4 Habilidades · F Bloquear · G Ultimate / Evolución\nClic rueda Mira Lock · Rueda Zoom · R Reiniciar · Esc Pausa"

	crosshair = Label.new()
	ui.add_child(crosshair)
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 26)
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.anchor_left = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -20.0
	crosshair.offset_right = 20.0
	crosshair.offset_top = -20.0
	crosshair.offset_bottom = 20.0
	crosshair.visible = false

	pause_panel = PanelContainer.new()
	ui.add_child(pause_panel)
	pause_panel.position = Vector2(450,260)
	var pause_label := Label.new()
	pause_label.text = "  PAUSA\n  Esc para continuar  "
	pause_label.add_theme_font_size_override("font_size",28)
	pause_panel.add_child(pause_label)
	pause_panel.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_child(moves)
	moves.setup(self)
	add_child(presentation)
	add_child(feedback)
	feedback.setup(self)
	presentation.setup(self)
	add_child(robots); robots.setup(self)
	add_child(robot_clearance); robot_clearance.setup(self)
	add_child(performance_capture); performance_capture.setup(self)
	add_child(fusion); fusion.setup(self)
	add_child(skill_vfx); skill_vfx.setup(self)
	add_child(interface)
	interface.setup(self)
	ui.remove_child(crosshair)
	interface.screen.add_child(crosshair)
	update_camera(1.0)
	if arena.punchline != null: arena.punchline.finalize()
	# Diagnóstico opcional, inactivo por defecto y sin coste durante el juego normal.
	if OS.get_environment("PUNCHLINE_PERF_TRACE") == "1":
		var probe_path := "res://qa/perf_fusion_trace.gd"
		if ResourceLoader.exists(probe_path):
			var perf_script: Script = load(probe_path)
			var perf_probe: Node = perf_script.new()
			perf_probe.host = self
			add_child(perf_probe)

func set_paused(value: bool) -> void:
	paused = value
	fusion.damage.set_paused(value)
	if skill_vfx.dust != null: skill_vfx.dust.paused = value
	if is_instance_valid(skill_vfx.jets):
		for emitter in skill_vfx.jets.trails: emitter.speed_scale = 0 if value else 1
	if fusion.sequence != null and fusion.sequence._thruster_voice != null: fusion.sequence._thruster_voice.stream_paused = value
	if fusion.sequence != null:
		if fusion.sequence.engine_voice != null: fusion.sequence.engine_voice.stream_paused = value
		if fusion.sequence.dust != null: fusion.sequence.dust.paused = value
	attack_buffer = 0
	ability_buffer = 0
	jump_buffer = 0
	feedback.set_paused(value)
	if is_instance_valid(physical_ragdoll): physical_ragdoll.pause_simulation(value)
	if robots.active and value: robots.stop_locomotion()
	rig_anim.active = not value and not fusion.busy() and moves.player_freeze <= 0 and not (is_instance_valid(physical_ragdoll) and physical_ragdoll.active)
	locomotion_tree.process_mode = Node.PROCESS_MODE_DISABLED if value or moves.player_freeze > 0 else Node.PROCESS_MODE_INHERIT
	for enemy in enemies:
		if is_instance_valid(enemy.get("physics")): enemy.physics.pause_simulation(value)
		if enemy.rig_anim != null: enemy.rig_anim.active = not value and float(enemy.get("projection_freeze",0)) <= 0 and not (is_instance_valid(enemy.get("physics")) and enemy.physics.active)
	interface.pause_changed(value)
	if not value and input_pressed("attack"): hud_attack_requires_release = true
	Input.mouse_mode = hud_mouse_mode()

func reset_lab() -> void:
	if is_instance_valid(route_trial): route_trial.cancel()
	end_form()
	respawn_player()
	if arena.punchline == null: player.position = Vector3(0,0.05,5)
	model.rotation.y = 0
	charge = 0
	attack_cd = 0
	dash_cd = 0
	dash_time = 0
	skill3_cd = 0
	skill4_cd = 0
	attack_buffer = 0
	ability_buffer = 0
	for key in moves.cooldowns: moves.cooldowns[key] = 0.0
	for enemy in enemies: reset_enemy(enemy)
	interface.combo_life = 0
	camera_initialized = false

func create_dash_frame() -> void:
	dash_frame = preload("res://scripts/projection_frame.gd").new()
	add_child(dash_frame)
	dash_frame.setup()
	dash_frame.visible = false

func first_person_enabled() -> bool: return zoom <= .55

func camera_aim_locked() -> bool: return camera_lock or first_person_enabled()

func facing_forward() -> Vector3:
	if first_person_enabled(): return Vector3.FORWARD.rotated(Vector3.UP,yaw)
	var forward := -model.global_basis.z
	forward.y = 0
	if forward.length() < 0.001:
		return Vector3.FORWARD
	return forward.normalized()

func grounded_for_actions() -> bool:
	return player.is_on_floor()

func leave_to_main_menu() -> void:
	leave_to_scene("res://launcher.tscn")

func leave_to_scene(scene_path: String) -> void:
	var tree := get_tree()
	set_paused(false)
	var online := online_session()
	if online != null: online.leave()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	tree.change_scene_to_file.call_deferred(scene_path)

func can_start_action() -> bool:
	if fusion.fused: return fusion.combat.can_act() and fusion.boost_time <= 0
	return (not robots.active or robots.counter_recovery <= 0) and not fusion.busy() and moves.player_freeze <= 0 and not presentation.busy() and stun <= 0 and not player_ragdoll and dash_time <= 0 and skill_active == "" and attack_anim <= 0 and not block

func show_projection_frame(direction: Vector3, distance: float, life: float) -> void:
	var flat_dir := direction
	flat_dir.y = 0
	if flat_dir.length() < 0.01:
		flat_dir = facing_forward()
	flat_dir = flat_dir.normalized()
	dash_frame_life = life
	dash_frame.position = player.position + flat_dir*distance + Vector3(0,1.17,0)
	dash_frame.rotation = Vector3(0, atan2(-flat_dir.x,-flat_dir.z), 0)
	dash_frame.scale = Vector3(0.82,0.82,0.82)
	dash_frame.visible = true

func smooth_rotation(node: Node3D, target: Vector3, delta: float, speed: float) -> void:
	var weight: float = clampf(delta*speed, 0.0, 1.0)
	var current := node.rotation
	current.x = lerp_angle(current.x, target.x, weight)
	current.y = lerp_angle(current.y, target.y, weight)
	current.z = lerp_angle(current.z, target.z, weight)
	node.rotation = current

func smooth_model_tilt(node: Node3D, target_x: float, target_z: float, delta: float, speed: float) -> void:
	var weight: float = clampf(delta*speed, 0.0, 1.0)
	var current := node.rotation
	current.x = lerp_angle(current.x, target_x, weight)
	current.z = lerp_angle(current.z, target_z, weight)
	node.rotation = current

func smooth_player_neutral(delta: float, speed: float = 13.0) -> void:
	smooth_model_tilt(model, 0.0, 0.0, delta, speed)
	smooth_rotation(arm_left, Vector3.ZERO, delta, speed)
	smooth_rotation(arm_right, Vector3.ZERO, delta, speed)
	smooth_rotation(elbow_left, Vector3(0.12,0,0), delta, speed)
	smooth_rotation(elbow_right, Vector3(0.12,0,0), delta, speed)
	smooth_rotation(leg_left, Vector3.ZERO, delta, speed)
	smooth_rotation(leg_right, Vector3.ZERO, delta, speed)

var hud_cursor := false
var hud_attack_requires_release := false

func hud_mouse_mode() -> int:
	return Input.MOUSE_MODE_VISIBLE if paused or hud_cursor or (interface != null and interface.emote_wheel != null and interface.emote_wheel.visible) else Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if hp<=0 and not (event is InputEventKey and event.keycode==KEY_ESCAPE): return
	if event.is_action_released("ability1") and fusion.fused: fusion.combat.release_cannon()
	if not paused and domain_inspector.input(event): return
	if event is InputEventKey and event.keycode == KEY_ALT and not event.echo:
		hud_cursor = event.pressed
		if not event.pressed and input_pressed("attack"): hud_attack_requires_release = true
		Input.mouse_mode = hud_mouse_mode()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("character"):
			interface.toggle_character()
			return
		if event.keycode == KEY_ESCAPE:
			if interface.character_popup.visible: interface.close_character()
			elif paused: set_paused(false)
			else: interface.open_menu("test")
			return
		if paused:
			return
		if event.keycode == KEY_V and not preferences.bindings.values().has(KEY_V):
			zoom = maxf(2.0,float(preferences.values.camera_distance)) if zoom <= .55 else 0.0
			return
		if event.is_action_pressed("interact"):
			if fusion.spider.interact():return
			arena.urban.interact(); return
		if fusion.spider.active():
			if event.is_action_pressed("spider_vision"):fusion.spider.cycle_vision()
			if event.is_action_pressed("jump"):fusion.spider.request_jump()
			for slot in range(1,3):
				if event.is_action_pressed("ability"+str(slot)):fusion.spider.ability(slot)
			return
		if event.is_action_pressed("kogane"):
			presentation.toggle_kogane()
		if event.is_action_pressed("lock"):
			camera_lock = not camera_lock; crosshair.visible = camera_lock
		if event.is_action_pressed("emote"):
			presentation.toggle_emote()
		if event.is_action_pressed("jump") or event.is_action_pressed("dash") or event.is_action_pressed("transform") or event.is_action_pressed("ability1") or event.is_action_pressed("ability2") or event.is_action_pressed("ability3") or event.is_action_pressed("ability4"):
			presentation.cancel_emote()
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		if event.is_action_pressed("jump"):
			jump_buffer = 0.12
		if event.is_action_pressed("transform"):
			moves.transform_input()
		if event.is_action_pressed("dash") and dash_cd <= 0 and can_start_action():
			start_dash()
		for index in range(1,5):
			if event.is_action_pressed("ability"+str(index)):
				if can_start_action():
					moves.press(index)
				else:
					buffered_ability = index
					ability_buffer = 0.16

	if paused:
		return
	if (hud_cursor or interface.emote_wheel.visible) and (event is InputEventMouseMotion or event is InputEventMouseButton): return
	if fusion.cinematic and (event is InputEventMouseMotion or event is InputEventMouseButton): return
	if event is InputEventMouseMotion:
		var sensitivity: float = 0.003*float(preferences.values.sensitivity)
		yaw -= event.relative.x*sensitivity
		pitch = clampf(pitch-event.relative.y*sensitivity,-1.35 if first_person_enabled() else -1.05,1.35 if first_person_enabled() else .25)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if hud_attack_requires_release: return
			if attack_cd <= 0: punch()
			else: attack_buffer = 0.16
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			camera_lock = not camera_lock
			crosshair.visible = camera_lock
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = maxf(0.0, zoom-0.4)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = minf(10.0, zoom+0.4)

func movement() -> Vector3:
	var axis := Input.get_vector("left","right","forward","back")
	var input := Vector3(axis.x,0,axis.y)
	return input.normalized().rotated(Vector3.UP,yaw)

func start_dash() -> void:
	if fusion.spider!=null and fusion.spider.active():return
	if fusion.fused:
		fusion.start_boost()
		return
	if dash_cd > 0.0 or dash_time > 0.0 or paused or not can_start_action(): return
	if fusion.cinematic: return
	if moves.player_freeze > 0: return
	feedback.sound("dash",player.position,-9.0)
	feedback.particles(player.position,Color("b6b0c5"),true,5)
	dash_dir = movement()
	if dash_dir.length() < 0.1:
		dash_dir = facing_forward()
	dash_dir.y = 0
	dash_dir = dash_dir.normalized()
	dash_time = DASH_DURATION
	dash_cd = DASH_COOLDOWN
	# El frame queda delante y Naoya lo atraviesa durante el dash.
	if not robots.active: show_projection_frame(dash_dir, 1.9, 0.28)

func select_fourth_variant() -> String:
	# El cuarto M1 depende únicamente del estado aéreo; Espacio ya no activa el golpe.
	# Cerca del ápice (< 1.0) ya cuenta como caída para que el downslam sea consistente.
	if not player.is_on_floor():
		if player.velocity.y < 1.0:
			return "downslam"
		return "uppercut"
	return "normal"

func punch() -> void:
	if fusion.spider!=null and fusion.spider.active():return
	if moves.player_freeze > 0: return
	if fusion.fused:
		attack_buffer = .16; return
	if robots.active: robots.punch(); return
	presentation.cancel_emote()
	if presentation.transition_time > 0:
		return
	# El golpe real se resuelve durante el punto de contacto de la animación.
	var blocking_now := input_pressed("block") and stun <= 0 and attack_anim <= 0 and dash_time <= 0 and not player_ragdoll
	if attack_cd > 0 or stun > 0 or block or blocking_now or dash_time > 0 or player_ragdoll or skill_active != "":
		return
	if combo_timeout <= 0:
		combo = 0
	combo = combo%4+1
	combo_timeout = 0.95
	attack_cd = 0.68 if combo == 4 else 0.33
	attack_anim = FINISHER_TIME if combo == 4 else ATTACK_TIME
	attack_variant = select_fourth_variant() if combo == 4 else "normal"
	attack_hit_done = false
	punch_visual = "combat/MixamoCross" if combo == 2 else "combat/Hook"
	if combo == 3 and not find_skill_target(1.45,0.2,facing_forward()).is_empty(): punch_visual = "combat/MixamoElbow"

func enemy_blocks_hit(enemy: Dictionary, flat_offset: Vector3) -> bool:
	if int(enemy.kind) != 1 or float(enemy.stun) > 0 or flat_offset.length() < 0.01:
		return false
	var actor: CharacterBody3D = enemy.body
	return (-actor.global_basis.z).dot(-flat_offset.normalized()) > 0.2

func interrupt_enemy_attack(enemy: Dictionary) -> void:
	enemy.attack_phase = "idle"
	enemy.attack_timer = 0.0
	enemy.attack_anim = 0.0
	enemy.cd = maxf(float(enemy.cd), 0.25)

func perform_hit(enemy: Dictionary, damage: float, charge_gain: float, forward: Vector3, horizontal_force: float, vertical_force: float, stun_time: float, ragdoll_time: float = 0.0, slam: bool = false, unblockable: bool = false, audio_id: String = "") -> bool:
	var actor: CharacterBody3D = enemy.body
	if float(enemy.hp) <= 0 or bool(enemy.ragdoll) or float(enemy.get("wakeup_protection", 0.0)) > 0:
		return false
	var offset: Vector3 = actor.position-player.position
	var flat_offset := Vector3(offset.x,0,offset.z)
	var crystallized := float(enemy.get("projection_freeze",0)) > 0
	if not crystallized and not unblockable and enemy_blocks_hit(enemy, flat_offset):
		enemy.flash = 0.12
		feedback.sound("block",actor.position,-6.0)
		presentation.comment("blocked")
		feedback.particles(actor.position+Vector3.UP,Color("ead6a2"),false,6)
		return false

	if crystallized: moves.break_enemy_frame(enemy,"hit")
	feedback.sound(audio_id if audio_id != "" else ("heavy" if damage >= 12 else "hit"),actor.position)
	feedback.particles(actor.position+Vector3.UP,Color("e8d8c2"),false,8)
	feedback.damage_number(actor.position+Vector3.UP*1.7,damage)
	interface.confirm_hit(damage)
	impact_freeze = 0.025 if damage < 12 else 0.045
	camera_kick = maxf(camera_kick,0.18 if damage < 12 else 0.32)
	enemy["hit_pause"] = impact_freeze
	enemy.hp = maxf(0.0, float(enemy.hp)-damage)
	add_charge(charge_gain)
	enemy.flash = 0.16
	interrupt_enemy_attack(enemy)
	enemy.stun = maxf(float(enemy.stun), stun_time)

	if ragdoll_time > 0.0:
		enemy["ragdoll_impact"] = {"kind":"downslam" if slam else ("uppercut" if vertical_force >= 6 else "horizontal"),"direction":forward,"side":-1.0 if combo % 2 == 0 else 1.0}
		enemy.ragdoll = true
		enemy.ragdoll_time = maxf(float(enemy.ragdoll_time), ragdoll_time)
		enemy.ragdoll_grounded = false
		enemy.slam_pending = slam
		if slam:
			actor.velocity = Vector3(0,-18.0,0)
			if actor.is_on_floor():
				enemy.ragdoll_grounded = true
		else:
			actor.velocity = forward*horizontal_force + Vector3.UP*vertical_force
	else:
		actor.velocity = forward*horizontal_force + Vector3.UP*vertical_force

	if float(enemy.hp) <= 0:
		enemy.respawn = 3.0
		enemy.ragdoll = true
		enemy.ragdoll_time = maxf(float(enemy.ragdoll_time), 3.0)
	return true

func resolve_punch_hit() -> void:
	var forward := facing_forward()
	arena.urban.hit_props(player.global_position,forward)
	for enemy in enemies:
		var actor: CharacterBody3D = enemy.body
		var offset: Vector3 = preload("res://scripts/combat_geometry.gd").offset(enemy,player.global_position)
		var flat_offset := Vector3(offset.x,0,offset.z)
		if float(enemy.hp) <= 0 or bool(enemy.ragdoll) or float(enemy.get("wakeup_protection", 0.0)) > 0 or flat_offset.length() >= 2.7 or absf(offset.y) > 2.2:
			continue
		if not moves.projection.line_of_sight(enemy): continue
		if flat_offset.length() < 0.01 or forward.dot(flat_offset.normalized()) <= 0.35:
			continue

		if combo < 4:
			perform_hit(enemy, tuning.m1_damage, M1_CHARGE, forward, 2.5, 0.0, NORMAL_STUN,0,false,false,"m1_"+str(combo))
		else:
			match attack_variant:
				"uppercut":
					perform_hit(enemy, tuning.uppercut_damage, FOURTH_M1_CHARGE, forward, 3.2, 11.5, FOURTH_HIT_STUN, FOURTH_HIT_STUN,false,false,"uppercut")
				"downslam":
					perform_hit(enemy, tuning.downslam_damage, FOURTH_M1_CHARGE, forward, 0.0, -18.0, FOURTH_HIT_STUN, FOURTH_HIT_STUN, true, true,"downslam")
				_:
					perform_hit(enemy, tuning.fourth_m1_damage, FOURTH_M1_CHARGE, forward, 12.0, 2.2, FOURTH_HIT_STUN, FOURTH_HIT_STUN,false,false,"m1_4")

func update_player_attack_hit() -> void:
	if robots.active: return
	if attack_anim <= 0 or attack_hit_done:
		return
	var total: float = FINISHER_TIME if combo == 4 else ATTACK_TIME
	var progress: float = clampf(1.0-attack_anim/total, 0.0, 1.0)
	var contact_point: float = 0.42 if combo == 4 else 0.38
	if progress >= contact_point:
		attack_hit_done = true
		resolve_punch_hit()

func start_skill3() -> void:
	skill3_start_position = player.global_position
	rush_target = {}
	rush_hits = 0
	skill3_cd = SKILL3_COOLDOWN
	skill_active = "skill3"
	skill_phase = "windup"
	skill_timer = 0.12
	skill_hit_done = false
	skill_connected = false
	skill_dir = facing_forward()
	combo_timeout = 0.0
	combo = 0

func start_skill4() -> void:
	kick_visual = "mixamo/Kick_To_The_Groin" if not find_skill_target(1.65,0.2,facing_forward()).is_empty() else "combat/Kick"
	skill4_cd = SKILL4_COOLDOWN
	skill_active = "skill4"
	skill_phase = "windup"
	skill_timer = 0.17
	skill_hit_done = false
	skill_connected = false
	skill_dir = facing_forward()
	combo_timeout = 0.0
	combo = 0

func find_skill_target(max_range: float, min_dot: float, direction_override: Vector3 = Vector3.ZERO) -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = max_range + 1.0
	for enemy in enemies:
		if float(enemy.hp) <= 0 or bool(enemy.ragdoll) or float(enemy.get("wakeup_protection",0)) > 0:
			continue
		var actor: CharacterBody3D = enemy.body
		var offset: Vector3 = actor.position-player.position
		var flat_offset := Vector3(offset.x,0,offset.z)
		var distance: float = flat_offset.length()
		if distance <= 0.01 or distance > max_range:
			continue
		if (skill_dir if direction_override == Vector3.ZERO else direction_override).dot(flat_offset.normalized()) < min_dot:
			continue
		if not moves.projection.line_of_sight(enemy): continue
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best

# Barrido físico host-autoritativo para la habilidad 3: evita perder impactos
# cuando el atacante avanza más de un radio entre dos ticks de red.
func find_rush_swept_target() -> Dictionary:
	var best: Dictionary = {}
	var best_distance := 1.35
	var start := skill3_start_position
	var end := player.global_position+skill_dir*0.8
	for enemy in enemies:
		if float(enemy.hp) <= 0 or bool(enemy.ragdoll) or float(enemy.get("wakeup_protection",0)) > 0: continue
		var point: Vector3 = enemy.body.global_position
		if absf(point.y-player.global_position.y) > 2.2: continue
		var a := Vector3(start.x,0,start.z)
		var b := Vector3(end.x,0,end.z)
		var q := Vector3(point.x,0,point.z)
		var nearest := Geometry3D.get_closest_point_to_segment(q,a,b)
		var dist: float = nearest.distance_to(q)
		if dist >= best_distance: continue
		if not moves.projection.line_of_sight(enemy): continue
		var contact := Vector3(nearest.x,player.global_position.y+1.0,nearest.z)
		var ray := PhysicsRayQueryParameters3D.create(start+Vector3.UP,contact,1)
		ray.exclude = [player.get_rid(),enemy.body.get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		best = enemy
		best_distance = dist
	return best

func resolve_skill3_hit() -> void:
	if skill_hit_done:
		return
	skill_hit_done = true
	var target := find_skill_target(3.15, 0.20)
	if target.is_empty(): target = find_rush_swept_target()
	if target.is_empty():
		skill_connected = false
		return
	skill_connected = perform_hit(target,tuning.rush_first_damage,4.0,skill_dir,0.0,0.0,0.35)
	if skill_connected:
		rush_target = target
		rush_hits = 1

func resolve_skill4_hit() -> void:
	if skill_hit_done:
		return
	skill_hit_done = true
	var target := find_skill_target(3.0, 0.12)
	if target.is_empty():
		skill_connected = false
		return
	skill_connected = perform_hit(target, tuning.kick_damage, SKILL4_CHARGE, skill_dir, 8.5, 1.0, 0.66,0,false,false,"kick")

func cancel_skill() -> void:
	if robots.active: robots.cancel()
	if is_instance_valid(moves) and moves.game != null:
		moves.cancel()
	skill_active = ""
	skill_phase = ""
	skill_timer = 0.0
	skill_hit_done = false
	skill_connected = false

func update_skill(delta: float) -> void:
	if skill_active == "extra":
		moves.tick_skill(delta)
		return
	if skill_active == "":
		return
	skill_timer = maxf(0.0, skill_timer-delta)

	# El impacto ocurre dentro de la fase visual, no al inicio de la skill.
	if skill_active == "skill3" and skill_phase == "rush" and not skill_hit_done and skill_timer <= 0.055:
		resolve_skill3_hit()
	if skill_active == "skill4" and skill_phase == "strike" and not skill_hit_done and skill_timer <= 0.060:
		resolve_skill4_hit()

	if skill_timer > 0.0:
		return

	if skill_active == "skill3":
		match skill_phase:
			"windup":
				skill_phase = "rush"
				skill_timer = 0.18
				show_projection_frame(skill_dir, 1.65, 0.25)
			"rush":
				if not skill_hit_done:
					resolve_skill3_hit()
				skill_phase = "barrage" if skill_connected else "recovery"
				skill_timer = 0.09 if skill_connected else SKILL3_MISS_RECOVERY
			"barrage":
				if not rush_target.is_empty() and float(rush_target.hp) > 0 and rush_target.body.position.distance_to(player.position) < 3.8:
					var final_hit := rush_hits == 2
					perform_hit(rush_target,tuning.rush_follow_damage,5.0,skill_dir,10.5 if final_hit else 0.0,1.4 if final_hit else 0.0,0.78 if final_hit else 0.35)
				rush_hits += 1
				if rush_hits >= 3:
					skill_phase = "recovery"
					skill_timer = SKILL3_HIT_RECOVERY
				else:
					skill_timer = 0.09
			"recovery":
				cancel_skill()
	elif skill_active == "skill4":
		match skill_phase:
			"windup":
				skill_phase = "strike"
				skill_timer = 0.12
			"strike":
				if not skill_hit_done:
					resolve_skill4_hit()
				skill_phase = "recovery"
				skill_timer = SKILL4_RECOVERY
			"recovery":
				cancel_skill()

func _physics_process(delta: float) -> void:
	if not input_pressed("attack"): hud_attack_requires_release = false
	if paused:
		return

	if interface.emote_wheel.visible and (stun > 0 or player_ragdoll or moves.player_freeze > 0): interface.close_emotes()
	if fusion.tick(delta):
		feedback.tick(delta); skill_vfx.tick(delta)
		if not fusion.cinematic: presentation.tick(delta)
		for enemy in enemies: update_enemy(enemy,delta)
		interface.tick(delta); return
	skill_vfx.tick(delta)
	clock += delta
	robots.tick(delta)
	route_trial.tick(delta)
	preview_time = maxf(0,preview_time-delta)
	if moves.tick_player_freeze(delta):
		update_ultimate(delta)
		moves.tick(delta)
		feedback.tick(delta)
		presentation.tick(delta)
		for enemy in enemies: update_enemy(enemy,delta)
		interface.tick(delta)
		return
	impact_freeze = maxf(0,impact_freeze-delta)
	attack_buffer = maxf(0,attack_buffer-delta)
	ability_buffer = maxf(0,ability_buffer-delta)
	jump_buffer = maxf(0,jump_buffer-delta)
	coyote_time = 0.10 if player.is_on_floor() else maxf(0,coyote_time-delta)
	stun = maxf(0.0, stun-delta)
	attack_cd = maxf(0.0, attack_cd-delta)
	attack_anim = maxf(0.0, attack_anim-delta)
	combo_timeout -= delta
	dash_cd = maxf(0.0,dash_cd-delta)
	skill3_cd = maxf(0.0, skill3_cd-delta)
	skill4_cd = maxf(0.0, skill4_cd-delta)
	landing_anim = maxf(0.0, landing_anim-delta)
	wakeup_anim = maxf(0.0, wakeup_anim-delta)
	dash_time = maxf(0.0,dash_time-delta)
	dash_frame_life -= delta
	player_ragdoll_time = maxf(0.0, player_ragdoll_time-delta)
	block_recoil_time = maxf(0.0, block_recoil_time-delta)
	player_wakeup_protection = maxf(0.0, player_wakeup_protection-delta)
	update_ultimate(delta)
	moves.tick(delta)
	feedback.tick(delta)
	presentation.tick(delta)
	update_skill(delta)
	update_player_attack_hit()

	if player_ragdoll and player_ragdoll_time <= 0:
		if is_instance_valid(physical_ragdoll): physical_ragdoll.stop(true)
		player_ragdoll = false
		wakeup_anim = 0.34
		player_wakeup_protection = maxf(player_wakeup_protection, WAKEUP_PROTECTION_DURATION)

	block = (not robots.active or robots.counter_recovery <= 0) and not presentation.busy() and (input_pressed("block") or (robots.active and robots.guard_time > 0)) and stun <= 0 and attack_anim <= 0 and dash_time <= 0 and not player_ragdoll and skill_active == ""
	if stun > 0 or player_ragdoll or block:
		attack_buffer = 0
		ability_buffer = 0
	if jump_buffer > 0 and coyote_time > 0 and not presentation.busy() and stun <= 0 and not player_ragdoll and skill_active == "":
		player.velocity.y = JUMP_FORCE
		feedback.sound("jump",player.position,-15)
		jump_buffer = 0
		coyote_time = 0
	if ability_buffer > 0 and can_start_action():
		ability_buffer = 0
		moves.press(buffered_ability)
	elif (attack_buffer > 0 or (bool(preferences.values.hold_attack) and input_pressed("attack") and not hud_cursor and not interface.emote_wheel.visible and not hud_attack_requires_release)) and attack_cd <= 0 and can_start_action():
		attack_buffer = 0
		punch()
	var dir := Vector3.ZERO if domain_inspector.active else movement()
	var speed := 2.2 if block else SPEED*form_speed_mult()
	if robots.active and not block: speed = 6.0*form_speed_mult()
	if input_pressed("walk") and not block: speed = 2.4*form_speed_mult()

	if player_ragdoll:
		if form == "BASE" and is_instance_valid(physical_ragdoll): physical_ragdoll.start(player.velocity,player_ragdoll_impact)
		if not physical_ragdoll.active:
			player.velocity.x = move_toward(player.velocity.x,0.0,delta*7.0)
			player.velocity.z = move_toward(player.velocity.z,0.0,delta*7.0)
	elif stun > 0:
		player.velocity.x = move_toward(player.velocity.x,0.0,delta*15.0)
		player.velocity.z = move_toward(player.velocity.z,0.0,delta*15.0)
	elif presentation.busy():
		player.velocity.x = 0
		player.velocity.z = 0
	elif skill_active != "":
		if skill_active == "robot":
			var robot_velocity: Vector3 = robots.velocity()
			player.velocity.x = robot_velocity.x; player.velocity.z = robot_velocity.z
		elif skill_active == "extra":
			var ability_velocity: Vector3 = moves.skill_velocity(delta)
			player.velocity.x = ability_velocity.x
			player.velocity.z = ability_velocity.z
		elif skill_active == "skill3" and skill_phase == "rush":
			player.velocity.x = skill_dir.x*SKILL3_RUSH_SPEED
			player.velocity.z = skill_dir.z*SKILL3_RUSH_SPEED
		else:
			player.velocity.x = move_toward(player.velocity.x,0.0,delta*24.0)
			player.velocity.z = move_toward(player.velocity.z,0.0,delta*24.0)
	else:
		var response := 58.0 if dir.length() < 0.05 else 46.0
		player.velocity.x = move_toward(player.velocity.x,dir.x*speed,delta*response)
		player.velocity.z = move_toward(player.velocity.z,dir.z*speed,delta*response)
		if camera_aim_locked():
			# Mira lock: Naoya siempre encara la dirección frontal de la cámara.
			model.rotation.y = lerp_angle(model.rotation.y, yaw, delta*22.0)
		elif dir.length() > 0.1:
			model.rotation.y = lerp_angle(model.rotation.y,atan2(-dir.x,-dir.z),delta*18.0)
		if block:
			model.rotation.y = lerp_angle(model.rotation.y, yaw, delta*24.0)
		if dash_time > 0:
			player.velocity.x = dash_dir.x*DASH_SPEED*robots.speed_mult()
			player.velocity.z = dash_dir.z*DASH_SPEED*robots.speed_mult()

	# Mantener gravedad constante conserva un contacto estable con el piso.
	if is_instance_valid(physical_ragdoll) and physical_ragdoll.active:
		physical_ragdoll.follow_actor()
	else:
		player.velocity.y -= GRAVITY*delta
		if stun <= 0 and dash_time <= 0 and not presentation.busy(): preload("res://scripts/terrain_steps.gd").prepare(player,delta)
		robot_clearance.tick(delta)
		player.move_and_slide()
	var on_floor_now: bool = player.is_on_floor()
	descending_time = descending_time+delta if not on_floor_now and player.velocity.y < -0.5 and not player_ragdoll else 0.0
	if on_floor_now and not was_on_floor and not player_ragdoll:
		landing_anim = 0.18
		feedback.sound("step2",player.position,-5)
	was_on_floor = on_floor_now

	if player.position.y < -12:
		respawn_player()

	update_dash_effect(delta)
	moves.projection.update_gate()
	animate_player(dir, delta)
	update_rig_animation(dir)
	sync_rig_transform()
	if robots.active: robot_clearance.apply_base_pose()
	for enemy in enemies:
		update_enemy(enemy,delta)

	interface.tick(delta)

	var state_text := "LISTO"
	if player_ragdoll:
		state_text = "RAGDOLL / ATURDIDO"
	elif block_recoil_time > 0:
		state_text = "BLOCKSTUN"
	elif block:
		state_text = "BLOQUEANDO"
	elif stun > 0:
		state_text = "ATURDIDO"
	elif player_wakeup_protection > 0:
		state_text = "PROTECCIÓN AL LEVANTARSE"
	var combo_text := "M1 %d/4" % combo if combo_timeout > 0 else "M1 listo"
	var variant_text := ""
	if combo == 4 and attack_anim > 0:
		variant_text = " · %s" % attack_variant.to_upper()
	var lock_text := "ON" if camera_lock else "OFF"
	hud.text = "NAOYA · LABORATORIO %s · PROYECCIÓN\nVida %d / 100 · %s\n%s%s · %s · MIRA LOCK %s" % [BuildInfo.version,int(hp),state_text,combo_text,variant_text,ult_hud_text(),lock_text]
	if ult_msg_time > 0:
		hud.text += "\n>> %s" % ult_msg
	health_bar.value = hp
	ult_bar.value = charge if form == "BASE" else ult_time/ult_duration*100.0
	skills_label.text = moves.hud_text()

func _process(delta: float) -> void:
	if not paused and is_instance_valid(camera): update_camera(delta)
	if not paused: domain_inspector.update(delta)

func toggle_enemy_gallery() -> void:
	if is_instance_valid(gallery): gallery.queue_free(); gallery = null; return
	gallery = load("res://scripts/enemy_gallery.gd").new()
	add_child(gallery); gallery.position = Vector3(0,.05,10)
	gallery.setup(appearance_seed)
	player.position = Vector3(0,.05,16); model.rotation.y = 0; yaw = 0; camera_initialized = false

func preview_clip(name: String) -> void:
	reset_lab()
	if not rig_anim.has_animation(name): return
	preview_animation = name; preview_time = rig_anim.get_animation(name).length
	set_paused(false)

func randomize_enemy_appearances(seed_value: int) -> void:
	appearance_seed = seed_value
	for i in range(enemies.size()): enemies[i].appearance = appearance.apply(enemies[i].rig_scene,seed_value,i)

func update_camera(delta: float) -> void:
	if fusion.cinematic or fusion.death_broken: camera_view.restore()
	if fusion.camera_update(camera,delta): fusion.camera_shake(camera,delta); return
	if camera_view.update(self,camera,zoom,yaw,pitch,delta): return
	camera.near = .12
	var target := player.get_global_transform_interpolated().origin + Vector3.UP*camera_view.eye_height(self)*.88
	if not camera_initialized or camera_target.distance_to(target) > 8:
		camera_target = target
		camera_initialized = true
	else:
		camera_target = camera_target.lerp(target,1-exp(-delta*16))
	var desired := camera_target+Vector3(0,0,zoom*(1.6 if fusion.fused else 1.0)).rotated(Vector3.RIGHT,pitch).rotated(Vector3.UP,yaw)
	var query := PhysicsRayQueryParameters3D.create(camera_target,desired)
	var excluded: Array[RID] = [player.get_rid()]
	for enemy in enemies: excluded.append(enemy.body.get_rid())
	if is_instance_valid(physical_ragdoll):
		for bone in physical_ragdoll.bodies: excluded.append(bone.get_rid())
	for enemy in enemies:
		if is_instance_valid(enemy.get("physics")):
			for bone in enemy.physics.bodies: excluded.append(bone.get_rid())
	query.exclude = excluded
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty(): desired = hit.position + hit.normal*0.25
	camera_kick = maxf(0,camera_kick-delta*2.5)
	var kick: float = camera_kick*float(preferences.values.shake)
	desired += Vector3(sin(clock*83),cos(clock*97),0)*kick*0.075
	camera.position = fusion.blend_camera(camera,desired,delta)
	camera.look_at(camera_target)
	var target_fov: float = float(preferences.values.fov) + (6.0 if moves.stage == "rush" or dash_time > 0 else minf(2,Vector2(player.velocity.x,player.velocity.z).length()*0.2))
	camera.fov = lerpf(camera.fov,target_fov,1-exp(-delta*10))
	fusion.camera_shake(camera,delta)

func cooldown_text(value: float) -> String:
	if value <= 0.0:
		return "LISTA"
	return "%.1fs" % value

func update_dash_effect(delta: float) -> void:
	var target_blend := 1.0 if dash_time > 0 else 0.0
	dash_pose_blend = move_toward(dash_pose_blend, target_blend, delta*10.0)
	if dash_frame_life > 0:
		dash_frame.visible = true
		var pulse := 1.0 + sin(clock*42.0)*0.04
		dash_frame.scale = Vector3.ONE*pulse
	else:
		dash_frame.visible = false

func ult_ready() -> bool:
	if robots.active: return false
	return form == "BASE" and charge >= 100.0

func add_charge(amount: float) -> void:
	if robots.active:
		if not fusion.busy(): charge = clampf(charge+maxf(0,amount),0,100)
		return
	if form == "FORM1":
		moves.add_evolution_charge(amount)
	if form != "BASE":
		return
	charge = minf(100.0, charge+amount)

func form_speed_mult() -> float:
	if robots.active: return robots.speed_mult()
	match form:
		"FORM1":
			return FORM1_SPEED_MULT
		"FORM2":
			return FORM2_SPEED_MULT
	return 1.0

func start_form(new_form: String, laboratory: bool = false) -> void:
	if robots.active: return
	if new_form not in ["FORM1", "FORM2"]: return
	if not laboratory:
		if new_form == "FORM1" and form != "BASE": return
		if new_form == "FORM2" and (form != "FORM1" or moves.phase_charge < 100.0): return
	var previous_form := form
	cancel_skill()
	attack_anim = 0.0
	attack_hit_done = true
	dash_time = 0.0
	form = new_form
	ult_duration = ULT_FORM1_DURATION if new_form == "FORM1" else ULT_FORM2_DURATION
	ult_time = ult_duration
	charge = 0.0
	domain_used = false
	ult_msg = "FORMA 1 ACTIVADA" if new_form == "FORM1" else "FORMA 2 ACTIVADA"
	ult_msg_time = 2.0
	moves.form_changed()
	# La nueva forma hereda el frente actual y no conserva un yaw obsoleto.
	model.rotation.y = yaw
	presentation.begin_transition(previous_form)

func end_form() -> void:
	moves.clear_player_frame()
	presentation.reset()
	cancel_skill()
	form = "BASE"
	ult_time = 0.0
	charge = 0.0
	moves.form_changed()
	presentation.reset()
	ult_msg = "TRANSFORMACIÓN TERMINADA"
	ult_msg_time = 2.0

func rebirth_phase1() -> void:
	if is_instance_valid(physical_ragdoll): physical_ragdoll.cancel()
	# Muerte con la barra llena: renace transformado en el mismo lugar con vida parcial.
	start_form("FORM1")
	hp = ULT_REBIRTH_HP
	stun = 0.0
	player_ragdoll = false
	player_ragdoll_time = 0.0
	block_recoil_time = 0.0
	player_wakeup_protection = WAKEUP_PROTECTION_DURATION
	player.velocity = Vector3.ZERO
	block = false
	attack_buffer = 0
	ability_buffer = 0
	jump_buffer = 0
	ult_msg = "RENACIMIENTO · FASE 1 · EVOLUCIÓN 0%"

func on_player_death() -> void:
	if fusion.spider.active():fusion.spider.destroy();return
	if fusion.fused:
		fusion.break_apart(); return
	if ult_ready():
		rebirth_phase1()
	else:
		respawn_player()

func update_ultimate(delta: float) -> void:
	ult_msg_time = maxf(0.0, ult_msg_time-delta)
	if form != "BASE" and presentation.transition_time <= 0:
		ult_time -= delta
		if ult_time <= 0.0:
			end_form()

func ult_hud_text() -> String:
	match form:
		"FORM1":
			return "FORMA 1 · %d s" % ceili(ult_time)
		"FORM2":
			return "FORMA 2 · %d s" % ceili(ult_time)
	if charge >= 100.0:
		return "ULT LISTA · pulsa G"
	return "ULT %d%%" % int(charge)

func respawn_player() -> void:
	if fusion.busy(): fusion.reset()
	route_trial.cancel()
	preview_time = 0
	if is_instance_valid(physical_ragdoll): physical_ragdoll.cancel()
	descending_time = 0
	moves.clear_player_frame()
	attack_buffer = 0
	ability_buffer = 0
	jump_buffer = 0
	presentation.reset()
	moves.end_domain()
	hp = 100.0
	max_hp = 100.0
	# La carga se conserva al morir/reaparecer. Una transformación activa termina.
	if form != "BASE":
		form = "BASE"
		ult_time = 0.0
		charge = 0.0
	stun = 0.0
	player_ragdoll = false
	player_ragdoll_time = 0.0
	block_recoil_time = 0.0
	player_wakeup_protection = WAKEUP_PROTECTION_DURATION
	cancel_skill()
	attack_anim = 0.0
	attack_hit_done = false
	wakeup_anim = 0.0
	landing_anim = 0.0
	block = false
	dash_time = 0.0
	combo = 0
	combo_timeout = 0.0
	moves.form_changed()
	player.position = Vector3(0,1,12)
	player.velocity = Vector3.ZERO
	if arena.punchline != null: arena.punchline.respawn()
	if robots.active: robots.spawn()

func hit_player_from_enemy(enemy: Dictionary, offset: Vector3) -> void:
	if fusion.cinematic: return
	if fusion.fused: fusion.receive_enemy(enemy,offset); return
	if moves.player_freeze <= 0:
		if robots.active:
			if robots.counter(enemy): return
		elif moves.counter(enemy): return
	# El impacto ocurre después del wind-up. Si el jugador aún está protegido o caído, falla.
	if player_ragdoll or stun > 0 or player_wakeup_protection > 0:
		return
	if moves.player_freeze > 0: moves.break_player_frame("hit")

	var attacker: CharacterBody3D = enemy.body
	var incoming := player.position-attacker.position
	incoming.y = 0
	var guarded := false
	if incoming.length() > 0.01:
		guarded = block and facing_forward().dot(-incoming.normalized()) > 0.25

	var attack_dir := offset.normalized() if offset.length() > 0.01 else -attacker.global_basis.z
	if guarded:
		feedback.sound("block",player.position,-3.0)
		# El cuarto golpe bloqueado no hace daño/ragdoll, pero sí una reacción fuerte y breve.
		if int(enemy.combo) == 4:
			stun = BLOCKSTUN_DURATION
			block_recoil_time = BLOCKSTUN_DURATION
			player.velocity.x = attack_dir.x*3.2
			player.velocity.z = attack_dir.z*3.2
		return

	if interface.emote_wheel.visible: interface.close_emotes()
	presentation.comment("emote_hit" if presentation.emote_time > 0 else "damage")
	presentation.reset()
	attack_buffer = 0
	ability_buffer = 0
	camera_kick = 0.4
	feedback.sound("hit",player.position)
	cancel_skill()
	attack_anim = 0.0
	attack_hit_done = true

	if int(enemy.combo) == 4:
		hp -= 10.0
		player_ragdoll_impact = {"kind":"horizontal","direction":attack_dir,"side":-1.0 if int(enemy.combo) % 2 == 0 else 1.0}
		add_charge(7.0)
		stun = FOURTH_HIT_STUN
		player_ragdoll = true
		player_ragdoll_time = FOURTH_HIT_STUN
		player.velocity = attack_dir*8.0 + Vector3.UP*3.2
	else:
		hp -= 6.0
		add_charge(4.0)
		stun = 0.3
		player.velocity += attack_dir*5.0

	if hp <= 0:
		on_player_death()

func reset_enemy(enemy: Dictionary) -> void:
	enemy["ragdoll_impact"] = {}
	if float(enemy.hp) <= 0 and bool(enemy.rig_enabled):
		enemy.appearance_generation = int(enemy.get("appearance_generation",0))+1
		var available: Array[int] = [0,1,2,3,4,5]
		for other in enemies:
			if other != enemy: available.erase(int(other.appearance.get("palette",-1)))
		var rng := RandomNumberGenerator.new()
		rng.seed = appearance_seed+int(enemy.appearance_generation)*7919+enemies.find(enemy)
		var forced: int = available[rng.randi_range(0,available.size()-1)] if not available.is_empty() else -1
		enemy.appearance = appearance.apply(enemy.rig_scene,appearance_seed,enemies.find(enemy)+int(enemy.appearance_generation)*enemies.size(),forced)
	if is_instance_valid(enemy.get("physics")): enemy.physics.cancel()
	var actor: CharacterBody3D = enemy.body
	var visual: Node3D = enemy.visual
	enemy.hp = 100.0
	enemy.stun = 0.0
	enemy.cd = 1.0
	enemy.flash = 0.0
	enemy.attack_anim = 0.0
	enemy.attack_phase = "idle"
	enemy.attack_timer = 0.0
	enemy.combo = 0
	enemy.combo_timeout = 0.0
	enemy.ragdoll = false
	enemy.ragdoll_time = 0.0
	enemy.ragdoll_grounded = false
	enemy.slam_pending = false
	enemy["sequence_hold"] = 0.0
	enemy["wakeup_protection"] = 0.0
	enemy["wakeup_time"] = 0.0
	enemy["dash_time"] = 0.0
	enemy["dash_cd"] = 0.0
	enemy["dash_dir"] = Vector3.ZERO
	actor.position = enemy.spawn
	actor.velocity = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	if bool(enemy.get("rig_enabled", false)):
		enemy.rig_current_anim = StringName()
		play_enemy_rig_animation(enemy, "UnarmedIdleAlert1", 0.0, 1.0)
	moves.enemy_reset(enemy)

func start_enemy_attack(enemy: Dictionary) -> void:
	if enemy.body.position.distance_to(player.position) < 7: presentation.comment("enemy_attack")
	if enemy.combo_timeout <= 0:
		enemy.combo = 0
	enemy.combo = int(enemy.combo)%4+1
	enemy.combo_timeout = 1.35
	enemy.attack_phase = "windup"
	enemy.attack_timer = 0.30 if int(enemy.combo) == 4 else 0.20
	enemy.attack_anim = enemy.attack_timer
	enemy.cd = 0.0

const DUMMY_NAMES := ["QUIETO", "BLOQUEADOR", "PERSEGUIDOR", "ATACANTE ESTACIONARIO", "ESQUIVA FINAL"]

func set_dummy_mode(enemy: Dictionary, mode: int) -> void:
	var position: Vector3 = enemy.body.position
	reset_enemy(enemy)
	enemy.kind = clampi(mode, 0, DUMMY_NAMES.size()-1)
	enemy.body.position = position

func start_enemy_dash(enemy: Dictionary, dash_direction: Vector3) -> bool:
	if enemy.body.position.distance_to(player.position) < 10: presentation.comment("enemy_dash")
	if float(enemy.get("dash_cd",0)) > 0 or float(enemy.stun) > 0 or bool(enemy.ragdoll) or float(enemy.get("projection_freeze",0)) > 0 or float(enemy.get("sequence_hold",0)) > 0 or float(enemy.get("wakeup_protection",0)) > 0:
		return false
	var flat := Vector3(dash_direction.x,0,dash_direction.z)
	if flat.length() < 0.01: return false
	enemy["dash_dir"] = flat.normalized()
	enemy["dash_time"] = DASH_DURATION
	enemy["dash_cd"] = DASH_COOLDOWN
	interrupt_enemy_attack(enemy)
	feedback.sound("dash",enemy.body.position,-9.0)
	return true

func update_enemy(enemy: Dictionary, delta: float) -> void:
	if moves.frozen_tick(enemy, delta):
		return
	enemy["hit_pause"] = maxf(0,float(enemy.get("hit_pause",0))-delta)
	if enemy.rig_anim != null:
		enemy.rig_anim.speed_scale = 0.0 if float(enemy.hit_pause) > 0 else 1.0
	var actor: CharacterBody3D = enemy.body
	var visual: Node3D = enemy.visual
	var label: Label3D = enemy.label
	enemy["dash_cd"] = maxf(0.0,float(enemy.get("dash_cd",0))-delta)
	enemy["wakeup_protection"] = maxf(0.0,float(enemy.get("wakeup_protection",0))-delta)
	enemy["wakeup_time"] = maxf(0.0,float(enemy.get("wakeup_time",0))-delta)
	enemy["sequence_hold"] = maxf(0.0,float(enemy.get("sequence_hold",0))-delta)
	enemy.stun = maxf(0.0, enemy.stun-delta)
	enemy.cd = maxf(0.0, float(enemy.cd)-delta)
	enemy.flash = maxf(0.0, enemy.flash-delta)
	enemy.attack_anim = maxf(0.0, enemy.attack_anim-delta)
	enemy.attack_timer = maxf(0.0, float(enemy.attack_timer)-delta)
	enemy.combo_timeout -= delta
	enemy.ragdoll_time = maxf(0.0, enemy.ragdoll_time-delta)
	enemy.walk_clock += delta

	if enemy.combo_timeout <= 0 and str(enemy.attack_phase) == "idle":
		enemy.combo = 0
	if enemy.ragdoll and enemy.ragdoll_time <= 0 and enemy.hp > 0:
		if is_instance_valid(enemy.get("physics")): enemy.physics.stop(true)
		enemy.ragdoll = false
		enemy.ragdoll_grounded = false
		enemy.slam_pending = false
		visual.rotation = Vector3.ZERO
		enemy.wakeup_time = tuning.wakeup_protection
		enemy.wakeup_protection = tuning.wakeup_protection

	visual.scale = Vector3.ONE*(1.05 if enemy.flash > 0 else 1.0)
	var names = DUMMY_NAMES
	var status := ""
	if enemy.ragdoll:
		status = " · RAGDOLL"
	elif enemy.stun > 0:
		status = " · STUN"
	elif enemy.wakeup_time > 0:
		status = " · RECUPERACIÓN"
	elif str(enemy.attack_phase) == "windup":
		status = " · PREPARA M1 %d" % int(enemy.combo)
	elif str(enemy.attack_phase) == "recovery":
		status = " · RECUPERA"
	label.text = "%s%s\n%d / 100" % [names[enemy.kind],status,int(enemy.hp)]
	label.modulate = Color("ffcf67") if enemy.flash > 0 or str(enemy.attack_phase) == "windup" else Color.WHITE

	if enemy.hp <= 0:
		enemy.respawn -= delta
		if enemy.respawn <= 0:
			reset_enemy(enemy)
		else:
			update_enemy_ragdoll_physics(enemy, delta)
			animate_enemy(enemy, delta)
		return

	var offset := player.position-actor.position
	offset.y = 0
	if fusion.spider.invisible():
		actor.velocity.x=move_toward(actor.velocity.x,0,delta*18);actor.velocity.z=move_toward(actor.velocity.z,0,delta*18)
		actor.velocity.y-=GRAVITY*delta;actor.move_and_slide();animate_enemy(enemy,delta);return

	if enemy.ragdoll:
		update_enemy_ragdoll_physics(enemy, delta)
		animate_enemy(enemy, delta)
		return
	if enemy.wakeup_time > 0 or enemy.sequence_hold > 0:
		actor.velocity.x = 0
		actor.velocity.z = 0
		actor.velocity.y -= GRAVITY*delta
		actor.move_and_slide()
		animate_enemy(enemy,delta)
		return
	if int(enemy.kind) == 4 and moves.stage == "commit" and not moves.target.is_empty() and moves.target.body == actor and moves.projection.phase_elapsed >= float(tuning.dummy_dodge_delay):
		start_enemy_dash(enemy,moves.direction.cross(Vector3.UP))
	if float(enemy.get("dash_time",0)) > 0:
		enemy.dash_time = maxf(0.0,float(enemy.dash_time)-delta)
		var dash: Vector3 = enemy.dash_dir
		actor.velocity.x = dash.x*DASH_SPEED
		actor.velocity.z = dash.z*DASH_SPEED
		actor.velocity.y -= GRAVITY*delta
		actor.move_and_slide()
		if enemy.rig_anim != null: play_enemy_rig_animation(enemy,enemy_dash_animation(enemy),0.05,3.8)
		return

	# Un enemigo ya comprometido con un ataque completa wind-up, impacto y recuperación.
	if str(enemy.attack_phase) != "idle":
		actor.velocity.x = 0.0
		actor.velocity.z = 0.0
		if offset.length() > 0.01:
			actor.rotation.y = atan2(-offset.x,-offset.z)

		if enemy.attack_timer <= 0:
			match str(enemy.attack_phase):
				"windup":
					# El golpe solo conecta al terminar la preparación y si el objetivo sigue cerca.
					if offset.length() <= 2.35:
						hit_player_from_enemy(enemy, offset)
					enemy.attack_phase = "strike"
					enemy.attack_timer = 0.12 if int(enemy.combo) == 4 else 0.10
				"strike":
					enemy.attack_phase = "recovery"
					enemy.attack_timer = 0.34 if int(enemy.combo) == 4 else 0.24
				"recovery":
					enemy.attack_phase = "idle"
					enemy.attack_timer = 0.0
					enemy.cd = 0.28 if int(enemy.combo) == 4 else 0.20

		actor.velocity.y -= GRAVITY*delta
		actor.move_and_slide()
		animate_enemy(enemy, delta)
		return

	if enemy.stun <= 0:
		actor.velocity.x = 0
		actor.velocity.z = 0
		if enemy.kind != 0 and offset.length() > 0.01:
			actor.rotation.y = atan2(-offset.x,-offset.z)
		if enemy.kind in [2,3] and offset.length() < 16:
			# No inicia otro ataque mientras el jugador está caído, aturdido o protegido al levantarse.
			var player_vulnerable := not player_ragdoll and stun <= 0 and player_wakeup_protection <= 0
			if offset.length() > 1.9 and enemy.kind == 2:
				actor.velocity.x = offset.normalized().x*3.5
				actor.velocity.z = offset.normalized().z*3.5
			elif offset.length() <= 1.9 and enemy.cd <= 0 and player_vulnerable:
				start_enemy_attack(enemy)
	else:
		actor.velocity.x = move_toward(actor.velocity.x,0.0,delta*18.0)
		actor.velocity.z = move_toward(actor.velocity.z,0.0,delta*18.0)

	actor.velocity.y -= GRAVITY*delta
	actor.move_and_slide()
	animate_enemy(enemy, delta)

	if actor.position.y < -12:
		reset_enemy(enemy)

func update_enemy_ragdoll_physics(enemy: Dictionary, delta: float) -> void:
	var actor: CharacterBody3D = enemy.body
	if is_instance_valid(enemy.get("physics")):
		enemy.physics.start(actor.velocity,enemy.get("ragdoll_impact",{}))
		enemy.physics.follow_actor()
		var was_grounded: bool = enemy.ragdoll_grounded
		enemy.ragdoll_grounded = enemy.physics.grounded()
		if enemy.ragdoll_grounded and not was_grounded: feedback.sound("landing",actor.global_position,-9)
		return
	if enemy.slam_pending:
		actor.velocity.x = 0
		actor.velocity.z = 0
	if actor.is_on_floor() and actor.velocity.y <= 0:
		enemy.ragdoll_grounded = true
		actor.velocity.x = move_toward(actor.velocity.x,0.0,delta*18.0)
		actor.velocity.z = move_toward(actor.velocity.z,0.0,delta*18.0)
	actor.velocity.y -= GRAVITY*delta
	actor.move_and_slide()
	if actor.is_on_floor() and enemy.slam_pending:
		# El downslam no debe arrastrar al enemigo por el piso.
		actor.velocity.x = 0
		actor.velocity.z = 0
		enemy.ragdoll_grounded = true

func reset_pose(visual: Node3D, left_arm: Node3D, right_arm: Node3D, left_elbow: Node3D, right_elbow: Node3D, left_leg: Node3D, right_leg: Node3D) -> void:
	# Reset inmediato reservado para respawns/debug. Las animaciones normales usan interpolación.
	visual.rotation.x = 0.0
	visual.rotation.z = 0.0
	left_arm.rotation = Vector3.ZERO
	right_arm.rotation = Vector3.ZERO
	left_elbow.rotation = Vector3(0.12,0,0)
	right_elbow.rotation = Vector3(0.12,0,0)
	left_leg.rotation = Vector3.ZERO
	right_leg.rotation = Vector3.ZERO

func smooth_guard_pose(left_arm: Node3D, right_arm: Node3D, left_elbow: Node3D, right_elbow: Node3D, delta: float, speed: float = 18.0) -> void:
	# Guardia cerrada: antebrazos delante de pecho/cara y transición progresiva.
	smooth_rotation(left_arm, Vector3(1.00,-0.08,0.34), delta, speed)
	smooth_rotation(right_arm, Vector3(1.00,0.08,-0.34), delta, speed)
	smooth_rotation(left_elbow, Vector3(1.95,0.0,-0.08), delta, speed)
	smooth_rotation(right_elbow, Vector3(1.95,0.0,0.08), delta, speed)

func smooth_enemy_neutral(visual: Node3D, left_arm: Node3D, right_arm: Node3D, left_elbow: Node3D, right_elbow: Node3D, left_leg: Node3D, right_leg: Node3D, delta: float, speed: float = 12.0) -> void:
	smooth_model_tilt(visual, 0.0, 0.0, delta, speed)
	smooth_rotation(left_arm, Vector3.ZERO, delta, speed)
	smooth_rotation(right_arm, Vector3.ZERO, delta, speed)
	smooth_rotation(left_elbow, Vector3(0.12,0,0), delta, speed)
	smooth_rotation(right_elbow, Vector3(0.12,0,0), delta, speed)
	smooth_rotation(left_leg, Vector3.ZERO, delta, speed)
	smooth_rotation(right_leg, Vector3.ZERO, delta, speed)

func apply_ragdoll_pose(visual: Node3D, left_arm: Node3D, right_arm: Node3D, left_elbow: Node3D, right_elbow: Node3D, left_leg: Node3D, right_leg: Node3D, grounded: bool, phase: float) -> void:
	if grounded:
		visual.rotation.z = 1.48
		visual.rotation.x = 0.08*sin(phase*4.0)
		left_arm.rotation = Vector3(-0.9,0.2,-1.0)
		right_arm.rotation = Vector3(0.35,-0.25,1.2)
		left_elbow.rotation = Vector3(0.75,0.2,0.2)
		right_elbow.rotation = Vector3(1.25,-0.2,-0.2)
		left_leg.rotation = Vector3(0.85,0,-0.25)
		right_leg.rotation = Vector3(-0.42,0,0.32)
	else:
		visual.rotation.z = sin(phase*8.0)*0.55
		visual.rotation.x = cos(phase*7.0)*0.28
		left_arm.rotation = Vector3(-0.8,0.3,-0.9)
		right_arm.rotation = Vector3(0.6,-0.3,0.95)
		left_elbow.rotation = Vector3(1.0,0,0.4)
		right_elbow.rotation = Vector3(0.5,0,-0.4)
		left_leg.rotation = Vector3(0.75,0,-0.2)
		right_leg.rotation = Vector3(-0.75,0,0.2)

func animate_player(dir: Vector3, delta: float) -> void:
	if player_ragdoll:
		apply_ragdoll_pose(model, arm_left, arm_right, elbow_left, elbow_right, leg_left, leg_right, player.is_on_floor(), clock)
		return

	# La base ya no se resetea cada frame. Se interpola desde la pose anterior.
	var neutral_speed: float = 7.0 if wakeup_anim > 0.0 else 13.0
	smooth_player_neutral(delta, neutral_speed)

	if wakeup_anim > 0.0:
		# Al salir de ragdoll el cuerpo recupera postura gradualmente antes de volver a animaciones normales.
		var wake_ratio: float = clampf(wakeup_anim/0.34, 0.0, 1.0)
		smooth_model_tilt(model, 0.12*wake_ratio, 0.30*wake_ratio, delta, 8.0)
		smooth_rotation(leg_left, Vector3(0.42*wake_ratio,0,-0.10), delta, 8.0)
		smooth_rotation(leg_right, Vector3(-0.18*wake_ratio,0,0.12), delta, 8.0)
		return

	if skill_active != "":
		animate_player_skill(delta)
		return

	if block_recoil_time > 0:
		var recoil_ratio: float = clampf(block_recoil_time / BLOCKSTUN_DURATION, 0.0, 1.0)
		smooth_guard_pose(arm_left, arm_right, elbow_left, elbow_right, delta, 24.0)
		smooth_model_tilt(model, 0.22*recoil_ratio, 0.0, delta, 24.0)
		smooth_rotation(arm_left, Vector3(1.00,-0.08,0.34-0.12*recoil_ratio), delta, 24.0)
		smooth_rotation(arm_right, Vector3(1.00,0.08,-0.34+0.12*recoil_ratio), delta, 24.0)
		return

	if block:
		smooth_guard_pose(arm_left, arm_right, elbow_left, elbow_right, delta, 20.0)
		smooth_model_tilt(model, -0.06, 0.0, delta, 18.0)
		return

	if dash_pose_blend > 0.01:
		var local_dash: Vector3 = dash_dir.rotated(Vector3.UP,-model.rotation.y)
		var dash_ease: float = dash_pose_blend*dash_pose_blend*(3.0-2.0*dash_pose_blend)
		smooth_model_tilt(model, local_dash.z*0.52*dash_ease, -local_dash.x*0.38*dash_ease, delta, 25.0)
		smooth_rotation(arm_left, Vector3(-0.70,0,-0.10), delta, 24.0)
		smooth_rotation(arm_right, Vector3(-0.70,0,0.10), delta, 24.0)
		smooth_rotation(elbow_left, Vector3(0.90,0,0), delta, 24.0)
		smooth_rotation(elbow_right, Vector3(0.90,0,0), delta, 24.0)
		smooth_rotation(leg_left, Vector3(0.82,0,-0.08), delta, 24.0)
		smooth_rotation(leg_right, Vector3(-0.68,0,0.08), delta, 24.0)
		if dash_time > 0:
			return

	if attack_anim > 0:
		animate_player_attack(delta)
		return

	if not player.is_on_floor():
		if player.velocity.y > 0.5:
			smooth_model_tilt(model, -0.13, 0.0, delta, 15.0)
			smooth_rotation(arm_left, Vector3(-0.44,0,-0.20), delta, 15.0)
			smooth_rotation(arm_right, Vector3(-0.38,0,0.20), delta, 15.0)
			smooth_rotation(elbow_left, Vector3(0.58,0,0), delta, 15.0)
			smooth_rotation(elbow_right, Vector3(0.52,0,0), delta, 15.0)
			smooth_rotation(leg_left, Vector3(0.64,0,-0.08), delta, 15.0)
			smooth_rotation(leg_right, Vector3(-0.30,0,0.08), delta, 15.0)
		else:
			smooth_model_tilt(model, 0.11, 0.0, delta, 14.0)
			smooth_rotation(arm_left, Vector3(0.34,0,-0.32), delta, 14.0)
			smooth_rotation(arm_right, Vector3(0.34,0,0.32), delta, 14.0)
			smooth_rotation(elbow_left, Vector3(0.36,0,0), delta, 14.0)
			smooth_rotation(elbow_right, Vector3(0.36,0,0), delta, 14.0)
			smooth_rotation(leg_left, Vector3(-0.22,0,-0.05), delta, 14.0)
			smooth_rotation(leg_right, Vector3(0.44,0,0.05), delta, 14.0)
		return

	if landing_anim > 0.0:
		var landing_ratio: float = clampf(landing_anim/0.18,0.0,1.0)
		var compression: float = sin(landing_ratio*PI)*0.32
		smooth_model_tilt(model, 0.14*landing_ratio, 0.0, delta, 22.0)
		smooth_rotation(leg_left, Vector3(compression,0,-0.05), delta, 22.0)
		smooth_rotation(leg_right, Vector3(compression,0,0.05), delta, 22.0)
		smooth_rotation(arm_left, Vector3(-0.18*landing_ratio,0,-0.08), delta, 18.0)
		smooth_rotation(arm_right, Vector3(-0.18*landing_ratio,0,0.08), delta, 18.0)
		return

	var stride: float = sin(clock*12.5)*0.58*dir.length()
	if dir.length() > 0.05:
		smooth_rotation(arm_left, Vector3(-stride*0.62,0,-0.03), delta, 16.0)
		smooth_rotation(arm_right, Vector3(stride*0.62,0,0.03), delta, 16.0)
		smooth_rotation(leg_left, Vector3(stride,0,-0.02), delta, 16.0)
		smooth_rotation(leg_right, Vector3(-stride,0,0.02), delta, 16.0)
		smooth_model_tilt(model, -0.035, -0.025*(1.0 if stride >= 0.0 else -1.0), delta, 14.0)

func animate_player_attack(delta: float) -> void:
	var total: float = 0.28 if combo == 4 else 0.24
	var progress: float = clampf(1.0-attack_anim/total,0.0,1.0)
	var striking_arm: Node3D = arm_left if combo%2 == 0 else arm_right
	var striking_elbow: Node3D = elbow_left if combo%2 == 0 else elbow_right
	var other_arm: Node3D = arm_right if combo%2 == 0 else arm_left
	var other_elbow: Node3D = elbow_right if combo%2 == 0 else elbow_left
	var side: float = 1.0 if combo%2 == 0 else -1.0

	# Tres fases: anticipación corta, impacto rápido y recuperación legible.
	var prep: float = 0.0
	var strike: float = 0.0
	var recover: float = 0.0
	if progress < 0.30:
		prep = smoothstep(0.0,1.0,progress/0.30)
	elif progress < 0.60:
		strike = smoothstep(0.0,1.0,(progress-0.30)/0.30)
		prep = 1.0-strike
	else:
		recover = smoothstep(0.0,1.0,(progress-0.60)/0.40)

	if combo == 4 and attack_variant == "uppercut":
		var lift: float = strike if progress < 0.60 else 1.0-recover
		var crouch: float = prep if progress < 0.30 else 1.0-strike
		smooth_model_tilt(model, 0.18*lift+0.10*crouch, side*0.12*lift, delta, 32.0)
		smooth_rotation(striking_arm, Vector3(lerpf(-0.35,2.38,lift),0,-0.10*side), delta, 34.0)
		smooth_rotation(striking_elbow, Vector3(lerpf(1.48,0.20,lift),0,0), delta, 34.0)
		smooth_rotation(other_arm, Vector3(0.82,0,0.20*side), delta, 24.0)
		smooth_rotation(other_elbow, Vector3(1.42,0,0), delta, 24.0)
		smooth_rotation(leg_left, Vector3(0.34*crouch,0,-0.08), delta, 24.0)
		smooth_rotation(leg_right, Vector3(-0.30*lift,0,0.08), delta, 24.0)
		return

	if combo == 4 and attack_variant == "downslam":
		var slam_amount: float = strike if progress < 0.60 else 1.0-recover
		var raise_amount: float = prep if progress < 0.30 else 1.0-strike
		smooth_model_tilt(model, -0.50*slam_amount+0.12*raise_amount, 0.0, delta, 34.0)
		smooth_rotation(arm_left, Vector3(lerpf(-0.55,1.78,slam_amount),0,-0.14), delta, 34.0)
		smooth_rotation(arm_right, Vector3(lerpf(-0.55,1.78,slam_amount),0,0.14), delta, 34.0)
		smooth_rotation(elbow_left, Vector3(lerpf(0.62,0.08,slam_amount),0,0), delta, 34.0)
		smooth_rotation(elbow_right, Vector3(lerpf(0.62,0.08,slam_amount),0,0), delta, 34.0)
		smooth_rotation(leg_left, Vector3(-0.20,0,-0.06), delta, 22.0)
		smooth_rotation(leg_right, Vector3(0.42,0,0.06), delta, 22.0)
		return

	var extension: float = strike if progress < 0.60 else 1.0-recover
	var chamber: float = prep if progress < 0.30 else 1.0-strike
	smooth_rotation(striking_arm, Vector3(lerpf(-0.48,1.62,extension),0,-0.08*side), delta, 34.0)
	smooth_rotation(striking_elbow, Vector3(lerpf(1.52,0.08,extension),0,0), delta, 34.0)
	smooth_rotation(other_arm, Vector3(0.68,0,0.18*side), delta, 25.0)
	smooth_rotation(other_elbow, Vector3(1.34,0,0), delta, 25.0)
	var power: float = 1.0 if combo == 4 else 0.55
	smooth_model_tilt(model, -0.10*extension*power, side*(0.10*extension+0.08*chamber), delta, 30.0)
	if combo == 4:
		smooth_rotation(leg_left, Vector3(0.20*extension,0,-0.06), delta, 22.0)
		smooth_rotation(leg_right, Vector3(-0.22*extension,0,0.06), delta, 22.0)

func animate_player_skill(delta: float) -> void:
	if skill_active == "skill3":
		match skill_phase:
			"windup":
				var prep: float = clampf(1.0-skill_timer/0.12,0.0,1.0)
				smooth_model_tilt(model, 0.04, -0.16*prep, delta, 28.0)
				smooth_rotation(arm_right, Vector3(lerpf(0.50,-0.85,prep),0,0.18), delta, 30.0)
				smooth_rotation(elbow_right, Vector3(1.55,0,0), delta, 30.0)
				smooth_rotation(arm_left, Vector3(0.92,0,-0.24), delta, 24.0)
				smooth_rotation(elbow_left, Vector3(1.52,0,0), delta, 24.0)
				smooth_rotation(leg_left, Vector3(0.20,0,-0.06), delta, 22.0)
				smooth_rotation(leg_right, Vector3(-0.18,0,0.06), delta, 22.0)
			"rush":
				var rush_progress: float = clampf(1.0-skill_timer/0.18,0.0,1.0)
				var punch_out: float = smoothstep(0.0,1.0,clampf((rush_progress-0.52)/0.48,0.0,1.0))
				smooth_model_tilt(model, -0.36+0.18*punch_out, -0.10-0.08*punch_out, delta, 34.0)
				smooth_rotation(arm_right, Vector3(lerpf(-0.62,1.62,punch_out),0,lerpf(0.14,0.04,punch_out)), delta, 38.0)
				smooth_rotation(elbow_right, Vector3(lerpf(1.38,0.08,punch_out),0,0), delta, 38.0)
				smooth_rotation(arm_left, Vector3(-0.48,0,-0.14), delta, 30.0)
				smooth_rotation(elbow_left, Vector3(0.92,0,0), delta, 30.0)
				smooth_rotation(leg_left, Vector3(0.72,0,-0.08), delta, 30.0)
				smooth_rotation(leg_right, Vector3(-0.62,0,0.08), delta, 30.0)
			"recovery":
				var recovery_total: float = SKILL3_HIT_RECOVERY if skill_connected else SKILL3_MISS_RECOVERY
				var remain: float = clampf(skill_timer/recovery_total,0.0,1.0)
				# El derechazo termina extendido; al fallar tarda más en recuperar la guardia.
				smooth_model_tilt(model, -0.14*remain, -0.12*remain, delta, 24.0)
				smooth_rotation(arm_right, Vector3(1.62*remain,0,0.06), delta, 28.0)
				smooth_rotation(elbow_right, Vector3(lerpf(0.12,1.10,1.0-remain),0,0), delta, 26.0)
				smooth_rotation(arm_left, Vector3(0.78*remain,0,-0.18), delta, 22.0)
		return

	if skill_active == "skill4":
		match skill_phase:
			"windup":
				var prep: float = clampf(1.0-skill_timer/0.17,0.0,1.0)
				# Cámara corporal: cadera carga hacia un lado y la pierna derecha se recoge.
				smooth_model_tilt(model, 0.06, -0.24*prep, delta, 28.0)
				smooth_rotation(leg_right, Vector3(-0.62*prep,0,0.34*prep), delta, 30.0)
				smooth_rotation(leg_left, Vector3(0.22*prep,0,-0.12), delta, 24.0)
				smooth_rotation(arm_left, Vector3(0.88,0,-0.28), delta, 24.0)
				smooth_rotation(arm_right, Vector3(0.48,0,0.36), delta, 24.0)
				smooth_rotation(elbow_left, Vector3(1.48,0,0), delta, 24.0)
				smooth_rotation(elbow_right, Vector3(1.28,0,0), delta, 24.0)
			"strike":
				var kick: float = clampf(1.0-skill_timer/0.12,0.0,1.0)
				smooth_model_tilt(model, -0.10, 0.34, delta, 38.0)
				smooth_rotation(leg_right, Vector3(lerpf(-0.55,1.58,kick),0,lerpf(0.34,-0.18,kick)), delta, 40.0)
				smooth_rotation(leg_left, Vector3(0.28,0,-0.14), delta, 32.0)
				smooth_rotation(arm_left, Vector3(-0.18,0,-0.46), delta, 30.0)
				smooth_rotation(arm_right, Vector3(0.22,0,0.52), delta, 30.0)
			"recovery":
				var remain: float = clampf(skill_timer/SKILL4_RECOVERY,0.0,1.0)
				smooth_model_tilt(model, -0.05*remain, 0.18*remain, delta, 22.0)
				smooth_rotation(leg_right, Vector3(0.72*remain,0,-0.10*remain), delta, 24.0)
				smooth_rotation(leg_left, Vector3(0.12*remain,0,-0.06), delta, 22.0)

func animate_enemy(enemy: Dictionary, delta: float) -> void:
	var actor: CharacterBody3D = enemy.body
	var visual: Node3D = enemy.visual
	if bool(enemy.get("rig_enabled", false)):
		update_enemy_rig_animation(enemy)
		return
	var left_arm: Node3D = enemy.arm_left
	var right_arm: Node3D = enemy.arm_right
	var left_elbow: Node3D = enemy.elbow_left
	var right_elbow: Node3D = enemy.elbow_right
	var left_leg: Node3D = enemy.leg_left
	var right_leg: Node3D = enemy.leg_right

	if bool(enemy.ragdoll):
		apply_ragdoll_pose(visual, left_arm, right_arm, left_elbow, right_elbow, left_leg, right_leg, bool(enemy.ragdoll_grounded) or actor.is_on_floor(), float(enemy.walk_clock))
		return

	smooth_enemy_neutral(visual, left_arm, right_arm, left_elbow, right_elbow, left_leg, right_leg, delta, 12.0)

	if int(enemy.kind) == 1:
		smooth_guard_pose(left_arm, right_arm, left_elbow, right_elbow, delta, 16.0)
		smooth_model_tilt(visual, -0.04, 0.0, delta, 14.0)
		return

	var horizontal_speed: float = Vector2(actor.velocity.x,actor.velocity.z).length()
	if horizontal_speed > 0.15:
		var stride: float = sin(float(enemy.walk_clock)*10.5)*0.62
		smooth_rotation(left_arm, Vector3(-stride*0.62,0,-0.02), delta, 15.0)
		smooth_rotation(right_arm, Vector3(stride*0.62,0,0.02), delta, 15.0)
		smooth_rotation(left_leg, Vector3(stride,0,-0.02), delta, 15.0)
		smooth_rotation(right_leg, Vector3(-stride,0,0.02), delta, 15.0)
		smooth_model_tilt(visual, -0.05, 0.0, delta, 14.0)

	if str(enemy.attack_phase) != "idle":
		var is_fourth: bool = int(enemy.combo) == 4
		var striking_arm: Node3D = left_arm if int(enemy.combo)%2 == 0 else right_arm
		var striking_elbow: Node3D = left_elbow if int(enemy.combo)%2 == 0 else right_elbow
		var other_arm: Node3D = right_arm if int(enemy.combo)%2 == 0 else left_arm
		var other_elbow: Node3D = right_elbow if int(enemy.combo)%2 == 0 else left_elbow
		var side: float = 1.0 if int(enemy.combo)%2 == 0 else -1.0
		smooth_rotation(other_arm, Vector3(0.66,0,0.15*side), delta, 20.0)
		smooth_rotation(other_elbow, Vector3(1.30,0,0), delta, 20.0)

		match str(enemy.attack_phase):
			"windup":
				var windup_total: float = 0.30 if is_fourth else 0.20
				var prep: float = clampf(1.0-float(enemy.attack_timer)/windup_total,0.0,1.0)
				smooth_rotation(striking_arm, Vector3(lerpf(0.45,-0.78 if not is_fourth else -1.02,prep),0,-0.08*side), delta, 25.0)
				smooth_rotation(striking_elbow, Vector3(lerpf(1.15,1.58,prep),0,0), delta, 25.0)
				smooth_model_tilt(visual, 0.11*prep if is_fourth else 0.05*prep, 0.18*side*prep, delta, 22.0)
			"strike":
				var strike_total: float = 0.12 if is_fourth else 0.10
				var extension: float = clampf(1.0-float(enemy.attack_timer)/strike_total,0.0,1.0)
				smooth_rotation(striking_arm, Vector3(lerpf(-0.50,1.66,extension),0,-0.05*side), delta, 36.0)
				smooth_rotation(striking_elbow, Vector3(lerpf(1.48,0.08,extension),0,0), delta, 36.0)
				smooth_model_tilt(visual, -0.13*extension, 0.13*side*extension, delta, 32.0)
			"recovery":
				var recovery_total: float = 0.34 if is_fourth else 0.24
				var remain: float = clampf(float(enemy.attack_timer)/recovery_total,0.0,1.0)
				smooth_rotation(striking_arm, Vector3(1.08*remain,0,-0.04*side), delta, 18.0)
				smooth_rotation(striking_elbow, Vector3(0.75+0.35*(1.0-remain),0,0), delta, 18.0)
				smooth_model_tilt(visual, -0.05*remain, 0.05*side*remain, delta, 16.0)


func enemy_dash_animation(enemy: Dictionary) -> String:
	var direction: Vector3 = enemy.dash_dir.rotated(Vector3.UP,-enemy.body.rotation.y)
	if direction.z > .45: return "UnarmedDodgeBackward"
	if direction.x < -.45: return "UnarmedDodgeLeft"
	return "UnarmedDodgeRight" if direction.x > .45 else "UnarmedRunForward"

func input_pressed(action: String) -> bool:
	return Input.is_action_pressed(action)

func online_session() -> Node:
	return null

extends Node3D
# Puente visual reutilizado del controlador individual 0.9.10. Conserva rigs,
# bibliotecas, mezcla y física originales, sin cargar dominio/NPC/HUD por jugador.
const PLAYER_RIG_SCENE_PATH := "res://assets/characters/alien/Alien_Naoya_Rig_Combat.glb"
const RIG_SCALE_ADJUST := .76
const RIG_YAW_OFFSET := 0.0
const RIG_BLEND_DEFAULT := .10
const SPEED := 7.5
const GRAVITY := 24.0
const JUMP_FORCE := 9.0
const DASH_SPEED := 24.0
const DASH_DURATION := .18
const DASH_COOLDOWN := 1.2
const ATTACK_TIME := .32
const FINISHER_TIME := .38
const NORMAL_STUN := .35
const FOURTH_HIT_STUN := 1.8
const BLOCKSTUN_DURATION := .22
var tuning: Resource = preload("res://balance_v091.tres")
var robots: Node = preload("res://scripts/robot_character.gd").new()
var visual_motion: Node = preload("res://scripts/visual_motion.gd").new()
var player: CharacterBody3D
var model: Node3D
var arm_left: Node3D
var arm_right: Node3D
var elbow_left: Node3D
var elbow_right: Node3D
var leg_left: Node3D
var leg_right: Node3D
var rig_holder: Node3D
var rig_scene: Node3D
var rig_anim: AnimationPlayer
var rig_enabled := false
var rig_current_anim: StringName = &""
var rig_anim_names: Dictionary = {}
var locomotion_tree: AnimationTree
var physical_ragdoll: Node
var locomotion_vector := Vector2.ZERO
var material_cache: Dictionary = {}
var hp := 100.0
var stun := 0.0
var block := false
var paused := false
var clock := 0.0
var attack_cd := 0.0
var attack_anim := 0.0
var attack_variant := "normal"
var attack_hit_done := false
var combo := 0
var combo_timeout := 0.0
var dash_time := 0.0
var dash_cd := 0.0
var dash_dir := Vector3.ZERO
var player_ragdoll := false
var player_ragdoll_time := 0.0
var block_recoil_time := 0.0
var landing_anim := 0.0
var descending_time := 0.0
var punch_visual := "combat/Hook"
var impact_freeze := 0.0
func form_speed_mult() -> float: return 1.0


func get_box_material(color: Color) -> StandardMaterial3D:
	var key := color.to_html(true)
	if material_cache.has(key):
		return material_cache[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material_cache[key] = material
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
	physical_ragdoll.setup(player,rig_holder,visual_motion.find_skeleton(rig_scene),rig_anim,locomotion_tree)

func setup_locomotion_tree() -> void:
	add_child(visual_motion)
	visual_motion.setup(self)

func sync_rig_transform() -> void:
	if robots.active: robots.sync_transform(); return
	if not rig_enabled or rig_holder == null:
		return
	if is_instance_valid(physical_ragdoll) and physical_ragdoll.active: return
	# Solo heredamos yaw. El Skeleton ya aporta inclinación corporal dentro de cada clip.
	rig_holder.rotation = Vector3(0.0, model.rotation.y + RIG_YAW_OFFSET, 0.0)

func facing_forward() -> Vector3:
	var forward := -model.global_basis.z
	forward.y = 0
	if forward.length() < 0.001:
		return Vector3.FORWARD
	return forward.normalized()

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

func select_fourth_variant() -> String:
	# El cuarto M1 depende únicamente del estado aéreo; Espacio ya no activa el golpe.
	# Cerca del ápice (< 1.0) ya cuenta como caída para que el downslam sea consistente.
	if not player.is_on_floor():
		if player.velocity.y < 1.0:
			return "downslam"
		return "uppercut"
	return "normal"

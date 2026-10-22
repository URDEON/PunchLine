extends Node
## AnimationTree: blended locomotion plus filtered upper-body actions on the same rig.
const Library = preload("res://assets/animation_sources/shooter/shooter_library.res")
var player: AnimationPlayer
var tree: AnimationTree
var playback: AnimationNodeStateMachinePlayback
var machine: AnimationNodeStateMachine
var action_clip: AnimationNodeAnimation
var action_node: AnimationNodeOneShot
var current := "idle"
var last_action := ""
var back_time := 0.0

func setup(visual: Node3D) -> void:
	player = AnimationPlayer.new()
	player.name = "AnimationPlayer"
	visual.add_child(player)
	player.add_animation_library("shooter",Library)
	machine = AnimationNodeStateMachine.new()
	var states := ["idle","walk","run","back","run_back","left","right","jump","step_back"]
	for label in states:
		var node := AnimationNodeAnimation.new()
		node.animation = "shooter/"+label
		machine.add_node(label,node)
	for from in states:
		for to in states:
			if from==to: continue
			var transition := AnimationNodeStateMachineTransition.new()
			transition.xfade_time = 0.12
			machine.add_transition(from,to,transition)
	var graph := AnimationNodeBlendTree.new()
	graph.add_node("locomotion",machine)
	graph.add_node("rate",AnimationNodeTimeScale.new())
	action_clip = AnimationNodeAnimation.new()
	action_clip.animation = "shooter/fire"
	graph.add_node("clip",action_clip)
	graph.add_node("action_rate",AnimationNodeTimeScale.new())
	action_node = AnimationNodeOneShot.new()
	action_node.fadein_time = 0.07
	action_node.fadeout_time = 0.13
	action_node.filter_enabled = true
	for bone in visual.bones.keys():
		var name: String = visual.skeleton.get_bone_name(visual.bones[bone])
		if "Spine" in name or "Arm" in name or "Shoulder" in name or "Hand" in name or "Neck" in name or "Head" in name:
			action_node.set_filter_path(NodePath("Rig/Skeleton3D:"+name),true)
	graph.add_node("action",action_node)
	graph.connect_node("rate",0,"locomotion")
	graph.connect_node("action_rate",0,"clip")
	graph.connect_node("action",0,"rate")
	graph.connect_node("action",1,"action_rate")
	graph.connect_node("output",0,"action")
	tree = AnimationTree.new()
	tree.name = "ShooterAnimationTree"
	visual.add_child(tree)
	tree.anim_player = tree.get_path_to(player)
	tree.tree_root = graph
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	tree.active = true
	playback = tree.get("parameters/locomotion/playback")
	playback.start("idle")
	refresh_style()
	WarfareSettings.changed.connect(refresh_style)

func clip_for(label: String) -> String:
	return "slim_"+label if int(WarfareSettings.values.animation_style)==1 and Library.has_animation("slim_"+label) else label

func refresh_style() -> void:
	for label in ["idle","walk","run","back","run_back","left","right","jump","step_back"]:
		var node: AnimationNodeAnimation = machine.get_node(label)
		node.animation = "shooter/"+clip_for(label)

func tick(body: CharacterBody3D,command: RefCounted) -> void:
	var speed: float = body.movement.locomotion_speed
	back_time = back_time+body.get_physics_process_delta_time() if command.move.y>0.1 else 0.0
	var desired := "idle"
	if not body.is_on_floor(): desired = "jump"
	elif speed>0.15:
		if absf(command.move.x)>absf(command.move.y): desired = "left" if command.move.x<0 else "right"
		elif command.move.y>0: desired = "step_back" if back_time<0.36 else ("run_back" if speed>3 else "back")
		else: desired = "run" if speed>3 else "walk"
	if desired!=current:
		current = desired
		playback.travel(current)
	var nominal := 4.6 if current in ["run","run_back"] else 2.1
	tree.set("parameters/rate/scale",clampf(speed/nominal,0.5,1.6) if current not in ["idle","jump"] else 1.0)

func play_action(label: String,duration: float = 0.0) -> void:
	if not Library.has_animation(label): return
	last_action = label
	var selected := clip_for(label)
	action_clip.animation = "shooter/"+selected
	tree.set("parameters/action_rate/scale",Library.get_animation(selected).length/duration if duration>0 else 1.0)
	tree.set("parameters/action/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func preview_idle() -> void:
	playback.start("idle")

func preview_clip(label: String) -> void:
	if not Library.has_animation(label): return
	tree.active = false
	player.play("shooter/"+clip_for(label),0.12)

extends Node
# Pose base Idle; zancadas y dash procedurales en robot_procedural_motion.gd.
var tree: AnimationTree
var blend := 0.0
var rate := 1.0
var game: Node3D
var rig: Dictionary

func setup(host: Node3D, data: Dictionary, tall: bool) -> void:
	game = host; rig = data
	var player: AnimationPlayer = rig.rig_anim
	var space := AnimationNodeBlendSpace1D.new()
	space.min_space = 0; space.max_space = 1; space.blend_mode = AnimationNodeBlendSpace1D.BLEND_MODE_INTERPOLATED
	var walk := "walk_tall" if tall else "walk"
	var run := "run_tall" if tall else "run"
	for pair in [["idle",0.0],[walk,.40],[run,1.0]]:
		var animation := AnimationNodeAnimation.new(); animation.animation = rig.rig_anim_names[pair[0]]
		space.add_blend_point(animation,pair[1])
	var graph := AnimationNodeBlendTree.new(); graph.add_node("movement",space)
	graph.add_node("rate",AnimationNodeTimeScale.new()); graph.connect_node("rate",0,"movement"); graph.connect_node("output",0,"rate")
	tree = AnimationTree.new(); rig.rig_holder.add_child(tree)
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	tree.tree_root = graph; tree.anim_player = tree.get_path_to(player); tree.active = false

func stop() -> void: tree.active = false

func tick(speed: float, delta: float) -> void:
	var target := clampf(speed/6.0,0,1)
	if game.input_pressed("walk") and speed > .1: target = .40
	blend = lerpf(blend,target,1-exp(-delta*11))
	var cadence := 1.0 if speed < .1 else clampf(speed/(2.4 if target <= .4 else 5.5),.80,1.55)
	rate = lerpf(rate,cadence,1-exp(-delta*8))
	tree.set("parameters/movement/blend_position",blend); tree.set("parameters/rate/scale",rate)
	if not tree.active:
		rig.rig_anim.stop(); tree.active = true
	rig.rig_anim.active = true

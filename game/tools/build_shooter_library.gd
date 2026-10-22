extends SceneTree
## Reproducible conversion of user-supplied FBX clips, with horizontal root motion removed.
const ROOT := "res://assets/animation_sources/shooter/"
const ROLES := {"rifle_aiming_idle":"idle","walking":"walk","rifle_run":"run",
	"walking_backwards":"back","run_backwards":"run_back","strafe_left":"left",
	"strafe_right":"right","reloading":"reload","firing_rifle":"fire","rifle_jump":"jump",
	"turn_left":"turn_left","turning_right_45_degrees":"turn_right","hit_reaction":"hit",
	"toss_grenade":"grenade","stepping_backward":"step_back","strafe":"strafe","strafe_2":"strafe_2"}
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var library := AnimationLibrary.new()
	var manifest: Dictionary = {}
	for folder in ["fbx","fbx/slim"]:
		for file in DirAccess.get_files_at(ROOT+folder):
			if not file.ends_with(".fbx") or file=="x_bot.fbx": continue
			var source: Node = load(ROOT+folder+"/"+file).instantiate()
			var players := source.find_children("*","AnimationPlayer",true,false)
			if players.is_empty(): push_error("Missing animation: "+file); quit(1); return
			var player: AnimationPlayer = players[0]
			var animation: Animation = player.get_animation(player.get_animation_list()[0]).duplicate(true)
			var label: String = ROLES.get(file.get_basename(),file.get_basename())
			if folder.ends_with("slim"): label = "slim_"+label
			for track in range(animation.get_track_count()):
				var path := String(animation.track_get_path(track))
				animation.track_set_path(track,NodePath("Rig/"+path))
				if animation.track_get_type(track)==Animation.TYPE_POSITION_3D and path.ends_with(":mixamorig_Hips"):
					for key in range(animation.track_get_key_count(track)):
						var position: Vector3 = animation.track_get_key_value(track,key)
						position.x = 0
						position.z = 0
						animation.track_set_key_value(track,key,position)
			animation.loop_mode = Animation.LOOP_LINEAR if label.trim_prefix("slim_") in ["idle","walk","run","back","run_back","left","right","strafe","strafe_2"] else Animation.LOOP_NONE
			library.add_animation(label,animation)
			manifest[label] = {"source":folder+"/"+file,"duration":animation.length,"tracks":animation.get_track_count()}
			source.free()
	var error := ResourceSaver.save(library,ROOT+"shooter_library.res",ResourceSaver.FLAG_COMPRESS)
	if error!=OK: push_error(error_string(error)); quit(1); return
	var report := FileAccess.open(ROOT+"clips.json",FileAccess.WRITE)
	report.store_string(JSON.stringify(manifest,"\t"))
	print("SHOOTER_LIBRARY ",library.get_animation_list().size()," clips")
	quit()

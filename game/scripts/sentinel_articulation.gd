extends "res://scripts/mecha_articulation.gd"
## Articulación rígida local. Reutiliza las piezas y la transformación V8;
## Junkyard no tiene skin ni huesos y no se presenta como un modelo riggeado.
var cannon_transform: Node3D
var all_parts: Dictionary = {}
var groups: Dictionary = {}
var deployment := 0.0
var dead := false
var disabled_modules:Dictionary={}
var render_batches = preload("res://scripts/rigid_mesh_batch.gd").new()
var last_deployment := -1.0
var cannon_shoulder := Vector3.ZERO
var cannon_elbow := Vector3.ZERO
var confinement_state: Dictionary = {}
var confinement = preload("res://scripts/mecha_confinement.gd").new()

func setup(modules: Dictionary) -> void:
	all_parts = modules.duplicate()
	for id in modules:
		original_parents[id] = modules[id].get_parent(); original_transforms[id] = modules[id].transform
	name = "SentinelArticulation"
	var model: Node3D = modules.values()[0].get_parent()
	cannon_transform = preload("res://scripts/sentinel_cannon.gd").new(); add_child(cannon_transform)
	cannon_transform.adopt(model,get_parent())
	var specs := [
		["Pelvis","",Vector3(0,.49,-.025)],
		["Torso_Abdomen","Pelvis",Vector3(0,.57,-.025)],
		["Torso_Pecho","Torso_Abdomen",Vector3(0,.69,-.025)],
		["Cabeza","Torso_Pecho",Vector3(0,.88,-.025)],
		["Hombro_Der","Torso_Pecho",Vector3(.215,.755,.020)],
		["Hombro_Izq","Torso_Pecho",Vector3(-.215,.755,.020)],
		["BrazoSuperior_Der","Hombro_Der",Vector3(.215,.755,.020)],
		["BrazoSuperior_Izq","Hombro_Izq",Vector3(-.215,.755,.020)],
		["Antebrazo_Der","BrazoSuperior_Der",Vector3(.275,.595,.055)],
		["Antebrazo_Izq","BrazoSuperior_Izq",Vector3(-.275,.595,.055)],
		["Mano_Der","Antebrazo_Der",Vector3(.275,.49,.10)],
		["Mano_Izq","Antebrazo_Izq",Vector3(-.275,.49,.10)],
		["Muslo_Der","Pelvis",Vector3(.115,.49,-.025)],
		["Muslo_Izq","Pelvis",Vector3(-.115,.49,-.025)],
		["Rodilla_Der","Muslo_Der",Vector3(.13,.30,-.025)],
		["Rodilla_Izq","Muslo_Izq",Vector3(-.13,.30,-.025)],
		["Pantorrilla_Der","Rodilla_Der",Vector3(.13,.30,-.025)],
		["Pantorrilla_Izq","Rodilla_Izq",Vector3(-.13,.30,-.025)],
		["Pie_Der","Pantorrilla_Der",Vector3(.135,.07,.015)],
		["Pie_Izq","Pantorrilla_Izq",Vector3(-.135,.07,.015)]]
	for spec in specs:
		var node: Node3D
		if spec[0] == "BrazoSuperior_Der": node = cannon_transform.shoulder
		elif spec[0] == "Antebrazo_Der": node = cannon_transform.elbow
		else: node = Node3D.new(); model.add_child(node); node.position = spec[2]
		var parent: Node3D = self if spec[1] == "" else pivots[spec[1]]
		node.reparent(parent,true); pivots[spec[0]] = node; rest_positions[spec[0]] = node.position
		rig_data[spec[0]] = {"pivot":[spec[2].x,spec[2].y,spec[2].z],"parent":spec[1]}
		groups[spec[0]] = []
	for id in modules:
		var mesh: MeshInstance3D = modules[id]
		var c: Vector3 = model.to_local(mesh.global_transform*mesh.get_aabb().get_center())
		var side := "Der" if c.x > 0 else "Izq"
		var region := "Torso_Pecho"
		if absf(c.x) > .175 and c.y > .405:
			region = ("Hombro_" if c.y > .79 else ("BrazoSuperior_" if c.y > .68 else ("Antebrazo_" if c.y > .535 else "Mano_")))+side
		elif c.y < .53 and absf(c.x) > .04:
			region = ("Muslo_" if c.y > .395 else ("Pantorrilla_" if c.y > .14 else "Pie_"))+side
		elif c.y > .88: region = "Cabeza"
		elif c.y < .55: region = "Pelvis"
		elif c.y < .66: region = "Torso_Abdomen"
		# The V8 right-arm cap, trims, forearm and hand retain their original hinges.
		var native_arm: bool = cannon_transform.shoulder.is_ancestor_of(mesh)
		if not native_arm: mesh.reparent(pivots[region],true)
		groups[region].append(mesh)
		if not pieces.has(region): pieces[region] = mesh
	attached = true
	cannon_transform._pose(0)
	var render_sources: Array = all_parts.values()
	for part in cannon_transform.gun_parts:
		for child in part.node.get_children():
			if child is MeshInstance3D: render_sources.append(child)
	render_batches.build(render_sources)
	build_joint_caps()
	build_neck_seals()

func build_neck_seals() -> void:
	var material := StandardMaterial3D.new(); material.albedo_color = Color("263239"); material.metallic = .8; material.roughness = .5
	for target in ["Cabeza","Torso_Pecho"]:
		var cover := MeshInstance3D.new(); cover.name = "NeckClosure"
		var mesh := CylinderMesh.new(); mesh.top_radius = .075; mesh.bottom_radius = .075; mesh.height = .025; mesh.radial_segments = 16
		cover.mesh = mesh; cover.material_override = material; pivots[target].add_child(cover)
		cover.position = Vector3(0,-.022,0) if target == "Cabeza" else Vector3(0,.16,0)

func detach() -> void:
	render_batches.restore()
	for id in all_parts:
		all_parts[id].reparent(original_parents[id],true); all_parts[id].transform = original_transforms[id]
	attached = false

func neutral_pose() -> Dictionary:
	return angles() # Source is already in a natural lowered-arm pose.

func update_sleeves() -> void: pass # Separate bolted armour; no cut-mesh sleeves.

func attack_pose(pose: Dictionary) -> void:
	var id: String = action.id
	var time: float = action.get("time",0)
	var contact: float = maxf(.01,action.get("contact",.55))
	var total: float = maxf(contact+.01,action.get("duration",1.2))
	var prepare := smoothstep(0,contact*.4,time)*(1-smoothstep(contact*.45,contact*.8,time))
	var impact := smoothstep(contact*.45,contact*.85,time)*(1-smoothstep(contact+.15,total,time))
	if id in ["hammer","m1_hammer"]:
		for side in ["Der","Izq"]:
			if side != action.get("limb","Der") and id != "hammer": continue
			pose["BrazoSuperior_"+side].x = -2.2*prepare-1.2*impact
			pose["Antebrazo_"+side].x = -.3*prepare+.08*impact
		pose.Torso_Abdomen.x = -.10*prepare+.85*impact
		pose.Torso_Pecho.x = -.08*prepare+.35*impact
	elif id in ["seismic","m1_stomp"]:
		var lift := smoothstep(0,contact*.4,time)*(1-smoothstep(contact*.7,contact,time))
		var side:String=action.get("limb","Der")
		pose["Muslo_"+side].x = -.75*lift; pose["Rodilla_"+side].x = 1.2*lift; pose["Pie_"+side].x = -.45*lift
		pose.Torso_Abdomen.z = -.04*lift; pose.Torso_Pecho.x = .10*impact
	elif id == "ram":
		pose.Torso_Abdomen.x = .13; pose.Torso_Pecho.x = .08
		pose.BrazoSuperior_Der.x = -.7; pose.BrazoSuperior_Izq.x = -.7

func action_pose(pose: Dictionary) -> void:
	pose.Torso_Abdomen.x += .10*crouch_weight
	pose.Torso_Pecho.x -= .08*crouch_weight
	if boosting:
		pose.Torso_Abdomen.x = .10
		pose.Muslo_Der.x = -.20; pose.Muslo_Izq.x = -.20
		pose.Rodilla_Der.x = .4; pose.Rodilla_Izq.x = .4
	if not String(action.get("id","")).is_empty(): attack_pose(pose)
	if guarding:
		pose.BrazoSuperior_Der.x = -.65; pose.BrazoSuperior_Izq.x = -.65
		pose.Antebrazo_Der.x = -.45; pose.Antebrazo_Izq.x = -.45

func plant_impact_legs(pose: Dictionary, root_y: float, grounded: bool) -> float:
	if not grounded or action.get("id","") not in ["hammer","m1_hammer"]: return root_y
	var t: float = action.get("time",0); var hit: float = action.get("contact",.55); var end: float = action.get("duration",1.2)
	root_y -= .25*smoothstep(hit*.45,hit*.85,t)*(1-smoothstep(hit+.15,end,t))
	for side in ["Der","Izq"]: leg_ik(pose,side,.04,0,root_y)
	return root_y

func apply_pose(rotations: Dictionary, root_offset: Vector3, delta: float, immediate: bool = false) -> void:
	if dead: return
	confinement.adjust_pose(self,rotations)
	root_offset.y -= crouch_weight*(4.0-2.7)/maxf(global_basis.y.length(),.1)
	super.apply_pose(rotations,root_offset,delta,immediate)
	if gait.initialized and procedural_blend > 0:
		pivots.Pelvis.position = rest_positions.Pelvis+root_offset
	var wanted: float = action.get("deploy",0.0) if action.get("id","") == "cannon" else 0.0
	deployment = clampf(wanted,0,1)
	var shoulder_rotation: Vector3 = cannon_transform.shoulder.rotation
	var elbow_rotation: Vector3 = cannon_transform.elbow.rotation
	if not is_equal_approx(last_deployment,deployment):
		cannon_transform.shoulder.rotation = Vector3.ZERO; cannon_transform.elbow.rotation = Vector3.ZERO
		cannon_transform._pose(deployment)
		cannon_shoulder = cannon_transform.shoulder.rotation; cannon_elbow = cannon_transform.elbow.rotation
		last_deployment = deployment
	cannon_transform.shoulder.rotation = cannon_shoulder; cannon_transform.elbow.rotation = cannon_elbow
	# V8 supplies only cannon-arm rotations; keep normal locomotion/guard/attacks.
	cannon_transform.shoulder.rotation += shoulder_rotation*(1-deployment)
	cannon_transform.elbow.rotation += elbow_rotation*(1-deployment)
	if action.get("id","") == "cannon" and deployment > .01:
		var aim: Vector3 = action.get("aim",muzzle()+global_basis.z*10)
		for iteration in range(5):
			var axis: Vector3 = (cannon_transform.mount.global_basis*cannon_transform.GUN_AXIS).normalized()
			var desired := (aim-muzzle()).normalized()
			if desired.length() > .1:
				var adjust := Quaternion(axis,desired)
				cannon_transform.shoulder.global_basis = Basis(adjust)*cannon_transform.shoulder.global_basis

	# Rustwing remains folded within the sleeve until deployed; original meshes intact.
	for part in cannon_transform.gun_parts: part.node.visible = deployment > .01
	update_gaze(delta,immediate)
	confinement.apply_hands(self,delta)
	if not gait.initialized or procedural_blend <= 0: update_joint_caps()

func muzzle() -> Vector3:
	return cannon_transform.mount.to_global(cannon_transform.RUST_MUZZLE)

func sole_height(side: String) -> float:
	var lowest := INF
	for mesh in groups.get("Pie_"+side,[]):
		var bounds: AABB = global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
		lowest = minf(lowest,bounds.position.y)
	return 0.0 if not is_finite(lowest) else lowest

# Locomoción 0.9.18: apoyo mundial e IK analítica, sin nuevos cuerpos físicos.
var gait = preload("res://scripts/mecha_foot_planner.gd").new()
var gait_enabled := true
var gait_velocity := Vector3.ZERO
var foot_sole_offsets: Dictionary = {}
var ik_error := {"Der":0.0,"Izq":0.0}
var procedural_blend := 0.0
var procedural_root := 0.0
var view_direction := Vector3.FORWARD
var tracking_view := false
var head_yaw := 0.0
var head_pitch := 0.0
var emote_state: Dictionary = {}
var gestures = preload("res://scripts/mecha_emotes.gd").new()
var support_shift := Vector3.ZERO
var joint_caps: MultiMeshInstance3D
var joint_cap_transforms: Array[Transform3D] = []
const CAP_JOINTS := [["Rodilla_Der",.045],["Rodilla_Izq",.045],["Muslo_Der",.046],["Muslo_Izq",.046],["Pie_Der",.028],["Pie_Izq",.028]]

func configure_view(yaw: float, pitch: float, locked: bool = true) -> void:
	view_direction = Vector3.FORWARD.rotated(Vector3.RIGHT,pitch).rotated(Vector3.UP,yaw)
	tracking_view = locked
	if not locked: head_yaw = 0; head_pitch = 0

func update_gaze(delta: float, immediate: bool) -> void:
	if not tracking_view or not emote_state.is_empty() or dead: return
	var head: Node3D = pivots.Cabeza
	var local: Vector3 = head.get_parent().global_basis.orthonormalized().inverse()*view_direction
	var wanted_yaw := clampf(atan2(local.x,local.z),-.72,.72)
	var wanted_pitch := clampf(-atan2(local.y,Vector2(local.x,local.z).length()),-.65,.70)
	var blend := 1.0 if immediate else 1-exp(-delta*11)
	head_yaw = lerp_angle(head_yaw,wanted_yaw,blend)
	head_pitch = lerpf(head_pitch,wanted_pitch,blend)
	head.rotation = Vector3(head_pitch,head_yaw,head.rotation.z*.45)

func animate_emote(delta: float) -> void:
	clock += delta
	gait.update(delta,self,Vector3.ZERO,0)
	procedural_blend = minf(1,procedural_blend+delta*6)
	var result: Dictionary = gestures.sample(self,int(emote_state.index),float(emote_state.time))
	apply_pose(result.pose,result.offset,delta)
	if gait.initialized:
		for side in ["Der","Izq"]:
			var f: Dictionary = gait.feet[side]
			if f.valid: solve_world_leg(side,f.point,f.normal,f.forward)
	update_joint_caps(); state = "emote"

func configure_locomotion(controller: CharacterBody3D, is_replica: bool, actual_velocity: Vector3 = Vector3.ZERO) -> void:
	gait.configure(controller,is_replica); gait_velocity = actual_velocity
	if not foot_sole_offsets.is_empty(): return
	for side in ["Der","Izq"]:
		var foot: Node3D = pivots["Pie_"+side]
		var bottom := 0.0
		for mesh in groups.get("Pie_"+side,[]):
			var box: AABB = foot.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
			bottom = minf(bottom,box.position.y)
		foot_sole_offsets[side] = -bottom*foot.global_basis.y.length()

func solve_world_leg(side: String, target: Vector3, normal: Vector3, forward: Vector3) -> void:
	var hip: Node3D = pivots["Muslo_"+side]
	var knee: Node3D = pivots["Rodilla_"+side]
	var shin: Node3D = pivots["Pantorrilla_"+side]
	var foot: Node3D = pivots["Pie_"+side]
	shin.rotation = Vector3.ZERO
	var upper_rest: Vector3 = rest_positions["Rodilla_"+side]
	var lower_rest: Vector3 = rest_positions["Pantorrilla_"+side]+rest_positions["Pie_"+side]
	var scale_value := global_basis.y.length()
	var upper := upper_rest.length()*scale_value; var lower := lower_rest.length()*scale_value
	target = foot.global_position.lerp(target,smoothstep(0,1,procedural_blend))
	var offset := target-hip.global_position
	var length_value := clampf(offset.length(),absf(upper-lower)+.01,upper+lower-.002)
	var direction := offset.normalized()
	if direction.length_squared() < .1: return
	var bend_axis: Vector3 = global_basis.z.normalized()
	bend_axis = (bend_axis-direction*bend_axis.dot(direction)).normalized()
	if bend_axis.length_squared() < .1: bend_axis = global_basis.y.normalized()
	var cosine := clampf((upper*upper+length_value*length_value-lower*lower)/(2*upper*length_value),-1,1)
	var knee_goal := hip.global_position+direction*(upper*cosine)+bend_axis*(upper*sqrt(maxf(0,1-cosine*cosine)))
	var parent_basis: Basis = hip.get_parent().global_basis.orthonormalized()
	hip.quaternion = Quaternion(upper_rest.normalized(),(parent_basis.inverse()*(knee_goal-hip.global_position)).normalized())
	var lower_direction := direction*length_value+hip.global_position-knee.global_position
	var knee_basis: Basis = knee.get_parent().global_basis.orthonormalized()
	knee.quaternion = Quaternion(lower_rest.normalized(),(knee_basis.inverse()*lower_direction).normalized())
	# Nivelación del pie respecto de la superficie, sin alterar su escala o uniones.
	var up := normal.normalized()
	var front := (forward-up*forward.dot(up)).normalized()
	if front.length_squared() < .1: front = global_basis.z.normalized()
	var body_front: Vector3 = (global_basis.z-up*global_basis.z.dot(up)).normalized()
	var ankle_turn := body_front.signed_angle_to(front,up)
	front = body_front.rotated(up,clampf(ankle_turn,-.60,.60))
	var right := up.cross(front).normalized(); front = right.cross(up).normalized()
	var desired_basis := Basis(right,up,front)
	var foot_parent_basis: Basis = foot.get_parent().global_basis.orthonormalized()
	foot.quaternion = (foot_parent_basis.inverse()*desired_basis).get_rotation_quaternion()
	ik_error[side] = foot.global_position.distance_to(target)

func locomotion(delta: float, speed: float, grounded: bool, vertical_speed: float, distance: float, muted: bool = false) -> void:
	if not emote_state.is_empty() and grounded and not boosting and not dead and is_instance_valid(gait.body):
		animate_emote(delta); return
	var id: String = action.get("id","")
	var special := id in ["hammer","m1_hammer","seismic","m1_stomp","ram"]
	if not gait_enabled or not is_instance_valid(gait.body) or not grounded or boosting or special or dead:
		gait.clear(); procedural_blend = 0; procedural_root = 0
		super.locomotion(delta,speed,grounded,vertical_speed,distance,muted)
		update_joint_caps()
		return
	clock += delta
	gait.update(delta,self,gait_velocity,distance)
	if not gait.initialized:
		super.locomotion(delta,speed,grounded,vertical_speed,distance,muted); update_joint_caps(); return
	phase = gait.phase
	var motion: float = clampf(gait.velocity.length()/1.2,0,1)
	motion_weight = lerpf(motion_weight,motion,1-exp(-delta*7))
	var pose := neutral_pose()
	var running: float = smoothstep(1.05,2.35,gait.velocity.length())
	state = "run" if running > .5 else ("walk" if motion > .10 else "idle")
	var local_velocity: Vector3 = global_basis.orthonormalized().inverse()*gait.velocity
	var local_accel: Vector3 = global_basis.orthonormalized().inverse()*gait.acceleration
	var nominal_span: Vector3 = gait.nominal(self,"Der")-gait.nominal(self,"Izq")
	var span: Vector3 = gait.feet.Der.point-gait.feet.Izq.point-nominal_span
	var travel: Vector3 = gait.velocity.normalized() if motion > .05 else global_basis.z.normalized()
	var cycle := clampf(span.dot(travel)/.8,-1,1)
	var local_direction := local_velocity.normalized() if local_velocity.length() > .05 else Vector3.BACK
	var side_weight := absf(local_direction.x)
	var support_goal := Vector3.ZERO
	for side in ["Der","Izq"]:
		var foot: Dictionary = gait.feet[side]
		if not foot.swing: continue
		var planted_side := "Izq" if side == "Der" else "Der"
		var local_support: Vector3 = global_transform.affine_inverse()*gait.feet[planted_side].point
		var shift_weight := sin(foot.t*PI)
		support_goal.x = clampf(local_support.x*.23,-.033,.033)*shift_weight
		support_goal.z = clampf(local_support.z*.15,-.018,.018)*shift_weight
	support_shift = support_shift.lerp(support_goal,1-exp(-delta*13))
	pose.Pelvis.y = (cycle*.055+local_direction.x*.10*side_weight)*motion_weight
	pose.Pelvis.z = -support_shift.x*.65
	pose.Torso_Abdomen.y = -cycle*.075*motion_weight-local_direction.x*.06*motion_weight
	pose.Torso_Abdomen.z = -clampf(local_accel.x*.008+local_velocity.x*.014,-.075,.075)+support_shift.x*.6
	pose.Torso_Pecho.y = cycle*.065*motion_weight
	pose.Torso_Pecho.x = clampf(local_velocity.z*.028+local_accel.z*.006,-.10,.12)+sin(clock*1.35)*.006*(1-motion_weight)
	pose.Cabeza.y = -(pose.Pelvis.y+pose.Torso_Abdomen.y+pose.Torso_Pecho.y)*.75
	pose.Cabeza.z = -(pose.Pelvis.z+pose.Torso_Abdomen.z)*.65
	for side in ["Der","Izq"]:
		var sign_side := 1.0 if side == "Der" else -1.0
		pose["BrazoSuperior_"+side].x = sign_side*cycle*(.24+.10*running)*local_direction.z*motion_weight
		pose["BrazoSuperior_"+side].z = -sign_side*.035*motion_weight-sign_side*cycle*local_direction.x*.22*motion_weight
		pose["Antebrazo_"+side].x = (-.12-absf(cycle)*.10)*motion_weight
		pose["Hombro_"+side].y = sign_side*cycle*.045*motion_weight
	var bob := -.008*(1-cos(phase*TAU*2))*motion_weight
	var wanted_root: float = -.022-.012*motion_weight-.022*running+bob+gait.balance_height()/maxf(global_basis.y.length(),.1)
	if absf(gait.vertical_step) > .07:
		procedural_root -= clampf(gait.vertical_step,-.45,.45)/maxf(global_basis.y.length(),.1)
	procedural_root = lerpf(procedural_root,wanted_root,1-exp(-delta*9))
	# Compresión visual adicional cuando el apoyo se aproxima al alcance anatómico.
	var reach_drop := 0.0
	for side in ["Der","Izq"]:
		var planted: Dictionary = gait.feet[side]
		if planted.swing or not planted.valid: continue
		var hip: Node3D = pivots["Muslo_"+side]
		var separation: Vector3 = hip.global_position-planted.point
		var upper_length: float = rest_positions["Rodilla_"+side].length()*global_basis.y.length()
		var lower_length: float = (rest_positions["Pantorrilla_"+side]+rest_positions["Pie_"+side]).length()*global_basis.y.length()
		var horizontal_squared := separation.x*separation.x+separation.z*separation.z
		var allowed_y := sqrt(maxf(.1,pow(upper_length+lower_length-.015,2)-horizontal_squared))
		reach_drop = maxf(reach_drop,separation.y-allowed_y)
	procedural_root -= clampf(reach_drop,0,.10)/maxf(global_basis.y.length(),.1)
	procedural_root = maxf(procedural_root,wanted_root-.04)
	procedural_blend = minf(1,procedural_blend+delta*6)
	action_pose(pose)
	apply_pose(pose,Vector3(support_shift.x,procedural_root,support_shift.z),delta)
	for side in ["Der","Izq"]:
		var f: Dictionary = gait.feet[side]
		if f.valid: solve_world_leg(side,f.point,f.normal,f.forward)
	update_joint_caps()
	if not muted:
		for side in gait.contacts:
			if ik_error[side] < .08: foot_contact.emit(side,gait.feet[side].point)
	grounded_before = grounded

func build_joint_caps() -> void:
	joint_caps = MultiMeshInstance3D.new(); joint_caps.name = "InternalMechanicalJoints"
	var mesh := SphereMesh.new(); mesh.radius = 1; mesh.height = 2; mesh.radial_segments = 12; mesh.rings = 6
	var material := StandardMaterial3D.new(); material.albedo_color = Color(.16,.19,.20); material.metallic = .65; material.roughness = .7
	mesh.material = material
	var instances := MultiMesh.new(); instances.transform_format = MultiMesh.TRANSFORM_3D; instances.mesh = mesh; instances.instance_count = CAP_JOINTS.size()
	joint_caps.multimesh = instances; joint_cap_transforms.resize(CAP_JOINTS.size()); add_child(joint_caps); update_joint_caps()

func update_joint_caps() -> void:
	if not is_instance_valid(joint_caps): return
	var inverse := global_transform.affine_inverse()
	for i in range(CAP_JOINTS.size()):
		var source: Node3D = pivots[CAP_JOINTS[i][0]]
		var transform: Transform3D = inverse*source.global_transform
		var hidden:=false
		for key in disabled_modules:
			if pivots[key] == source or pivots[key].is_ancestor_of(source):hidden=true
		transform = transform.scaled_local(Vector3.ONE*(0.0 if hidden else float(CAP_JOINTS[i][1])))
		joint_cap_transforms[i] = transform
		joint_caps.multimesh.set_instance_transform(i,transform)

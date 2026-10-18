extends Node3D
## Rig mecánico: 22 módulos originales enlazados por sus vértices de unión.
## No cambia vértices, UV, proporciones ni pesos del GLB original.
signal foot_contact(side: String, position: Vector3)
const JOINTS = preload("res://assets/fusion/articulacion_data.gd")
var pivots: Dictionary = {}
var pieces: Dictionary = {}
var original_parents: Dictionary = {}
var original_transforms: Dictionary = {}
var rest_positions: Dictionary = {}
var rig_data: Dictionary = {}
var phase := 0.0
var clock := 0.0
var state := "idle"
var grounded_before := true
var landing := 0.0
var motion_weight := 0.0
var attached := false
var strike := -1.0
var strike_side := "Der"
var guarding := false
var foot_armed := {"Der":false,"Izq":false}
var action: Dictionary = {}
var boosting := false
var crouch_weight := 0.0
var shoulder_covers: Array[MeshInstance3D] = []
var joint_covers: Array[MeshInstance3D] = []
var sleeves: Array[Dictionary] = []

func setup(modules: Dictionary) -> void:
	name = "ArticulacionMecanica"
	rig_data = JOINTS.DATA
	pieces = modules
	for part_name in rig_data:
		var data: Dictionary = rig_data[part_name]
		var joint := Node3D.new(); joint.name = part_name+"_Joint"
		var parent: Node3D = self if data.parent.is_empty() else pivots[data.parent]
		parent.add_child(joint)
		var point := Vector3(data.pivot[0],data.pivot[1],data.pivot[2])
		var parent_point := Vector3.ZERO
		if not data.parent.is_empty():
			var p: Array = rig_data[data.parent].pivot; parent_point = Vector3(p[0],p[1],p[2])
		joint.position = point-parent_point; rest_positions[part_name] = joint.position
		pivots[part_name] = joint
		var mesh: MeshInstance3D = pieces[part_name]
		original_parents[part_name] = mesh.get_parent(); original_transforms[part_name] = mesh.transform
		mesh.reparent(joint,true)
	attached = true
	close_shoulders()

func close_shoulders() -> void:
	# Los cortes de Meshy no son articulaciones. Los fuelles conectan sus
	# contornos reales sin estirar vértices ni engordar las 22 piezas.
	var material := StandardMaterial3D.new(); material.albedo_color = Color("30383b")
	material.metallic = .78; material.roughness = .5
	var data: Dictionary = preload("res://assets/fusion/joint_sleeves_v0915.gd").DATA
	for part_name in data:
		var seal := MeshInstance3D.new(); seal.name = "Fuelle_"+part_name
		seal.mesh = ImmediateMesh.new(); seal.material_override = material
		seal.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
		pivots[part_name].add_child(seal)
		joint_covers.append(seal)
		if part_name.begins_with("BrazoSuperior_"): shoulder_covers.append(seal)
		var parent: MeshInstance3D = pieces[data[part_name].parent]
		var child: MeshInstance3D = pieces[part_name]
		var anchors: Array = []
		for edge in data[part_name].edges:
			var endpoints: Array = []
			for p in edge:
				var world_point: Vector3 = global_transform*Vector3(p[0],p[1],p[2])
				endpoints.append([parent.global_transform.affine_inverse()*world_point,child.global_transform.affine_inverse()*world_point])
			anchors.append(endpoints)
		sleeves.append({"mesh":seal,"parent":parent,"child":child,"anchors":anchors})
	update_sleeves()

func update_sleeves() -> void:
	for sleeve in sleeves:
		var mesh: ImmediateMesh = sleeve.mesh.mesh; mesh.clear_surfaces()
		var inverse: Transform3D = sleeve.mesh.global_transform.affine_inverse()
		var a: Transform3D = inverse*sleeve.parent.global_transform
		var b: Transform3D = inverse*sleeve.child.global_transform
		var triangles: Array[Vector3] = []
		for edge in sleeve.anchors:
			var p0: Vector3 = a*edge[0][0]; var p1: Vector3 = a*edge[1][0]
			var q0: Vector3 = b*edge[0][1]; var q1: Vector3 = b*edge[1][1]
			if (p1-p0).cross(q0-p0).length_squared() > .000000000001: triangles.append_array([p0,p1,q0])
			if (q1-p1).cross(q0-p1).length_squared() > .000000000001: triangles.append_array([p1,q1,q0])
		if triangles.is_empty(): continue
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(0,triangles.size(),3):
			var normal: Vector3 = (triangles[i+1]-triangles[i]).cross(triangles[i+2]-triangles[i]).normalized()
			for j in range(3): mesh.surface_set_normal(normal); mesh.surface_add_vertex(triangles[i+j])
		mesh.surface_end()

func detach() -> void:
	if not attached: return
	for part_name in pieces:
		var mesh: MeshInstance3D = pieces[part_name]
		mesh.reparent(original_parents[part_name],true); mesh.transform = original_transforms[part_name]
	attached = false

func angles() -> Dictionary:
	var result: Dictionary = {}
	for part_name in pivots: result[part_name] = Vector3.ZERO
	return result

func neutral_pose() -> Dictionary:
	var result := angles()
	for side in ["Der","Izq"]:
		var sign_side := 1.0 if side == "Der" else -1.0
		result["Hombro_"+side].z = 0
		result["BrazoSuperior_"+side].z = sign_side*1.28
		result["Antebrazo_"+side].y = sign_side*.18
	return result

func apply_pose(rotations: Dictionary, root_offset: Vector3, delta: float, immediate: bool = false) -> void:
	var pose_speed := 22.0 if action.get("id","") in ["hammer","m1_hammer"] else 12.0
	var weight := 1.0 if immediate else 1-exp(-delta*pose_speed)
	for part_name in pivots:
		var node: Node3D = pivots[part_name]
		var target := Quaternion.from_euler(rotations[part_name])
		node.quaternion = node.quaternion.slerp(target,weight)
		var pos: Vector3 = rest_positions[part_name]
		if part_name == "Pelvis": pos += root_offset
		node.position = node.position.lerp(pos,weight)
	update_sleeves()

func action_pose(pose: Dictionary) -> void:
	if crouch_weight > 0.005:
		var k: float = clampf(crouch_weight,0,1)
		pose.Torso_Abdomen.x += -0.25*k
		pose.Torso_Pecho.x += 0.38*k
		for side in ["Der","Izq"]:
			pose["Muslo_"+side].x += -0.60*k
			pose["Rodilla_"+side].x += 1.05*k
			pose["Pantorrilla_"+side].x += -0.36*k
		pose.Pelvis.x += 0.10*k
	if boosting:
		# Boost procedural: impulso escalonado y absorción de vibración mecánica.
		var pulse := sin(clock*17.0)
		pose.Torso_Abdomen.x = -.22+0.025*pulse
		pose.Torso_Pecho.x = .08-0.018*pulse
		pose.Cabeza.x = 0.02-0.012*pulse
		for side in ["Der","Izq"]:
			var alternating := pulse if side == "Der" else -pulse
			pose["Muslo_"+side].x = -.26+0.12*alternating
			pose["Rodilla_"+side].x = .58-0.08*alternating
			pose["Pantorrilla_"+side].x = -.14
			pose["BrazoSuperior_"+side].y = (0.09 if side == "Der" else -0.09)*pulse
	if not String(action.get("id","")).is_empty():
		attack_pose(pose)
	if guarding:
		for side in ["Der","Izq"]:
			var sign_side := 1.0 if side == "Der" else -1.0
			pose["BrazoSuperior_"+side].z = sign_side*.78
			pose["BrazoSuperior_"+side].y = sign_side*.70
			pose["Antebrazo_"+side].y = sign_side*.85
	if strike >= 0:
		var p := clampf(strike,0,1)
		var extension := smoothstep(.24,.52,p)*(1-smoothstep(.58,1,p))
		var sign_side := 1.0 if strike_side == "Der" else -1.0
		pose["BrazoSuperior_"+strike_side].y = sign_side*(.18+.95*extension)
		pose["BrazoSuperior_"+strike_side].z = sign_side*(1.28-.73*extension)
		pose["Antebrazo_"+strike_side].y = sign_side*(.40-.18*extension)
		pose.Torso_Pecho.x += extension*.12
		pose.Torso_Abdomen.y += sign_side*extension*.10

func attack_pose(pose: Dictionary) -> void:
	var id: String = action.id
	var time: float = action.get("time",0)
	var contact: float = maxf(.01,float(action.get("contact",.55)))
	var total: float = maxf(contact+.01,float(action.get("duration",1.2)))
	var anticipation := smoothstep(0,contact*.28,time)*(1-smoothstep(contact*.40,contact*.72,time))
	var impact := smoothstep(contact*.45,contact*.75,time)*(1-smoothstep(contact+.16,total,time))
	if id == "cannon":
		var aim := smoothstep(0,.45,time)*(1-smoothstep(1.3,total,time))
		pose.BrazoSuperior_Der.z = 1.28-aim*.98
		pose.BrazoSuperior_Der.y = aim*1.36; pose.Antebrazo_Der.y = -.10*aim
		pose.Torso_Abdomen.y = -.12*aim; pose.Torso_Pecho.y = .08*aim
		pose.Torso_Pecho.x -= sin(clampf((time-.95)/.18,0,1)*PI)*.06
	elif id in ["hammer","m1_hammer"]:
		var two_hands := id == "hammer"
		for side in ["Der","Izq"]:
			if side == "Izq" and not two_hands: continue
			var sign_side := 1.0 if side == "Der" else -1.0
			pose["BrazoSuperior_"+side].z = sign_side*(1.28-anticipation*2.35+impact*.20)
			pose["BrazoSuperior_"+side].y = sign_side*(anticipation*.15+impact*.08)
			pose["BrazoSuperior_"+side].x = anticipation*-.3-impact*1.45
			pose["Antebrazo_"+side].y = sign_side*(anticipation*.4+impact*.06)
		pose.Torso_Abdomen.x = -.10*anticipation+.65*impact
		pose.Torso_Pecho.x = -.08*anticipation+.35*impact
		pose.Torso_Pecho.y = -.08*anticipation if not two_hands else 0
	elif id in ["seismic","m1_stomp"]:
		var lift_weight := smoothstep(0,contact*.45,time)*(1-smoothstep(contact*.7,contact,time))
		pose.Muslo_Der.x -= lift_weight*.95; pose.Rodilla_Der.x += lift_weight*1.35
		pose.Pie_Der.x -= lift_weight*.40
		pose.Torso_Abdomen.z = -.035*anticipation+.025*impact
		pose.Torso_Pecho.x = -.04*anticipation+.11*impact
		pose.Muslo_Izq.x -= anticipation*.08; pose.Rodilla_Izq.x += anticipation*.12
	elif id == "ram":
		var lean := smoothstep(0,.4,time)*(1-smoothstep(1.25,total,time))
		pose.Torso_Abdomen.x = .20*lean; pose.Torso_Pecho.x = .10*lean
		pose.BrazoSuperior_Der.y = .55*lean; pose.BrazoSuperior_Izq.y = -.55*lean

func plant_impact_legs(pose: Dictionary, root_y: float, grounded: bool) -> float:
	if not grounded or action.get("id","") not in ["hammer","m1_hammer"]: return root_y
	var time: float = action.get("time",0)
	var contact: float = maxf(.01,float(action.get("contact",.55)))
	var total: float = maxf(contact+.01,float(action.get("duration",1.2)))
	var weight := smoothstep(contact*.45,contact*.75,time)*(1-smoothstep(contact+.18,total,time))
	root_y -= .285*weight
	for side in ["Der","Izq"]: leg_ik(pose,side,.14*weight,0,root_y)
	return root_y

func activation(time: float) -> void:
	state = "activation"
	var p := clampf(time/2.8,0,1)
	var eased := smoothstep(.0,.47,p)
	var pose := neutral_pose()
	for part_name in pose: pose[part_name] *= eased
	var compression := sin(clampf((p-.15)/.65,0,1)*PI)*.012
	for side in ["Der","Izq"]:
		pose["Muslo_"+side].x = -.12*eased-.12*sin(p*PI)
		pose["Rodilla_"+side].x = .18*eased+.21*sin(p*PI)
		pose["Pie_"+side].x = -pose["Muslo_"+side].x-pose["Rodilla_"+side].x
	pose.Torso_Pecho.x = -.05*sin(p*PI)
	pose.Cabeza.x = .06*sin(p*PI)
	# El último asentamiento termina de pie, sin salto de pose al entregar control.
	var settle := smoothstep(.78,1.0,p)
	for side in ["Der","Izq"]:
		for part_name in ["Muslo_","Rodilla_","Pie_"]: pose[part_name+side].x *= 1-settle
	apply_pose(pose,Vector3(0,-compression,0),0,true)

func leg_ik(pose: Dictionary, side: String, target_z: float, lift: float, root_offset: float) -> void:
	var hip_data: Array = rig_data["Muslo_"+side].pivot
	var knee_data: Array = rig_data["Rodilla_"+side].pivot
	var ankle_data: Array = rig_data["Pie_"+side].pivot
	var hip := Vector3(hip_data[0],hip_data[1]+root_offset,hip_data[2])
	var knee := Vector3(knee_data[0],knee_data[1],knee_data[2])
	var ankle := Vector3(ankle_data[0],ankle_data[1]+lift,ankle_data[2]+target_z)
	var rest_hip := atan2(knee_data[2]-hip_data[2],hip_data[1]-knee_data[1])
	var rest_shin := atan2(ankle_data[2]-knee_data[2],knee_data[1]-ankle_data[1])
	var upper: float = Vector2(knee_data[1]-hip_data[1],knee_data[2]-hip_data[2]).length()
	var lower: float = Vector2(ankle_data[1]-knee_data[1],ankle_data[2]-knee_data[2]).length()
	var dy := hip.y-ankle.y; var dz := ankle.z-hip.z
	var distance := clampf(Vector2(dy,dz).length(),absf(upper-lower)+.002,upper+lower-.0005)
	var angle := atan2(dz,dy)
	var hip_angle := angle+acos(clampf((upper*upper+distance*distance-lower*lower)/(2*upper*distance),-1,1))
	var bend := PI-acos(clampf((upper*upper+lower*lower-distance*distance)/(2*upper*lower),-1,1))
	pose["Muslo_"+side].x = rest_hip-hip_angle
	pose["Rodilla_"+side].x = bend+rest_shin-rest_hip
	pose["Pie_"+side].x = -pose["Muslo_"+side].x-pose["Rodilla_"+side].x

func locomotion(delta: float, speed: float, grounded: bool, vertical_speed: float, distance: float, muted: bool = false) -> void:
	clock += delta
	var pose := neutral_pose()
	var moving := speed > .12 and grounded
	var target_weight := clampf(speed/1.0,0,1) if moving else 0.0
	motion_weight = lerpf(motion_weight,target_weight,1-exp(-delta*7))
	var running := speed > 1.65
	var root_y := (-.030+sin(phase*TAU*2)*.002)*motion_weight
	if not grounded:
		state = "fall" if vertical_speed < 0 else "rise"
		for side in ["Der","Izq"]:
			pose["Muslo_"+side].x = -.14; pose["Rodilla_"+side].x = .24
			pose["BrazoSuperior_"+side].z *= .82
	elif moving or motion_weight > .01:
		state = "run" if running else "walk"
		# El ciclo avanza por distancia real; colisionar contra una pared no produce pasos.
		if moving and distance < 1.0: phase += distance/(2.2 if running else 1.55)
		for side in ["Der","Izq"]:
			var side_phase := fposmod(phase+(.5 if side == "Izq" else 0),1)
			var swing := clampf((side_phase-.62)/.38,0,1)
			var stride := (.145 if running else .102)*motion_weight
			var z := lerpf(stride,-stride,side_phase/.62) if side_phase < .62 else lerpf(-stride,stride,smoothstep(0,1,swing))
			var lift := sin(swing*PI)*(.045 if running else .032)*motion_weight
			leg_ik(pose,side,z,lift,root_y)
			var sign_side := 1.0 if side == "Der" else -1.0
			pose["Hombro_"+side].y = sin(TAU*side_phase)*.035*motion_weight
			pose["Antebrazo_"+side].y += sign_side*(.08+sin(TAU*side_phase)*.07)*motion_weight
			pose["BrazoSuperior_"+side].y = sign_side*sin(TAU*side_phase)*.16*motion_weight
		pose.Torso_Abdomen.y = sin(phase*TAU)*.065*motion_weight
		pose.Torso_Abdomen.z = sin(phase*TAU)*.018*motion_weight
		pose.Torso_Pecho.y = -pose.Torso_Abdomen.y*.7
		pose.Torso_Pecho.x = (.035+sin(phase*TAU*2)*.012)*motion_weight
		pose.Torso_Pecho.z = -pose.Torso_Abdomen.z*.65
		root_y = plant_impact_legs(pose,root_y,grounded)
		action_pose(pose)
		apply_pose(pose,Vector3(0,root_y,0),delta)
		support_feet()
		for side in ["Der","Izq"]:
			var cycle := fposmod(phase+(.5 if side == "Izq" else 0),1)
			if cycle > .62: foot_armed[side] = true
			if moving and not muted and cycle < .62 and foot_armed[side] and sole_height(side) <= .008:
				foot_armed[side] = false; foot_contact.emit(side,foot_position(side))
		grounded_before = grounded
		return
	else:
		state = "idle"
		pose.Torso_Abdomen.y = sin(clock*.52)*.012
		pose.Torso_Pecho.x = sin(clock*1.35)*.012
		pose.Torso_Pecho.z = sin(clock*.68)*.007
		pose.Cabeza.y = sin(clock*.55)*.018
	if grounded and not grounded_before: landing = .28
	landing = maxf(0,landing-delta)
	if landing > 0:
		state = "land"
		var compression := sin(landing/.28*PI)*.10
		for side in ["Der","Izq"]:
			pose["Muslo_"+side].x -= compression*.5
			pose["Rodilla_"+side].x += compression
	root_y = plant_impact_legs(pose,root_y,grounded)
	action_pose(pose)
	apply_pose(pose,Vector3(0,root_y,0),delta)
	if grounded: support_feet()
	if not moving:
		foot_armed.Der = false; foot_armed.Izq = false
	grounded_before = grounded

func foot_position(side: String) -> Vector3:
	return pivots["Pie_"+side].global_position

func sole_height(side: String) -> float:
	var mesh: MeshInstance3D = pieces["Pie_"+side]
	var bounds: AABB = global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
	return bounds.position.y

func support_feet() -> void:
	var lowest := INF
	for side in ["Der","Izq"]:
		var cycle := fposmod(phase+(.5 if side == "Izq" else 0),1)
		if state in ["idle","land"] or not action.get("id","").is_empty() or cycle < .62: lowest = minf(lowest,sole_height(side))
	if is_finite(lowest): pivots.Pelvis.position.y -= clampf(lowest,-.04,.04)

extends RefCounted
## Planificador visual: apoyos mundiales, un pie en vuelo y consultas acotadas.
## No cambia el CharacterBody ni decide daño, colisiones o movimiento del jugador.
const SIDES := ["Der","Izq"]
var body: CharacterBody3D
var replica := false
var feet: Dictionary = {}
var velocity := Vector3.ZERO
var acceleration := Vector3.ZERO
var previous_velocity := Vector3.ZERO
var last_origin := Vector3.ZERO
var initialized := false
var vertical_step := 0.0
var enabled := true
var phase := .12
var clock := 0.0
var query_clock := 0.0
var budget := 0
var queries_frame := 0
var queries_total := 0
var steps := 0
var contacts: Array = []
var next_side := "Izq"
var last_stamp := -1.0
var authoritative_velocity := Vector3.ZERO
var measured_velocity := Vector3.ZERO
var travel_mode := ""

func configure(controller: CharacterBody3D, is_replica: bool) -> void:
	if body != controller or replica != is_replica: clear()
	body = controller; replica = is_replica

func clear() -> void:
	feet.clear(); initialized = false; contacts.clear(); previous_velocity = Vector3.ZERO
	velocity = Vector3.ZERO; acceleration = Vector3.ZERO; last_stamp = -1; query_clock = 0
	travel_mode = ""

func ensure_feet(rig: Node3D) -> void:
	if not feet.is_empty(): return
	for side in SIDES:
		var rest: Array = rig.rig_data["Pie_"+side].pivot
		feet[side] = {"rest":Vector3(rest[0],rest[1],rest[2]),"sole":rig.foot_sole_offsets[side],"point":Vector3.ZERO,"normal":Vector3.UP,"forward":Vector3.FORWARD,"from":Vector3.ZERO,"to":Vector3.ZERO,"from_forward":Vector3.FORWARD,"goal_forward":Vector3.FORWARD,"goal_normal":Vector3.UP,"swing":false,"t":0.0,"duration":.28,"valid":false,"platform":null,"local_point":Vector3.ZERO,"local_normal":Vector3.UP}

func nominal(rig: Node3D, side: String) -> Vector3:
	return rig.global_transform*feet[side].rest

func sample(point: Vector3, sole: float) -> Dictionary:
	if budget <= 0 or not is_instance_valid(body): return {}
	budget -= 1; queries_frame += 1; queries_total += 1
	var query := PhysicsRayQueryParameters3D.create(Vector3(point.x,body.global_position.y+.8,point.z),Vector3(point.x,body.global_position.y-.70,point.z),1|512)
	query.exclude = [body.get_rid()]
	var hit := body.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.normal.y < .65 or hit.position.y > body.global_position.y+.46: return {}
	var n: Vector3 = hit.normal.normalized()
	return {"point":hit.position+n*sole,"normal":n,"platform":hit.collider}

func attach_surface(foot: Dictionary, hit: Dictionary) -> void:
	foot.platform = hit.get("platform")
	if is_instance_valid(foot.platform) and foot.platform is Node3D:
		foot.local_point = foot.platform.to_local(hit.point)
		foot.local_normal = foot.platform.global_basis.orthonormalized().inverse()*hit.normal

func follow_surface(foot: Dictionary) -> void:
	if not replica and not foot.swing and is_instance_valid(foot.platform) and foot.platform is Node3D:
		foot.point = foot.platform.to_global(foot.local_point)
		foot.normal = (foot.platform.global_basis.orthonormalized()*foot.local_normal).normalized()

func initialize(rig: Node3D) -> void:
	ensure_feet(rig); budget = 2
	for side in SIDES:
		var f: Dictionary = feet[side]
		var hit := sample(nominal(rig,side),f.sole)
		f.point = hit.get("point",nominal(rig,side)); f.to = f.point; f.from = f.point
		f.normal = hit.get("normal",Vector3.UP); f.forward = rig.global_basis.z.normalized()
		f.goal_forward = f.forward; f.from_forward = f.forward; f.valid = not hit.is_empty(); f.swing = false
		attach_surface(f,hit)
	initialized = true; last_origin = body.global_position

func begin_step(rig: Node3D, side: String, speed: float) -> bool:
	var f: Dictionary = feet[side]
	var prediction_time := lerpf(.46,.36,smoothstep(.8,2.35,speed))
	var support_side: String="Izq" if side=="Der" else "Der"
	var support:Dictionary=feet[support_side]
	if speed>.2 and support.valid:
		var hip:Vector3=rig.pivots["Muslo_"+support_side].global_position
		var trailing:float=(hip-support.point).dot(measured_velocity.normalized())
		# Un cambio de dirección puede exigir un paso de recuperación corto;
		# no mantener el otro pie fijo hasta estirar toda la pierna.
		prediction_time=minf(prediction_time,clampf((.72-trailing)/maxf(measured_velocity.length(),.2),.14,.46))
	var lead := lerpf(.24,.40,smoothstep(.8,2.35,speed))
	# El pie aterriza DELANTE de la cadera futura, no debajo de ella.
	var prediction: Vector3 = (measured_velocity*prediction_time+measured_velocity.normalized()*lead+acceleration*(.25*prediction_time*prediction_time)).limit_length(1.42)
	var anticipated := nominal(rig,side)+prediction
	var future_center := rig.global_position+measured_velocity*prediction_time
	var local: Vector3 = rig.global_basis.orthonormalized().inverse()*(anticipated-future_center)
	var side_sign := 1.0 if side == "Der" else -1.0
	# Mantener los pies a su lado del cuerpo impide cruzarlos en un strafe.
	local.x = side_sign*maxf(side_sign*local.x,.24)
	anticipated = future_center+rig.global_basis.orthonormalized()*local
	var lateral_velocity:Vector3=rig.global_basis.orthonormalized().inverse()*measured_velocity
	if absf(lateral_velocity.x)>absf(lateral_velocity.z)*1.2 and support.valid:
		# Paso lateral de alcance y reunión: el pie que se reúne no atraviesa
		# al que ya sostiene el peso, aunque la predicción mire más adelante.
		var right_axis:Vector3=rig.global_basis.x.normalized()
		var separation:float=side_sign*(anticipated-support.point).dot(right_axis)
		if separation<.29:anticipated+=right_axis*side_sign*(.29-separation)
	var hit := sample(anticipated,f.sole)
	if hit.is_empty() and budget>0:
		# En escalones o bordes, acortar ese paso en vez de mantener un
		# apoyo viejo mientras el controlador sigue avanzando.
		hit=sample(nominal(rig,side)+measured_velocity*.08,f.sole)
	if hit.is_empty(): return false
	f.from = f.point; f.to = hit.point; f.goal_normal = hit.normal
	var travel: Vector3 = rig.global_basis.orthonormalized().inverse()*measured_velocity
	var turn := clampf(atan2(travel.x,absf(travel.z)+.5)*.23,-.32,.32)
	f.goal_forward = rig.global_basis.z.normalized().rotated(Vector3.UP,turn); f.from_forward = f.forward
	f.t = 0.0; f.duration = prediction_time; f.swing = true; f.valid = true
	attach_surface(f,hit); next_side = "Izq" if side == "Der" else "Der"
	return true

func advance_feet(delta: float, speed: float) -> void:
	for side in SIDES:
		var f: Dictionary = feet[side]
		if not f.swing: follow_surface(f); continue
		f.t = minf(1.0,f.t+delta/f.duration)
		var u: float = smoothstep(0,1,f.t)
		var clearance := lerpf(.20,.34,smoothstep(1,2.35,speed))+minf(.10,absf(f.to.y-f.from.y)*.25)
		f.point = f.from.lerp(f.to,u)+Vector3.UP*sin(f.t*PI)*clearance
		f.normal = f.normal.lerp(f.goal_normal,u).normalized()
		f.forward = f.from_forward.lerp(f.goal_forward,u).normalized()
		if f.t >= 1:
			f.swing = false; f.point = f.to; f.normal = f.goal_normal; f.forward = f.goal_forward
			if not replica and f.valid: contacts.append(side); steps += 1

func update(delta: float, rig: Node3D, actual_velocity: Vector3, distance: float) -> void:
	contacts.clear(); queries_frame = 0; budget = 0
	clock += delta; query_clock += delta
	if not is_instance_valid(body): return
	if not replica and initialized and last_origin.distance_to(body.global_position) > 2.2: clear()
	if query_clock >= .05: query_clock = fmod(query_clock,.05); budget = 2
	ensure_feet(rig)
	if not initialized:
		if replica: return
		initialize(rig)
	vertical_step = body.global_position.y-last_origin.y
	last_origin = body.global_position
	var wanted: Vector3 = authoritative_velocity if replica else actual_velocity
	wanted.y = 0
	measured_velocity = wanted
	var old := velocity
	velocity = velocity.lerp(wanted,1-exp(-delta*12))
	acceleration = acceleration.lerp((velocity-old)/maxf(delta,.001),1-exp(-delta*8)).limit_length(12)
	var speed := velocity.length()
	if not replica and distance < 1.0: phase += distance/lerpf(1.55,2.2,smoothstep(1,2.35,speed))
	advance_feet(delta,speed)
	if replica: return
	if feet.Der.swing or feet.Izq.swing: return
	var local_velocity: Vector3 = rig.global_basis.orthonormalized().inverse()*measured_velocity
	var mode := "lateral" if absf(local_velocity.x) > absf(local_velocity.z)*1.2 else "frontal"
	if speed > .25 and mode != travel_mode:
		travel_mode = mode
		if mode == "lateral": next_side = "Der" if local_velocity.x > 0 else "Izq"
	var selected := ""; var biggest := 0.0
	for side in [next_side,"Der" if next_side == "Izq" else "Izq"]:
		var f: Dictionary = feet[side]
		var offset: Vector3 = nominal(rig,side)-f.point; offset.y = 0
		var angle := absf(f.forward.signed_angle_to(rig.global_basis.z.normalized(),Vector3.UP))
		var threshold := lerpf(.40,.32,smoothstep(1,2.35,speed)) if speed > .12 else .24
		var score: float = maxf(offset.length()/threshold,angle/.5)
		if speed>.12:
			var travel:=velocity.normalized()
			var trailing:=offset.dot(travel)
			var across:Vector3=offset-travel*trailing
			score=maxf(maxf(trailing/threshold,across.length()/.45),angle/.5)
		if not f.valid: score = maxf(score,2)
		if score > maxf(1,biggest): selected = side; biggest = score
	if not selected.is_empty(): begin_step(rig,selected,speed)

func balance_height() -> float:
	if not initialized: return 0.0
	var sum := 0.0; var count := 0
	for f in feet.values():
		if f.valid and not f.swing:
			sum += f.point.y-f.normal.y*f.sole-body.global_position.y; count += 1
	return clampf(sum/float(maxi(1,count)),-.20,.20)

func snapshot() -> Dictionary:
	if not initialized: return {}
	var result := {"stamp":clock,"phase":phase,"velocity":velocity,"feet":[]}
	for side in SIDES:
		var f: Dictionary = feet[side]; var data := {"side":side}
		for key in ["point","normal","forward","from","to","from_forward","goal_forward","goal_normal","swing","t","duration","valid"]: data[key] = f[key]
		result.feet.append(data)
	return result

func accept_state(data: Dictionary, rig: Node3D) -> void:
	if data.is_empty() or float(data.get("stamp",-1)) <= last_stamp: return
	if not data.get("velocity",Vector3.ZERO).is_finite() or data.get("feet",[]).size() != 2: return
	ensure_feet(rig)
	for item in data.feet:
		if item.get("side","") not in SIDES: return
		for key in ["point","normal","forward","from","to","from_forward","goal_forward","goal_normal"]:
			if not item.get(key,Vector3.ZERO).is_finite(): return
		if item.point.distance_to(body.global_position) > 6: return
	for item in data.feet:
		for key in ["point","normal","forward","from","to","from_forward","goal_forward","goal_normal","swing","t","duration","valid"]: feet[item.side][key] = item[key]
		feet[item.side].duration = clampf(float(item.duration),.1,.6)
		feet[item.side].platform = null
	last_stamp = float(data.stamp); phase = float(data.phase); authoritative_velocity = data.velocity
	initialized = true

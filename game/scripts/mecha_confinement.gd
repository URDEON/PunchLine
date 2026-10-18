extends RefCounted
## Additive body reactions and two-bone hand IK against authoritative contacts.
var hand_weights := {"Der":0.0,"Izq":0.0}
var hand_errors: Dictionary = {}
var hand_goals: Dictionary = {}

func adjust_pose(rig: Node3D,pose: Dictionary) -> void:
	var state: Dictionary = rig.confinement_state
	var pressure: float = float(state.get("pressure",0))
	if pressure<.005 or occupied(rig): return
	var contacts: Dictionary = state.get("contacts",{})
	var right: float = float(contacts.get("Der",{}).get("weight",0))
	var left: float = float(contacts.get("Izq",{}).get("weight",0))
	pose.Torso_Pecho.z += (right-left)*.10
	pose.Torso_Abdomen.x += pressure*.08
	for side in ["Der","Izq"]:
		var sign_side := 1.0 if side=="Der" else -1.0
		# Tuck the elbows before the shoulders reach a narrow doorway.
		pose["BrazoSuperior_"+side].y += sign_side*pressure*.32
		pose["BrazoSuperior_"+side].x -= pressure*.12
		pose["Antebrazo_"+side].x -= pressure*.42

func occupied(rig: Node3D) -> bool:
	return rig.dead or rig.boosting or rig.guarding or not rig.action.get("id","").is_empty() or not rig.emote_state.is_empty()

func apply_hands(rig: Node3D,delta: float) -> void:
	var contacts: Dictionary = rig.confinement_state.get("contacts",{})
	hand_errors.clear(); hand_goals.clear()
	for side in ["Der","Izq"]:
		var contact: Dictionary = contacts.get(side,{})
		var enabled: bool = not occupied(rig) and not contact.is_empty()
		for module in ["BrazoSuperior_","Antebrazo_","Mano_"]:
			if rig.disabled_modules.has(module+side): enabled=false
		var wanted: float = float(contact.get("weight",0)) if enabled else 0.0
		hand_weights[side] = move_toward(float(hand_weights[side]),wanted,delta*4)
		if not enabled or hand_weights[side]<.01: continue
		var normal: Vector3 = contact.normal
		var goal: Vector3 = contact.point+normal*.09
		var weight: float = smoothstep(0,.62,float(hand_weights[side]))
		solve_arm(rig,side,goal,normal,weight)
	var compression: float = float(rig.confinement_state.get("compression",0))
	if not occupied(rig): rig.pivots.Cabeza.rotation.x += compression*.12

func solve_arm(rig: Node3D,side: String,goal: Vector3,normal: Vector3,weight: float) -> void:
	var shoulder: Node3D = rig.pivots["BrazoSuperior_"+side]
	var elbow: Node3D = rig.pivots["Antebrazo_"+side]
	var hand: Node3D = rig.pivots["Mano_"+side]
	var upper: Vector3 = rig.rest_positions["Antebrazo_"+side]
	var lower: Vector3 = rig.rest_positions["Mano_"+side]
	var scale_value: float = shoulder.global_basis.get_scale().y
	var a: float = upper.length()*scale_value
	var b: float = lower.length()*scale_value
	var reach: Vector3 = goal-shoulder.global_position
	if reach.length()<.001: return
	var direction: Vector3 = reach.normalized()
	var distance: float = clampf(reach.length(),absf(a-b)+.01,a+b-.01)
	var pole: Vector3 = rig.global_basis.z.normalized()+Vector3.DOWN*.45
	pole = (pole-direction*pole.dot(direction)).normalized()
	if pole.length_squared()<.01: pole=rig.global_basis.x.normalized()
	var along: float = (a*a-b*b+distance*distance)/(2*distance)
	var knee: Vector3 = shoulder.global_position+direction*along+pole*sqrt(maxf(0,a*a-along*along))
	var parent_basis: Basis = shoulder.get_parent().global_basis.orthonormalized()
	var rotation := Quaternion(upper.normalized(),(parent_basis.inverse()*(knee-shoulder.global_position)).normalized()).normalized()
	shoulder.quaternion=shoulder.quaternion.slerp(rotation,weight).normalized()
	var reachable: Vector3 = shoulder.global_position+direction*distance
	parent_basis=elbow.get_parent().global_basis.orthonormalized()
	rotation=Quaternion(lower.normalized(),(parent_basis.inverse()*(reachable-elbow.global_position)).normalized()).normalized()
	elbow.quaternion=elbow.quaternion.slerp(rotation,weight).normalized()
	# Orient the wrist into the supporting surface without changing arm lengths.
	var up: Vector3 = rig.global_basis.z.normalized() if absf(normal.y)>.8 else Vector3.UP
	var desired: Basis = Basis.looking_at(-normal,up)
	rotation=(hand.get_parent().global_basis.orthonormalized().inverse()*desired).get_rotation_quaternion().normalized()
	hand.quaternion=hand.quaternion.slerp(rotation,weight).normalized()
	hand_goals[side]=goal
	hand_errors[side]=hand.global_position.distance_to(goal)

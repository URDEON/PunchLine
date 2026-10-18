extends RefCounted
## Gestos de piezas rígidas, sin fingir un esqueleto o clips importados.
const ENTRIES := [
	{"name":"Baile de acero","clip":"sentinel/dance","speed":1.0,"music":true,"duration":0.0},
	{"name":"Saludo de titán","clip":"sentinel/salute","speed":1.0,"music":false,"duration":3.4},
	{"name":"Afirmativo","clip":"sentinel/yes","speed":1.0,"music":false,"duration":2.6},
	{"name":"Negativo","clip":"sentinel/no","speed":1.0,"music":false,"duration":2.6}]

func sample(rig: Node3D, index: int, time: float) -> Dictionary:
	var pose: Dictionary = rig.neutral_pose()
	var entry: Dictionary = ENTRIES[clampi(index,0,ENTRIES.size()-1)]
	var envelope := smoothstep(0,.3,time)
	if entry.duration > 0: envelope *= 1-smoothstep(entry.duration-.4,entry.duration,time)
	var offset := Vector3(0,-.026,0)
	if index == 0:
		var beat := time*TAU*.72
		offset += Vector3(sin(beat)*.027,-absf(sin(beat))*.018,0)*envelope
		pose.Pelvis.y = sin(beat)*.08*envelope
		pose.Torso_Abdomen.z = -sin(beat)*.06*envelope
		pose.Torso_Pecho.y = -sin(beat)*.15*envelope
		pose.Cabeza.z = sin(beat)*.035*envelope
		for side in ["Der","Izq"]:
			var s := 1.0 if side == "Der" else -1.0
			pose["BrazoSuperior_"+side] = Vector3(-.35+sin(beat+s*1.2)*.30,0,s*.16)*envelope
			pose["Antebrazo_"+side].x = (-.5+cos(beat+s*1.2)*.25)*envelope
	elif index == 1:
		pose.BrazoSuperior_Der = Vector3(-1.22,.15,.28)*envelope
		pose.Antebrazo_Der = Vector3(-.90,0,.12)*envelope
		pose.Mano_Der.z = sin(time*9)*.16*envelope
		pose.Torso_Pecho.y = -.08*envelope
		pose.Cabeza.x = -.08*envelope
	elif index == 2:
		pose.Cabeza.x = sin(time*8)*.25*envelope
		pose.Torso_Pecho.x = sin(time*8)*.025*envelope
		pose.BrazoSuperior_Der.x = -.25*envelope
		pose.Antebrazo_Der.x = -.5*envelope
	else:
		pose.Cabeza.y = sin(time*7)*.38*envelope
		pose.Torso_Abdomen.y = -sin(time*7)*.035*envelope
		pose.BrazoSuperior_Izq.z = -.24*envelope
		pose.Antebrazo_Izq.x = -.50*envelope
	return {"pose":pose,"offset":offset}

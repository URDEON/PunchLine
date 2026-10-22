extends Node3D
## Original provisional full-body rig. Replace this component without changing movement.
## One Skeleton3D serves FPS and TPS; no legacy fighter model or duplicated arms.
var skeleton: Skeleton3D
var bones: Dictionary = {}
var attachments: Dictionary = {}
var head: BoneAttachment3D
var phase := 0.0
var crouch_weight := 0.0
var gait_weight := 0.0
var cloth: ShaderMaterial
var armor: StandardMaterial3D
var dark: StandardMaterial3D
var accent: StandardMaterial3D
var glass: StandardMaterial3D

func _ready() -> void:
	cloth = ShaderMaterial.new()
	cloth.shader = preload("res://units/soldiers/uniform.gdshader")
	armor = material(Color("45544e"))
	dark = material(Color("182628"))
	accent = material(Color("79c9c2"),0.2)
	glass = material(Color("173d43"),0.65)
	skeleton = Skeleton3D.new()
	skeleton.name = "SoldierSkeleton"
	add_child(skeleton)
	bone("pelvis","",Vector3(0,0.94,0))
	bone("spine","pelvis",Vector3(0,0.17,0))
	bone("chest","spine",Vector3(0,0.25,0))
	bone("neck","chest",Vector3(0,0.19,0))
	bone("head","neck",Vector3(0,0.12,0))
	box("pelvis",Vector3(0.35,0.2,0.24),Vector3.ZERO,cloth)
	box("spine",Vector3(0.34,0.27,0.23),Vector3(0,0.04,0),cloth)
	box("chest",Vector3(0.45,0.3,0.27),Vector3(0,-0.015,0),cloth)
	box("chest",Vector3(0.37,0.29,0.09),Vector3(0,-0.02,-0.17),armor)
	box("chest",Vector3(0.31,0.34,0.15),Vector3(0,-0.02,0.19),dark)
	for x in [-0.13,0.0,0.13]:
		box("chest",Vector3(0.10,0.14,0.055),Vector3(x,-0.11,-0.23),dark)
		box("chest",Vector3(0.075,0.018,0.06),Vector3(x,-0.055,-0.23),armor)
	for x in [-0.155,0.155]:
		box("chest",Vector3(0.05,0.32,0.025),Vector3(x,0.015,-0.225),dark)
	box("chest",Vector3(0.10,0.055,0.015),Vector3(0,0.07,-0.228),accent)
	box("chest",Vector3(0.035,0.22,0.035),Vector3(0.17,0.22,0.17),dark)
	box("pelvis",Vector3(0.39,0.055,0.27),Vector3(0,0.06,0),dark)
	box("pelvis",Vector3(0.08,0.06,0.04),Vector3(0,0.06,-0.15),armor)
	box("neck",Vector3(0.11,0.13,0.12),Vector3(0,0.01,0),dark)
	head = attachments.head
	var helmet := SphereMesh.new()
	helmet.radius = 0.15
	helmet.height = 0.30
	helmet.radial_segments = 16
	helmet.rings = 8
	mesh("head",helmet,Vector3.ZERO,cloth)
	box("head",Vector3(0.25,0.115,0.09),Vector3(0,0.015,-0.125),dark)
	box("head",Vector3(0.215,0.075,0.018),Vector3(0,0.022,-0.178),glass)
	box("head",Vector3(0.20,0.09,0.085),Vector3(0,-0.083,-0.10),dark)
	box("head",Vector3(0.08,0.045,0.09),Vector3(0,0.145,-0.005),armor)
	for side in [-1.0,1.0]:
		var suffix := "l" if side<0 else "r"
		bone("upper_arm_"+suffix,"chest",Vector3(side*0.27,0.065,0))
		bone("forearm_"+suffix,"upper_arm_"+suffix,Vector3(0,-0.29,0))
		bone("hand_"+suffix,"forearm_"+suffix,Vector3(0,-0.25,0))
		bone("thigh_"+suffix,"pelvis",Vector3(side*0.13,-0.04,0))
		bone("shin_"+suffix,"thigh_"+suffix,Vector3(0,-0.43,0))
		bone("foot_"+suffix,"shin_"+suffix,Vector3(0,-0.40,0))
		box("upper_arm_"+suffix,Vector3(0.16,0.27,0.17),Vector3(0,-0.125,0),cloth)
		box("upper_arm_"+suffix,Vector3(0.19,0.14,0.20),Vector3(0,-0.025,0),armor)
		box("upper_arm_"+suffix,Vector3(0.018,0.055,0.10),Vector3(side*0.103,-0.035,0),accent)
		box("forearm_"+suffix,Vector3(0.13,0.23,0.14),Vector3(0,-0.115,0),cloth)
		box("forearm_"+suffix,Vector3(0.14,0.08,0.15),Vector3(0,-0.19,0),dark)
		box("hand_"+suffix,Vector3(0.115,0.105,0.13),Vector3(0,-0.045,-0.012),dark)
		box("thigh_"+suffix,Vector3(0.19,0.40,0.21),Vector3(0,-0.21,0),cloth)
		box("thigh_"+suffix,Vector3(0.07,0.18,0.15),Vector3(side*0.105,-0.19,0),armor)
		box("shin_"+suffix,Vector3(0.155,0.35,0.17),Vector3(0,-0.17,0),cloth)
		box("shin_"+suffix,Vector3(0.16,0.14,0.06),Vector3(0,-0.025,-0.105),armor)
		box("foot_"+suffix,Vector3(0.18,0.15,0.31),Vector3(0,0.005,-0.065),dark)
		box("head",Vector3(0.055,0.12,0.10),Vector3(side*0.15,-0.015,0.01),armor)
	# Small wrist display is provisional equipment, not a functional weapon.
	box("forearm_l",Vector3(0.15,0.065,0.12),Vector3(0,-0.16,-0.07),dark)
	box("forearm_l",Vector3(0.10,0.035,0.01),Vector3(0,-0.16,-0.137),accent)

func material(color: Color,metallic: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metallic
	result.roughness = 0.65
	return result

func bone(label: String,parent: String,offset: Vector3) -> void:
	var index := skeleton.get_bone_count()
	skeleton.add_bone(label)
	bones[label] = index
	if not parent.is_empty(): skeleton.set_bone_parent(index,bones[parent])
	skeleton.set_bone_rest(index,Transform3D(Basis.IDENTITY,offset))
	skeleton.reset_bone_pose(index)
	var attachment := BoneAttachment3D.new()
	attachment.name = label
	skeleton.add_child(attachment)
	attachment.bone_name = label
	attachments[label] = attachment

func mesh(label: String,shape: Mesh,offset: Vector3,surface: Material) -> void:
	var visual := MeshInstance3D.new()
	visual.mesh = shape
	visual.material_override = surface
	visual.position = offset
	attachments[label].add_child(visual)

func box(label: String,size: Vector3,offset: Vector3,surface: Material) -> void:
	var shape := BoxMesh.new()
	shape.size = size
	mesh(label,shape,offset,surface)

func pose(label: String,angles: Vector3) -> void:
	skeleton.set_bone_pose_rotation(bones[label],Quaternion.from_euler(angles))

func set_local_first_person(enabled: bool) -> void:
	if head != null: head.visible = not enabled

func animate(body: CharacterBody3D,command: RefCounted,delta: float) -> void:
	var speed: float = body.movement.locomotion_speed
	var grounded := body.is_on_floor()
	var target_weight := clampf(speed/2.2,0,1) if grounded else 0.0
	gait_weight = move_toward(gait_weight,target_weight,delta*9)
	crouch_weight = move_toward(crouch_weight,1.0 if body.movement.crouched else 0.0,delta*7)
	# Phase follows horizontal distance, so a blocked soldier stops stepping.
	phase = fposmod(phase+speed*delta*TAU/(1.65 if speed>4.8 else 1.25),TAU)
	var stride := sin(phase)*gait_weight
	var sideways: float = command.move.x*gait_weight
	skeleton.set_bone_pose_position(bones.pelvis,Vector3(0,0.94-0.52*crouch_weight+absf(sin(phase))*0.025*gait_weight,0))
	pose("pelvis",Vector3(0.08*crouch_weight,0,-sideways*0.035))
	pose("spine",Vector3(0.15*crouch_weight,0,-sideways*0.025))
	pose("chest",Vector3(-0.09*crouch_weight,0,0))
	pose("head",Vector3(body.view.pitch*0.30,0,0))
	for side in [-1.0,1.0]:
		var suffix := "l" if side<0 else "r"
		var swing: float = stride*side
		var forward_sign := -1.0 if command.move.y>0 else 1.0
		pose("thigh_"+suffix,Vector3(swing*0.55*forward_sign+0.95*crouch_weight+(0.30 if not grounded else 0.0),0,-sideways*0.10))
		pose("shin_"+suffix,Vector3(-maxf(0,-swing)*0.75-1.40*crouch_weight-(0.40 if not grounded else 0.0),0,0))
		pose("foot_"+suffix,Vector3(0.40*crouch_weight,0,0))
		pose("upper_arm_"+suffix,Vector3(-swing*0.30+0.18+0.18*crouch_weight,0,-side*0.10))
		pose("forearm_"+suffix,Vector3(0.25+absf(swing)*0.18,0,0))

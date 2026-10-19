@tool
extends RefCounted
## Shared-building equipment stays outside the measured entrance and U-stair route.
var g:Node3D
var wood:Material
var steel:Material
var white:Material
var dark:Material
var fabric:Material
var screen:Material
var mirror:Material
var red:Material
var manifest:Dictionary={}

func item(parent:Node3D,label:String,kind:String,at:Vector3)->Node3D:
	var node:Node3D=g.category(parent,label);node.position=at;node.set_meta("facility_kind",kind)
	manifest[kind]=int(manifest.get(kind,0))+1
	return node
func box(parent:Node3D,size:Vector3,at:Vector3,mat:Material)->void:
	g.detail(parent,size,at,mat)
func solid(parent:Node3D,label:String,size:Vector3,at:Vector3,mat:Material)->Node3D:
	return g.part(parent,label,size,at,mat)
func round_part(parent:Node3D,label:String,radius:float,height:float,at:Vector3,mat:Material)->MeshInstance3D:
	var mesh:=MeshInstance3D.new();mesh.name=label
	var shape:=CylinderMesh.new();shape.top_radius=radius;shape.bottom_radius=radius;shape.height=height;shape.radial_segments=16
	mesh.mesh=shape;mesh.material_override=mat;parent.add_child(mesh);mesh.position=at
	return mesh
func basin(parent:Node3D)->void:
	var rim:=MeshInstance3D.new();var ring:=TorusMesh.new();ring.inner_radius=.18;ring.outer_radius=.25;ring.rings=24;ring.ring_segments=12
	rim.mesh=ring;rim.material_override=white;rim.position=Vector3(0,.875,0);rim.scale=Vector3(1.1,1,.80);parent.add_child(rim)
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(8):
		for col in range(24):
			var corners:Array[Vector3]=[]
			for pair in [[row,col],[row+1,col],[row+1,col+1],[row,col+1]]:
				var angle:float=float(pair[0])/8*PI/2;var azimuth:float=float(pair[1])/24*TAU
				corners.append(Vector3(cos(azimuth)*sin(angle)*.205,-cos(angle)*.08,sin(azimuth)*sin(angle)*.148))
			for index in [0,1,2,0,2,3]:surface.set_normal(Vector3(-corners[index].x*2,1,-corners[index].z*2).normalized());surface.add_vertex(corners[index])
	var bowl:=MeshInstance3D.new();bowl.name="RecessedBasin";bowl.mesh=surface.commit();bowl.material_override=white;bowl.position=Vector3(0,.875,0);parent.add_child(bowl)
func placard(parent:Node3D,text:String,at:Vector3,yaw:=0.0,size:=22)->void:
	var label:=Label3D.new();label.text=text;label.font_size=size;label.pixel_size=.006
	label.position=at;label.rotation.y=yaw;label.modulate=Color("e2ebe8");parent.add_child(label)
func chair(parent:Node3D,at:Vector3,yaw:=0.0)->void:
	var node:Node3D=item(parent,"ErgonomicChair","ergonomic_chair",at);node.rotation.y=yaw
	solid(node,"UpholsteredSeat",Vector3(.53,.13,.52),Vector3(0,.48,0),fabric)
	box(node,Vector3(.51,.50,.09),Vector3(0,.77,-.22),fabric)
	box(node,Vector3(.16,.5,.08),Vector3(0,.69,-.27),steel)
	round_part(node,"LiftPiston",.045,.35,Vector3(0,.25,0),steel)
	for angle in range(5):
		var rotation:float=angle*TAU/5
		g.detail(node,Vector3(.045,.035,.30),Vector3(sin(rotation)*.14,.065,cos(rotation)*.14),steel,Vector3(0,rotation,0))
		round_part(node,"Caster",.035,.055,Vector3(sin(rotation)*.28,.035,cos(rotation)*.28),dark).rotation.z=PI/2
	for side in [-1,1]:
		box(node,Vector3(.035,.20,.035),Vector3(side*.29,.61,0),steel)
		box(node,Vector3(.08,.045,.34),Vector3(side*.29,.73,0),dark)
func monitor(parent:Node3D,at:Vector3,yaw:=0.0)->void:
	var node:Node3D=item(parent,"SecurityMonitor","control_monitor",at);node.rotation.y=yaw
	box(node,Vector3(.36,.025,.20),Vector3.ZERO,steel)
	box(node,Vector3(.045,.22,.045),Vector3(0,.12,0),steel)
	box(node,Vector3(.60,.36,.065),Vector3(0,.35,0),dark)
	box(node,Vector3(.55,.30,.008),Vector3(0,.35,.037),screen)
	for row in range(3):
		for col in range(2):
			box(node,Vector3(.22,.075,.009),Vector3(-.14+col*.28,.25+row*.10,.044),steel)
	box(node,Vector3(.40,.025,.15),Vector3(0,.02,.23),dark)
func couch(parent:Node3D,at:Vector3,yaw:=0.0)->void:
	var node:Node3D=item(parent,"WaitingSofa","waiting_sofa",at);node.rotation.y=yaw
	solid(node,"Seat",Vector3(1.70,.31,.72),Vector3(0,.37,0),fabric)
	box(node,Vector3(1.7,.56,.14),Vector3(0,.64,-.30),fabric)
	for x in [-.81,.81]:
		box(node,Vector3(.16,.38,.76),Vector3(x,.55,0),fabric)
	for x in [-.60,0,.60]:box(node,Vector3(.015,.01,.58),Vector3(x,.535,0),dark)
	for x in [-.65,.65]:
		for z in [-.22,.22]:box(node,Vector3(.06,.22,.06),Vector3(x,.11,z),steel)
func waste(parent:Node3D,at:Vector3,recycle:bool)->void:
	var node:Node3D=item(parent,"RecyclingBin" if recycle else "WasteBin","recycling_bin" if recycle else "waste_bin",at)
	solid(node,"BinBody",Vector3(.32,.52,.30),Vector3(0,.26,0),steel)
	var color:Material=g.material("recycle_blue" if recycle else "waste_grey",Color("307d9e") if recycle else Color("64716c"))
	box(node,Vector3(.35,.055,.33),Vector3(0,.54,0),color)
	box(node,Vector3(.18,.02,.12),Vector3(0,.573,0),dark)
	placard(node,"RECICLA" if recycle else "RESIDUOS",Vector3(0,.34,.156),0,11)
func mirror_panel(parent:Node3D,at:Vector3,yaw:=0.0,bathroom:=false)->void:
	var node:Node3D=item(parent,"BathroomMirror" if bathroom else "LobbyMirror","bathroom_mirror" if bathroom else "security_mirror",at);node.rotation.y=yaw
	box(node,Vector3(.82,1.0,.045),Vector3.ZERO,steel)
	box(node,Vector3(.75,.93,.012),Vector3(0,0,.029),mirror)
func cctv(parent:Node3D,at:Vector3,yaw:float)->void:
	var node:Node3D=item(parent,"CCTVCamera","cctv",at);node.rotation.y=yaw
	box(node,Vector3(.10,.10,.12),Vector3.ZERO,steel)
	box(node,Vector3(.035,.035,.28),Vector3(0,0,.18),steel)
	box(node,Vector3(.18,.14,.33),Vector3(0,-.08,.35),white)
	round_part(node,"OpticalLens",.048,.015,Vector3(0,-.08,.524),dark).rotation.x=PI/2
	box(node,Vector3(.02,.02,.01),Vector3(.065,-.06,.524),screen)
func locker_bank(parent:Node3D,at:Vector3,count:int,mail:=false)->void:
	var node:Node3D=item(parent,"Mailboxes" if mail else "StaffLockers","mailboxes" if mail else "staff_lockers",at)
	var width:float=.40*count;var height:float=1.1 if mail else 1.75
	solid(node,"MetalCabinet",Vector3(width,height,.32),Vector3(0,height/2,0),steel)
	for col in range(count):
		for row in range(3 if mail else 1):
			var hh:float=.32 if mail else 1.62
			var yy:float=.21+row*.35 if mail else .90
			var xx:float=(col-(count-1)*.5)*.40
			box(node,Vector3(.37,hh,.025),Vector3(xx,yy,.172),white)
			box(node,Vector3(.08,.02,.016),Vector3(xx+.10,yy,.191),dark)
			if mail:box(node,Vector3(.24,.018,.02),Vector3(xx,yy+.10,.192),dark)
func bathroom(parent:Node3D,y:float)->void:
	var room:Node3D=item(parent,"PublicStaffBathroom","bathroom",Vector3(5.45,y,-3.8))
	# Side gallery, beyond the outer stair rail. A human-width door stays open.
	var partition:Material=g.material("facility_partition",Color("d1d5ca"),"plaster",1.2)
	solid(room,"Partition",Vector3(.10,2.55,3.7),Vector3(-1.02,1.275,.1),partition)
	solid(room,"VanityWall",Vector3(1.05,2.3,.10),Vector3(.53,1.15,-.08),partition)
	solid(room,"RearPrivacyWall",Vector3(2.0,2.55,.10),Vector3(0,1.275,-1.80),partition)
	for x in [-.78,.78]:solid(room,"DoorJamb",Vector3(.42,2.3,.10),Vector3(x,1.15,2.0),partition)
	solid(room,"DoorLintel",Vector3(2.0,.30,.10),Vector3(0,2.45,2.0),partition)
	placard(room,"BAÑOS / PERSONAL",Vector3(0,2.43,2.06),0,15)
	var vanity:Node3D=item(room,"VanityWashbasin","washbasin",Vector3(.40,0,.55))
	solid(vanity,"Cabinet",Vector3(.74,.79,.56),Vector3(0,.395,0),wood)
	for side in [-1,1]:
		box(vanity,Vector3(.82,.07,.15),Vector3(0,.84,side*.245),white)
		box(vanity,Vector3(.17,.07,.34),Vector3(side*.325,.84,0),white)
	basin(vanity)
	box(vanity,Vector3(.035,.23,.035),Vector3(0,1.0,-.20),steel)
	box(vanity,Vector3(.035,.035,.17),Vector3(0,1.105,-.13),steel)
	mirror_panel(room,Vector3(.47,1.65,-.02),0,true)
	for entry in [["SoapDispenser","soap_dispenser",Vector3(.83,1.1,.10),Vector3(.13,.23,.12)], ["PaperTowelDispenser","paper_towel_dispenser",Vector3(1.0,1.55,1.0),Vector3(.20,.29,.20)], ["HandDryer","hand_dryer",Vector3(1.0,1.05,1.55),Vector3(.20,.25,.20)]]:
		var unit:Node3D=item(room,entry[0],entry[1],entry[2]);box(unit,entry[3],Vector3.ZERO,white)
		if entry[1]!="soap_dispenser":unit.rotation.y=-PI/2
		box(unit,Vector3(.08,.025,.03),Vector3(0,-.10,.115),dark)
	var wc:Node3D=item(room,"Toilet","toilet",Vector3(-.1,0,-1.0))
	solid(wc,"PorcelainBase",Vector3(.45,.42,.65),Vector3(0,.21,0),white)
	round_part(wc,"SeatRim",.26,.07,Vector3(0,.46,.05),white)
	box(wc,Vector3(.46,.55,.16),Vector3(0,.62,-.30),white)
	locker_bank(parent,Vector3(-5.5,y,-4.9),3)
func build(generator:Node3D,parent:Node3D,level:int,front:float)->void:
	g=generator;manifest={}
	wood=g.material("facility_oak",Color("8d6b46"),"wood",1.1)
	steel=g.material("facility_steel",Color("445251"));steel.metallic=.68;steel.roughness=.34
	white=g.material("facility_porcelain",Color("e9e8df"));white.roughness=.22
	dark=g.material("facility_dark",Color("172324"));fabric=g.material("facility_fabric",Color("5f7d76"),"plaster",2.5)
	screen=g.material("facility_lcd",Color("4dbaa8"));screen.emission_enabled=true;screen.emission=Color("278477");screen.emission_energy_multiplier=.5
	mirror=g.material("facility_mirror",Color("d5e0df"));mirror.metallic=.97;mirror.roughness=.035
	red=g.material("facility_safety_red",Color("ac4037"))
	var y:float=level*3.6
	var zone:Node3D=g.category(parent,"BuildingFacilities_"+str(level))
	if level==0:
		var desk:Node3D=item(zone,"ConciergeDesk","reception_desk",Vector3(-4.75,y,3.8))
		solid(desk,"Cabinet",Vector3(2.65,1.02,.78),Vector3(0,.51,0),wood)
		box(desk,Vector3(2.8,.08,.94),Vector3(0,1.06,0),white)
		for x in [-.95,0,.95]:box(desk,Vector3(.025,.75,.025),Vector3(x,.48,.405),steel)
		placard(desk,"CONSERJERÍA",Vector3(0,.64,.409),0,25)
		monitor(desk,Vector3(-.48,1.11,0));monitor(desk,Vector3(.40,1.11,0))
		chair(zone,Vector3(-4.75,y,2.6))
		couch(zone,Vector3(5.55,y,3.5),-PI/2)
		var table:Node3D=item(zone,"CoffeeTable","coffee_table",Vector3(4.20,y,3.5))
		solid(table,"TableTop",Vector3(.70,.10,1.1),Vector3(0,.45,0),wood)
		for x in [-.24,.24]:
			for z in [-.42,.42]:box(table,Vector3(.055,.42,.055),Vector3(x,.21,z),steel)
		locker_bank(zone,Vector3(-5.1,y,5.85),4,true)
		mirror_panel(zone,Vector3(6.525,y+1.60,5.5),-PI/2)
		for x in [-6.0,6.0]:g.plant(zone,Vector3(x,y+.02,front-.6),level)
		manifest["decorative_planter"]=2
		var gate:Node3D=item(zone,"PedestrianTurnstile","pedestrian_turnstile",Vector3(3.0,y,5.9))
		solid(gate,"Pedestal",Vector3(.30,1.0,.42),Vector3(0,.5,0),steel)
		for angle in range(3):g.detail(gate,Vector3(.60,.04,.04),Vector3(.34,.95,0),steel,Vector3(angle*TAU/3,0,0))
	else:
		var bench:Node3D=item(zone,"CorridorBench","rest_bench",Vector3(-5.25,y,2.7))
		solid(bench,"BenchSeat",Vector3(1.65,.12,.55),Vector3(0,.46,0),wood)
		for x in [-.62,.62]:box(bench,Vector3(.08,.44,.40),Vector3(x,.22,0),steel)
		box(bench,Vector3(1.65,.38,.07),Vector3(0,.72,-.25),wood)
		g.plant(zone,Vector3(5.75,y+.02,2.9),level)
		manifest["decorative_planter"]=1
	cctv(zone,Vector3(-6.48,y+2.75,front-.35),PI*.30)
	var fire:Node3D=item(zone,"ExtinguisherCabinet","extinguisher_cabinet",Vector3(-6.43,y+1.05,1.8))
	box(fire,Vector3(.18,.75,.46),Vector3.ZERO,red)
	box(fire,Vector3(.02,.64,.35),Vector3(.10,0,0),dark)
	round_part(fire,"Extinguisher",.09,.43,Vector3(.115,-.05,0),red)
	waste(zone,Vector3(5.4,y,1.6),false);waste(zone,Vector3(5.9,y,1.6),true)
	bathroom(zone,y)
	var mat:Node3D=item(zone,"EntranceMat","entrance_mat",Vector3(0,y+.012,front-.70))
	box(mat,Vector3(3.6,.018,1.0),Vector3.ZERO,dark)
	for x in range(18):box(mat,Vector3(.025,.003,.9),Vector3(-1.7+x*.20,.011,0),steel)
	for x in [-6.49,6.49]:
		var lamp:Node3D=item(zone,"WallLuminaire","wall_luminaire",Vector3(x,y+2.4,2.0))
		lamp.rotation.y=-signf(x)*PI/2
		box(lamp,Vector3(.18,.32,.12),Vector3.ZERO,steel);box(lamp,Vector3(.13,.24,.13),Vector3(0,0,.04),white)
		var light:=OmniLight3D.new();light.name="LobbyLight";light.light_color=Color("fff0d9");light.light_energy=.7;light.omni_range=4.8;light.shadow_enabled=false
		light.position=Vector3(signf(x)*6.1,y+2.4,2.2);light.distance_fade_enabled=true;light.distance_fade_begin=28;light.distance_fade_length=8;zone.add_child(light)
	var combined:Dictionary=g.active_building.get_meta("facilities",{})
	for kind in manifest:combined[kind]=int(combined.get(kind,0))+int(manifest[kind])
	g.active_building.set_meta("facilities",combined)

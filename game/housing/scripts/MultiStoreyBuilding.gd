@tool
extends RefCounted
## Real floors and a continuous U staircase, built inside a validated 14 m envelope.
const CLEAR_HEIGHT := 3.4
const FLOOR_STEP := 3.6
const FLIGHT_WIDTH := 3.8
const FLIGHT_RUN := 3.8
const HALF_RISE := 1.8
const STEPS := 12

func build(g: Node3D,root: Node3D,b: Dictionary) -> void:
	g.active_building=root
	var style: Dictionary=b.style
	var palette: int=int(style.palette)%g.WALL_COLORS.size()
	var wall: Material=g.material("wall_"+str(palette),g.WALL_COLORS[palette],"plaster",1)
	var trim: Material=g.material("tower_trim",Color("e9e1ce"),"plaster",1.5)
	var wood: Material=g.material("tower_wood",Color("665442"),"wood",1.2)
	var floor_mat:=ShaderMaterial.new();floor_mat.shader=preload("res://shaders/interior_tiles.gdshader")
	var metal: Material=g.material("tower_rail",Color("354e48"),"plaster",1.2)
	var floors: Node3D=g.category(root,"Floors")
	var walls: Node3D=g.category(root,"Walls")
	var windows: Node3D=g.category(root,"Windows")
	var doors: Node3D=g.category(root,"Doors")
	var interiors: Node3D=g.category(root,"Interiors")
	var stairs: Node3D=g.category(root,"Stairs")
	var facade: Node3D=g.category(root,"FacadeDetails")
	var roof: Node3D=g.category(root,"Roof");roof.add_to_group("housing_roofs")
	root.set_meta("storeys",int(b.storeys));root.set_meta("storey_height",FLOOR_STEP)
	root.set_meta("robot_passage",{"width":b.door_width,"height":b.door_height,"kind":"shared_building"})
	doors.set_meta("clear_width",b.door_width);doors.set_meta("clear_height",b.door_height)
	doors.set_meta("functional","permanently open passages")
	var route: Array[Vector3]=[]
	for level in range(int(b.storeys)):
		var y: float=level*FLOOR_STEP
		var front: float=6.8 if level==0 else 4.4
		var side_length: float=front+6.8
		var slab: Node3D=g.category(floors,"Storey_"+str(level))
		if level==0:
			g.part(slab,"GroundSlab",Vector3(14,.12,14),Vector3(0,-.06,0),floor_mat)
		else:
			# Four slabs around the stair opening; no invisible floor across the stairs.
			g.part(slab,"FrontLanding",Vector3(14,.2,5.95),Vector3(0,y-.1,4.025),floor_mat)
			for sign_side in [-1.0,1.0]:
				g.part(slab,"SideGallery",Vector3(2.88,.2,8.05),Vector3(sign_side*5.56,y-.1,-2.975),floor_mat)
			g.part(slab,"BackEdge",Vector3(8.24,.2,.3),Vector3(0,y-.1,-6.85),floor_mat)
			upper_guards(g,slab,y,level==int(b.storeys)-1,metal)
			balcony(g,facade,y,metal,wood,palette)
		var storey: Node3D=g.category(walls,"Storey_"+str(level))
		var front_holes: Array=[{"x":0.0,"width":b.door_width,"bottom":0.0,"height":b.door_height,"kind":"door"}]
		for x in [-4.42,4.42]:front_holes.append(hole(x))
		g.wall_with_openings(storey,windows,"L%dFront"%level,Vector3(0,y,front-.125),0,13.6,CLEAR_HEIGHT,front_holes,wall,trim,wood,style)
		var back_holes: Array=[hole(-4.4),hole(0),hole(4.4)]
		g.wall_with_openings(storey,windows,"L%dBack"%level,Vector3(0,y,-6.675),PI,13.6,CLEAR_HEIGHT,back_holes,wall,trim,wood,style)
		var side_holes: Array=[hole(-side_length*.3),hole(0),hole(side_length*.3)]
		g.wall_with_openings(storey,windows,"L%dLeft"%level,Vector3(-6.675,y,(front-6.8)/2),-PI/2,side_length,CLEAR_HEIGHT,side_holes,wall,trim,wood,style)
		g.wall_with_openings(storey,windows,"L%dRight"%level,Vector3(6.675,y,(front-6.8)/2),PI/2,side_length,CLEAR_HEIGHT,side_holes,wall,trim,wood,style)
		for x in [-6.65,6.65]:
			g.detail(facade,Vector3(.18,CLEAR_HEIGHT,.18),Vector3(x,y+CLEAR_HEIGHT/2,front-.02),trim)
			g.detail(facade,Vector3(.18,CLEAR_HEIGHT,.18),Vector3(x,y+CLEAR_HEIGHT/2,-6.65),trim)
		for x in [-6.82,6.82]:g.detail(facade,Vector3(.18,.24,13.5),Vector3(x,y-.04,0),trim)
		g.detail(facade,Vector3(13.65,.24,.18),Vector3(0,y-.04,-6.82),trim)
		g.detail(facade,Vector3(13.65,.24,.18),Vector3(0,y-.04,6.82),trim)
		var room: Node3D=g.category(interiors,"Storey_"+str(level))
		if level<int(b.storeys)-1:
			staircase(g,stairs,y,metal,wood)
			route.append_array([Vector3(-2.1,y+.025,2.5),Vector3(-2.1,y+HALF_RISE+.025,-4.15),Vector3(2.1,y+HALF_RISE+.025,-4.15),Vector3(2.1,y+FLOOR_STEP+.025,2.5)])
		preload("res://housing/scripts/BuildingFacilities.gd").new().build(g,room,level,front)
		var threshold: Node3D=g.part(doors,"Threshold" if level==0 else "UpperThreshold",Vector3(b.door_width,.035,.32),Vector3(0,y-.0175,front-.06),floor_mat)
		threshold.set_meta("storey",level)
		g.detail(doors,Vector3(b.door_width+.24,.12,.16),Vector3(0,y+b.door_height+.06,front+.03),wood)
	var ramps: Node3D=g.category(root,"Ramps")
	var ramp: Node3D=g.part(ramps,"EntranceRamp",Vector3(b.door_width,.08,1.2),Vector3(0,-.10,7.6),floor_mat)
	ramp.rotation.x=atan2(.12,1.2)
	g.part(roof,"Ceiling",Vector3(14,.22,14),Vector3(0,b.height+.11,0),trim)
	g.build_roof(roof,14,14,b.height,style,int(style.roof_palette),wall,trim,false)
	var sign_node:=Label3D.new();sign_node.name="BuildingSign"
	sign_node.text="%s · %d PLANTAS"%[["AURORA","ALAMEDA","MIRADOR","LOS TILOS"][int(style.sign)%4],int(b.storeys)]
	sign_node.font_size=48;sign_node.pixel_size=.006;sign_node.position=Vector3(0,3.34,6.85);sign_node.modulate=Color("f5e7c9");facade.add_child(sign_node)
	root.set_meta("stair_route",route);root.set_meta("architecture_revision",g.REVISION);root.set_meta("style",style)
	root.set_meta("window_count",windows.get_child_count())
	g.finish_build(root)

func hole(x: float) -> Dictionary:
	return {"x":x,"width":1.7,"bottom":1.0,"height":1.6,"kind":"window"}

func staircase(g: Node3D,parent: Node3D,y: float,metal: Material,wood: Material) -> void:
	var group: Node3D=g.category(parent,"From_"+str(int(round(y/FLOOR_STEP))))
	for flight in range(2):
		var x: float=-2.1 if flight==0 else 2.1
		# Bodies use a continuous slope; foot IK uses the exact visible treads.
		var start_y: float=y+flight*HALF_RISE
		var start_z: float=1.0 if flight==0 else -2.8
		var end_z: float=-2.8 if flight==0 else 1.0
		var face: Array[Vector3]=[Vector3(x-1.9,start_y,start_z),Vector3(x-1.9,start_y+HALF_RISE,end_z),Vector3(x-1.9,start_y+HALF_RISE-.15,end_z),Vector3(x-1.9,start_y-.15,start_z)]
		g.prism(group,"WalkableFlight",face,Vector3(FLIGHT_WIDTH,0,0),wood)
		for step in range(1,STEPS+1):
			var rise: float=HALF_RISE*step/STEPS
			var z: float=1.0-FLIGHT_RUN*(step-.5)/STEPS if flight==0 else -2.8+FLIGHT_RUN*(step-.5)/STEPS
			var top: float=y+rise+(0.0 if flight==0 else HALF_RISE)
			var tread: StaticBody3D=g.part(group,"Tread",Vector3(FLIGHT_WIDTH,.15,FLIGHT_RUN/STEPS+.002),Vector3(x,top-.075,z),wood)
			tread.collision_layer=512
			g.detail(group,Vector3(FLIGHT_WIDTH,.035,.05),Vector3(x,top+.012,z+(.13 if flight==0 else -.13)),metal)
		var angle: float=atan2(HALF_RISE,FLIGHT_RUN)*(1 if flight==0 else -1)
		for edge in [-1.0,1.0]:
			var rail: Node3D=g.part(group,"FlightRail",Vector3(.08,1.0,sqrt(FLIGHT_RUN*FLIGHT_RUN+HALF_RISE*HALF_RISE)),Vector3(x+edge*1.94,y+.90+.55+flight*HALF_RISE,-.9),metal)
			rail.rotation.x=angle
	g.part(group,"TurnLanding",Vector3(8.0,.2,3.8),Vector3(0,y+HALF_RISE-.1,-4.7),wood)
	g.part(group,"BackGuard",Vector3(8.0,1.05,.08),Vector3(0,y+HALF_RISE+.525,-6.63),metal)

func upper_guards(g: Node3D,parent: Node3D,y: float,last: bool,metal: Material) -> void:
	for x in [-4.16,4.16]:g.part(parent,"ShaftSideRail",Vector3(.08,1.05,7.7),Vector3(x,y+.525,-2.8),metal)
	g.part(parent,"ShaftBackRail",Vector3(8.3,1.05,.08),Vector3(0,y+.525,-6.7),metal)
	g.part(parent,"FrontCentreRail",Vector3(.3,1.05,.08),Vector3(0,y+.525,1.04),metal)
	if last:g.part(parent,"ClosedTopFlight",Vector3(3.9,1.05,.08),Vector3(-2.1,y+.525,1.04),metal)

func balcony(g: Node3D,parent: Node3D,y: float,metal: Material,wood: Material,palette: int) -> void:
	var group: Node3D=g.category(parent,"Balcony_"+str(int(round(y/FLOOR_STEP))))
	g.part(group,"FrontRail",Vector3(13.5,1.05,.08),Vector3(0,y+.525,6.8),metal)
	for x in [-6.7,6.7]:g.part(group,"SideRail",Vector3(.08,1.05,2.4),Vector3(x,y+.525,5.6),metal)
	for x in [-5.5,5.5]:g.plant(group,Vector3(x,y+.02,5.75),palette)
	g.detail(group,Vector3(13.6,.09,.13),Vector3(0,y+1.08,6.8),wood)

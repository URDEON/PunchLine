extends Node3D
## Hollow ISO containers and an authoritative, operable rail gantry inside Parking_00.
const CRANE_X:=-74.6
const FLOOR_Y:=.025
var map:Node3D
var game:Node3D
var containers:Array[AnimatableBody3D]=[]
var batches:Dictionary={}
var materials:Dictionary={}
var unit_box:BoxMesh
var crane:AnimatableBody3D
var trolley:Node3D
var spreader:Node3D
var cables:Array[MeshInstance3D]=[]
var console:=Vector3(-57.5,.025,-96)
var operator:=0
var gantry_z:=-96.0
var trolley_x:=0.0
var hook_height:=3.0
var load_index:=-1
var control_axis:=Vector3.ZERO
var last_input:=0.0
var send_time:=0.0
var control_send_time:=0.0
var replica_state:Dictionary={}
var panel:CanvasLayer
var notice:Label
var crane_camera:Camera3D
var captured:=false
var hook_mesh:MeshInstance3D
var initial_positions:Array[Vector3]=[]

func online()->bool:return "session" in game and game.session!=null and game.session.active
func authority()->bool:return not online() or game.session.is_host()
func local_id()->int:return game.session.local_id() if online() else 1
func actor(id:int)->Node3D:
	if "session" in game:return game.session.actors.get(id) if game.session!=null else null
	return game if id==1 else null
func paint(key:String,color:Color,metallic:=.65)->StandardMaterial3D:
	if not materials.has(key):
		var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.metallic=metallic;mat.roughness=.55
		materials[key]=mat
	return materials[key]
func piece(parent:Node3D,label:String,size:Vector3,at:Vector3,mat:Material,physical:=false,yaw:=0.0)->void:
	var key:String=str(parent.get_instance_id())+":"+str(mat.get_instance_id())
	if not batches.has(key):batches[key]={"parent":parent,"material":mat,"poses":[]}
	batches[key].poses.append(Transform3D(Basis(Vector3.UP,yaw).scaled(size),at))
	if physical:
		var col:=CollisionShape3D.new();col.name=label;var shape:=BoxShape3D.new();shape.size=size
		col.shape=shape;col.position=at;col.rotation.y=yaw;parent.add_child(col)
func flush()->void:
	for data in batches.values():
		var visual:=MultiMeshInstance3D.new();visual.name="CargoGeometry"
		var instances:=preload("res://housing/scripts/BakedMultiMesh.gd").new();instances.transform_format=MultiMesh.TRANSFORM_3D
		instances.mesh=unit_box;instances.instance_count=data.poses.size()
		instances.source_transforms.assign(data.poses);visual.multimesh=instances;visual.material_override=data.material
		data.parent.add_child(visual);instances.upload()
	batches.clear()
func setup(owner_map:Node3D)->void:
	map=owner_map;game=map.game;name="CargoYard";unit_box=BoxMesh.new();unit_box.size=Vector3.ONE
	build_fence();build_containers();build_crane();build_terminal();flush()
	for body in containers:initial_positions.append(body.position)
	set_meta("container_count",containers.size());set_meta("source_polygon","Parking_00")
func build_fence()->void:
	var root:=StaticBody3D.new();root.name="YardPerimeter";add_child(root)
	var steel:=paint("fence",Color("465652"));var safety:=paint("safety",Color("cfa34d"))
	var wire:=ShaderMaterial.new();wire.shader=preload("res://shaders/cargo_fence.gdshader")
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/vector_meshes.json"))
	for feature in data.features:
		if feature.layer!="Parking":continue
		var ring:Array=feature.rings[0]
		for i in range(ring.size()-1):
			var a:=Vector3(ring[i][0],FLOOR_Y,ring[i][1]);var b:=Vector3(ring[i+1][0],FLOOR_Y,ring[i+1][1])
			var length:float=a.distance_to(b);var segments:int=maxi(1,ceili(length/3.0))
			var yaw:float=atan2((b-a).x,(b-a).z)
			for j in range(segments):
				var center:Vector3=a.lerp(b,(j+.5)/segments)
				# Vehicle gates connect the yard to the existing eastern/southern roads.
				if (center.x>-21 and absf(center.z+24.4)<8) or (center.z>63 and absf(center.x+65)<8):continue
				piece(root,"FencePost",Vector3(.10,2.7,.10),a.lerp(b,float(j)/segments)+Vector3.UP*1.35,steel,true)
				piece(root,"WirePanel",Vector3(.045,2.35,length/segments),center+Vector3.UP*1.35,wire,true,yaw)
				for height in [.22,2.51]:piece(root,"FenceRail",Vector3(.06,.07,length/segments),center+Vector3.UP*height,steel,false,yaw)
	for gate in [Vector3(-20.4,FLOOR_Y,-24.4),Vector3(-65,FLOOR_Y,64)]:
		for side in [-1,1]:piece(root,"GateBollard",Vector3(.22,1.2,.22),gate+Vector3(0,.60,side*7.5) if gate.x>-21 else gate+Vector3(side*7.5,.60,0),safety,true)
func container(at:Vector3,length:float,color:Color,opened:bool,contents:bool,index:int)->AnimatableBody3D:
	var body:=AnimatableBody3D.new();body.name="Container_%02d"%index;body.sync_to_physics=false
	body.collision_layer=1;body.collision_mask=1;add_child(body);body.position=at
	body.set_meta("length",length);body.set_meta("open",opened);body.set_meta("hollow",true)
	var coating:=ShaderMaterial.new();coating.shader=preload("res://shaders/shipping_steel.gdshader");coating.set_shader_parameter("paint_color",color)
	var steel:=paint("corner_castings",Color("69706a"));var timber:=paint("cargo_plywood",Color("887052"),0)
	piece(body,"WalkableFloor",Vector3(2.44,.12,length),Vector3(0,.06,0),timber,true)
	piece(body,"Roof",Vector3(2.44,.10,length),Vector3(0,2.54,0),coating,true)
	for side in [-1,1]:
		piece(body,"SideWall",Vector3(.075,2.44,length),Vector3(side*1.1825,1.30,0),coating,true)
		for z in [-length/2,length/2]:
			piece(body,"CornerPost",Vector3(.14,2.59,.14),Vector3(side*1.15,1.295,z-side*.01),steel)
		for y in [.18,2.47]:piece(body,"SideRail",Vector3(.12,.12,length),Vector3(side*1.20,y,0),steel)
		for rib in range(int(length/.28)):
			piece(body,"Corrugation",Vector3(.028,2.18,.045),Vector3(side*1.227,1.32,-length/2+.20+rib*.28),coating)
	piece(body,"BackWall",Vector3(2.30,2.44,.075),Vector3(0,1.30,-length/2+.0375),coating,true)
	for side in [-1,1]:
		var angle:float=-side*2.05 if opened else 0.0
		var hinge:=Vector3(side*1.17,0,length/2)
		var center:Vector3=hinge+Basis(Vector3.UP,angle)*Vector3(-side*.575,1.30,0)
		piece(body,"DoorLeaf",Vector3(1.15,2.44,.075),center,coating,true,angle)
		for bar in [-.32,.32]:piece(body,"DoorLockRod",Vector3(.035,2.18,.035),center+Basis(Vector3.UP,angle)*Vector3(bar,0,.06),steel,false,angle)
	if contents:
		piece(body,"Pallet",Vector3(1.15,.12,1.55),Vector3(0,.19,-length/2+1.1),timber,true)
		for x in [-.32,.32]:
			for level in range(2):
				piece(body,"CargoCrate",Vector3(.58,.60,.66),Vector3(x,.55+level*.60,-length/2+1.1),timber,true)
				for band in [-.20,.20]:piece(body,"CrateStrap",Vector3(.018,.62,.68),Vector3(x+band,.55+level*.60,-length/2+1.1),steel)
	containers.append(body);return body
func build_containers()->void:
	var rng:=RandomNumberGenerator.new();rng.seed=(String(map.world_settings.seed)+"cargo").sha256_text().substr(0,12).hex_to_int()
	var colors:Array[Color]=[Color("9c4438"),Color("3c687e"),Color("52705c"),Color("b68d43"),Color("8e9390"),Color("3e7d7e")]
	var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://housing/data/vector_meshes.json"))
	for x in [-114.0,-100.0,-82.0,-67.0,-49.0,-34.0]:
		for z in [-96.0,-77.0,-43.0,-10.0,38.0]:
			var point:=Vector2(x,z);var clear:=true
			for spawn in source.spawns:
				if point.distance_to(Vector2(spawn[0],spawn[1]))<13:clear=false
			if not clear:continue
			container(Vector3(x,FLOOR_Y,z),6.06 if rng.randf()<.65 else 12.2,colors[rng.randi_range(0,colors.size()-1)],rng.randf()<.62,rng.randf()<.55,containers.size())
	# A visible load starts directly under the gantry, ready for a first lift.
	container(Vector3(CRANE_X,FLOOR_Y,-96),6.06,colors[3],false,true,containers.size())
func build_crane()->void:
	var yellow:=paint("gantry_paint",Color("d6a044"));var steel:=paint("gantry_steel",Color("394a4d"))
	var glass:=paint("gantry_glass",Color("496d78"));glass.metallic=.25;glass.roughness=.18
	var base:=StaticBody3D.new();base.name="GantryRailFoundation";add_child(base)
	for x in [-12,12]:
		piece(base,"Rail",Vector3(.18,.08,148),Vector3(CRANE_X+x,FLOOR_Y+.04,-27),steel,true)
		piece(base,"RailBed",Vector3(.55,.05,148),Vector3(CRANE_X+x,FLOOR_Y+.025,-27),yellow)
	crane=AnimatableBody3D.new();crane.name="WorkingGantry";crane.sync_to_physics=false;add_child(crane)
	for x in [-12,12]:
		for z in [-4.5,4.5]:
			piece(crane,"Leg",Vector3(.48,11.4,.48),Vector3(x,5.95,z),yellow,true)
			piece(crane,"WheelTruck",Vector3(.90,.50,2.2),Vector3(x,.33,z),steel,true)
			for y in [1.2,3.4,5.6,7.8,10.0]:piece(crane,"LegBrace",Vector3(.65,.12,.60),Vector3(x,y,z),steel)
		piece(crane,"LongitudinalBeam",Vector3(.55,.75,11),Vector3(x,11.6,0),yellow,true)
	for z in [-4.5,4.5]:piece(crane,"GantryCrossBeam",Vector3(25,.90,.70),Vector3(0,11.7,z),yellow,true)
	piece(crane,"Cabin",Vector3(1.6,1.8,1.8),Vector3(10.9,9.4,-3.2),yellow,true)
	for z in [-4.12,-2.28]:piece(crane,"CabinWindow",Vector3(1.40,.90,.03),Vector3(10.9,9.6,z),glass)
	for rung in range(23):piece(crane,"ServiceLadderRung",Vector3(.7,.035,.05),Vector3(11.65,.45+rung*.40,-4.78),steel)
	trolley=Node3D.new();trolley.name="HoistTrolley";crane.add_child(trolley)
	piece(trolley,"HoistBridge",Vector3(2.0,.65,10.4),Vector3(0,11.85,0),steel)
	piece(trolley,"Winch",Vector3(1.4,.75,1.2),Vector3(0,11.25,0),yellow)
	spreader=Node3D.new();spreader.name="ContainerSpreader";trolley.add_child(spreader)
	for z in [-2.8,2.8]:piece(spreader,"SpreaderCrossbar",Vector3(2.3,.22,.24),Vector3(0,0,z),yellow)
	for x in [-1.0,1.0]:piece(spreader,"SpreaderRail",Vector3(.16,.20,5.6),Vector3(x,0,0),steel)
	for x in [-.7,.7]:
		for z in [-2.0,2.0]:
			var cable:=MeshInstance3D.new();cable.mesh=unit_box;cable.material_override=steel;cable.position=Vector3(x,7,z);trolley.add_child(cable);cables.append(cable)
	apply_pose()
func build_terminal()->void:
	var root:=StaticBody3D.new();root.name="CraneTerminal";add_child(root);root.position=console
	var steel:=paint("terminal_steel",Color("435758"));var dark:=paint("terminal_screen",Color("316e69"))
	piece(root,"ConsoleStand",Vector3(.7,1.1,.65),Vector3(0,.55,0),steel,true)
	piece(root,"ControlScreen",Vector3(.56,.38,.08),Vector3(0,1.34,0),dark)
	var label:=Label3D.new();label.text="DESPACHO DE CARGA\nH · CONTROL DE GRÚA";label.font_size=32;label.pixel_size=.012
	root.add_child(label);label.position=Vector3(0,2.2,0);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	var mat:=paint("yard_marking",Color("cba95d"),0)
	var marking:=StaticBody3D.new();marking.name="LoadingZoneMarkings";add_child(marking)
	for z in [-105.0,-86.0]:piece(marking,"LoadingBayLine",Vector3(23,.012,.12),Vector3(CRANE_X,FLOOR_Y+.004,z),mat)
func command(id:int,action:String)->bool:
	if not authority():return false
	var pilot:Node3D=actor(id)
	if pilot==null or pilot.hp<=0:return false
	if action=="toggle":
		if operator==id:operator=0;control_axis=Vector3.ZERO;return true
		if operator!=0 or pilot.player.global_position.distance_to(console)>5:return false
		operator=id;last_input=Time.get_ticks_msec()/1000.0;return true
	if action!="grab" or operator!=id:return false
	if load_index>=0:
		if containers[load_index].position.y>FLOOR_Y+.20:return false
		load_index=-1;return true
	var target:=Vector3(CRANE_X+trolley_x,hook_height,gantry_z)
	for i in range(containers.size()):
		var roof:Vector3=containers[i].position+Vector3.UP*2.9
		if Vector2(target.x,target.z).distance_to(Vector2(roof.x,roof.z))<.8 and absf(target.y-roof.y)<.35:
			load_index=i;return true
	return false
func input_control(id:int,axis:Vector3)->void:
	if not authority() or operator!=id or not axis.is_finite():return
	control_axis=axis.clamp(-Vector3.ONE,Vector3.ONE);last_input=Time.get_ticks_msec()/1000.0
func state()->Dictionary:
	var poses:Array[Vector3]=[]
	for body in containers:poses.append(body.position)
	return {"operator":operator,"z":gantry_z,"x":trolley_x,"height":hook_height,"load":load_index,"containers":poses}
func accept(data:Dictionary)->void:replica_state=data.duplicate(true);operator=int(data.get("operator",0))
func reset_world()->void:
	operator=0;gantry_z=-96;trolley_x=0;hook_height=3;load_index=-1;control_axis=Vector3.ZERO;replica_state.clear()
	for i in range(containers.size()):containers[i].position=initial_positions[i]
	apply_pose()
func apply_pose()->void:
	crane.position=Vector3(CRANE_X,FLOOR_Y,gantry_z);trolley.position.x=trolley_x;spreader.position.y=hook_height
	var index:=0
	for cable in cables:
		var top:=10.9;var length:float=maxf(.05,top-hook_height)
		cable.position.y=(top+hook_height)/2;cable.scale=Vector3(.026,length,.026);index+=1
	if load_index>=0 and load_index<containers.size():containers[load_index].position=Vector3(CRANE_X+trolley_x,FLOOR_Y+maxf(0,hook_height-2.9),gantry_z)
func _physics_process(delta:float)->void:
	if game==null:return
	if authority():
		var pilot:Node3D=actor(operator) if operator>0 else null
		if operator>0 and (pilot==null or pilot.hp<=0 or pilot.player.global_position.distance_to(console)>7):operator=0;control_axis=Vector3.ZERO
		if Time.get_ticks_msec()/1000.0-last_input>.35:control_axis=Vector3.ZERO
		if not ("paused" in game and game.paused):
			trolley_x=clampf(trolley_x+control_axis.x*2.1*delta,-8,8)
			gantry_z=clampf(gantry_z+control_axis.z*3.0*delta,-98,42)
			hook_height=clampf(hook_height+control_axis.y*1.8*delta,2.9,10.5)
		apply_pose();send_time+=delta
		if online() and send_time>.10:
			send_time=0
			for peer in game.session.ready_peers:game.session.cargo_state.rpc_id(peer,state())
	elif not replica_state.is_empty():
		var weight:float=1-exp(-delta*16)
		gantry_z=lerpf(gantry_z,float(replica_state.z),weight);trolley_x=lerpf(trolley_x,float(replica_state.x),weight)
		hook_height=lerpf(hook_height,float(replica_state.height),weight);load_index=int(replica_state.load)
		for i in range(mini(containers.size(),replica_state.containers.size())):containers[i].position=containers[i].position.lerp(replica_state.containers[i],weight)
		apply_pose()
func local_command(action:String)->void:
	if online():game.session.local_cargo_command(action)
	else:command(1,action)
func _unhandled_input(event:InputEvent)->void:
	if game==null or ("paused" in game and game.paused) or ("menu_open" in game and game.menu_open):return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_H or event.keycode==KEY_H:local_command("toggle")
		elif operator==local_id() and (event.keycode==KEY_ENTER or event.physical_keycode==KEY_ENTER):local_command("grab");get_viewport().set_input_as_handled()
func update_panel()->void:
	var active:bool=operator==local_id() and operator>0
	if active and not captured:
		captured=true;panel=CanvasLayer.new();panel.layer=30;add_child(panel)
		notice=Label.new();notice.position=Vector2(24,140);notice.add_theme_font_size_override("font_size",18);panel.add_child(notice)
		crane_camera=Camera3D.new();add_child(crane_camera);crane_camera.current=true;crane_camera.fov=65
	elif not active and captured:
		captured=false
		if is_instance_valid(panel):panel.queue_free()
		if is_instance_valid(crane_camera):crane_camera.queue_free()
		if is_instance_valid(game.camera):game.camera.current=true
	if active:
		notice.text="GRÚA / DESPACHO\nI K: avanzar · J L: carro · U O: subir/bajar\nENTER: enganchar / soltar en el suelo · H: salir\nCarga: %s · Altura: %.1f m"%["ENGANCHADA" if load_index>=0 else "LIBRE",hook_height]
		crane_camera.global_position=Vector3(CRANE_X+19,16,gantry_z+22)
		crane_camera.look_at(Vector3(CRANE_X+trolley_x,4,gantry_z))
func _process(delta:float)->void:
	if game==null:return
	update_panel()
	if operator==local_id() and operator>0:
		control_send_time+=delta
		if control_send_time<1.0/30:return
		control_send_time=0
		var axis:=Vector3(float(Input.is_physical_key_pressed(KEY_L))-float(Input.is_physical_key_pressed(KEY_J)),float(Input.is_physical_key_pressed(KEY_U))-float(Input.is_physical_key_pressed(KEY_O)),float(Input.is_physical_key_pressed(KEY_K))-float(Input.is_physical_key_pressed(KEY_I)))
		if ("paused" in game and game.paused) or ("menu_open" in game and game.menu_open):axis=Vector3.ZERO
		if online():game.session.local_cargo_input(axis)
		else:input_control(1,axis)

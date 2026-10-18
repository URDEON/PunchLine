extends SceneTree
var checks:=0
var passed:=0
func _initialize() -> void:run.call_deferred()
func check(ok:bool,title:String)->void:
	checks+=1
	if ok:passed+=1
	print("PASS " if ok else "FAIL ",title)
func frames(n:int)->void:
	for i in range(n):await physics_frame
func run()->void:
	var arena:Node3D=load("res://network/online.tscn").instantiate();root.add_child(arena);arena.session.active=true;arena.session.server=true
	arena.session.upsert_player(1,{"id":1,"nickname":"Piloto","character":1,"variant":1,"color":0,"slot":0,"generation":0,"spawn":Vector3(-16,.1,0),"yaw":0.0})
	await frames(10)
	var host:Node3D=arena.session.actors[1];host.charge=100;check(host.fusion.request(),"fusión autoritativa")
	host.fusion.sequence.advance(11.5);await frames(10)
	var host_rig:Node3D=host.fusion.sequence.articulation
	check(host_rig.gait.initialized,"anfitrión calcula apoyos en suelo real")
	for i in range(80):
		arena.session.apply_input(1,i+1,Vector2(0,-1),0,0);await frames(1)
	var snapshot:Dictionary=host.make_snapshot();var state:Dictionary=snapshot.full.fusion.feet
	check(state.feet.size()==2 and state.velocity.is_finite(),"snapshot transmite dos apoyos y velocidad")
	var packed:=var_to_bytes([snapshot]).compress(FileAccess.COMPRESSION_DEFLATE)
	check(var_to_bytes([snapshot,snapshot,snapshot]).size()<65536,"tres mechas mantienen el límite de estado de red")
	var decoded:Array=bytes_to_var(packed.decompress_dynamic(65536,FileAccess.COMPRESSION_DEFLATE))
	check(decoded[0].full.fusion.feet.feet[0].point==state.feet[0].point,"apoyos conservados al comprimir y decodificar")
	var viewport:=SubViewport.new();viewport.own_world_3d=true;root.add_child(viewport)
	var remote:Node3D=load("res://network/online.tscn").instantiate();viewport.add_child(remote);remote.session.active=true;remote.session.server=false;remote.session.upsert_player(1,host.metadata);await frames(3)
	var copy:Node3D=remote.session.actors[1];copy.accept_snapshot(1,snapshot);copy.interpolate_state(.016)
	var copy_rig:Node3D=copy.fusion.sequence.articulation
	check(copy_rig.gait.initialized and copy_rig.gait.replica,"cliente utiliza apoyos del anfitrión")
	check(copy_rig.gait.queries_total==0,"réplica no lanza rayos ni simula física del anfitrión")
	var worst:=0.0
	for side in ["Der","Izq"]:
		if not host_rig.gait.feet[side].swing:worst=maxf(worst,copy_rig.gait.feet[side].point.distance_to(host_rig.gait.feet[side].point))
	check(worst<.001,"pie apoyado coincide en ambos mundos")
	var invalid:Dictionary=state.duplicate(true);invalid.stamp+=1;invalid.feet[0].point=Vector3(INF,0,0)
	var stamp:float=copy_rig.gait.last_stamp;copy_rig.gait.accept_state(invalid,copy_rig)
	check(copy_rig.gait.last_stamp==stamp,"estado no finito no corrompe la pose")
	remote.session.leave();viewport.queue_free();arena.session.leave();arena.queue_free();await frames(8)
	print("RESULTADO ",passed,"/",checks);quit(0 if passed==checks else 1)

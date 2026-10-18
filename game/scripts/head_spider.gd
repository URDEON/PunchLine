extends Node3D
## The authoritative player collider becomes the head. The parked chassis stays in world space.
const MAX_HP:=50.0
const SPEED:=4.5
const RETURN_RANGE:=3.0
var fusion:Node3D
var game:Node3D
var mode:="attached"
var elapsed:=0.0
var mecha_origin:=Vector3.ZERO
var mecha_yaw:=0.0
var mecha_hp:=0.0
var mecha_height:=4.0
var normal:=Vector3.UP
var forward:=Vector3.FORWARD
var previous_yaw:=0.0
var dormant:=0.0
var rig:Node3D
var parked:StaticBody3D
var collider:CapsuleShape3D
var scan_time:=0.0
var scan_cd:=0.0
var scan_revision:=0
var cloak_time:=0.0
var cloak_cd:=0.0
var return_cd:=0.0
var fall_speed:=0.0
var markers:Array[Label3D]=[]
var scan_targets:Array[Node3D]=[]
var pulse:MeshInstance3D
var start_position:=Vector3.ZERO
var return_start:=Vector3.ZERO
var is_replica:=false
var last_scan_revision:=-1
var energy_materials:Array=[]

func setup(controller:Node3D)->void:
	fusion=controller;game=fusion.game;name="HeadSpider"
func active()->bool:return mode!="attached"
func invisible()->bool:return mode=="spider" and cloak_time>0
func local_view()->bool:
	return game.online_session()==null or game.peer_id==game.session.local_id()
func tell(message:String)->void:game.ult_msg=message;game.ult_msg_time=3
func interact()->bool:
	if not fusion.fused:return false
	if mode=="attached":return eject()
	if mode=="spider":return request_return()
	return true

func make_visual()->void:
	if is_instance_valid(rig):return
	rig=preload("res://scripts/rustcrawler_rig.gd").new();rig.name="Rustcrawler";add_child(rig);rig.scale=Vector3.ONE*1.6
func use_spider_collider()->void:
	if collider==null:collider=CapsuleShape3D.new();collider.radius=.25;collider.height=.58
	game.robots.naoya.collision.shape=collider;game.robots.naoya.collision.position=Vector3.UP*.32
	game.player.motion_mode=CharacterBody3D.MOTION_MODE_FLOATING
	game.player.up_direction=normal
	if is_instance_valid(fusion.hurt_area):fusion.hurt_area.collision_layer=0
func eject()->bool:
	if fusion.cinematic or fusion.death_broken or game.hp<=0 or game.stun>0 or game.moves.player_freeze>0 or return_cd>0 or not game.player.is_on_floor() or fusion.boost_time>0:
		tell("CABEZA / necesita apoyo y energía estabilizada");return false
	var head:Node3D=fusion.sequence.articulation.pivots.Cabeza
	mecha_origin=game.player.global_position;mecha_yaw=game.model.rotation.y;mecha_hp=game.hp
	mecha_height=game.robots.naoya.collision.shape.height
	forward=game.facing_forward().normalized();normal=Vector3.UP;previous_yaw=game.yaw
	start_position=head.global_position+forward*.7
	# Do not eject a collider into a roof or masonry.
	var test:=SphereShape3D.new();test.radius=.31
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=test;query.transform.origin=start_position+Vector3.UP*.32;query.collision_mask=1;query.exclude=[game.player.get_rid()]
	if not game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():tell("CABEZA / salida obstruida");return false
	fusion.combat.interrupted();fusion.boost_time=0;game.dash_time=0;game.block=false
	game.attack_buffer=0;game.ability_buffer=0;game.jump_buffer=0
	view_manager().restore();head.hide();fusion.sequence.set_engine_active(false)
	make_visual();make_parked()
	prepare_energy()
	game.hp=MAX_HP;game.max_hp=MAX_HP;mode="ejecting";elapsed=0;dormant=0
	update_portrait()
	game.player.global_position=start_position;game.player.velocity=forward*2.0+Vector3.UP*1.4
	use_spider_collider();game.player.reset_physics_interpolation()
	tell("RUSTCRAWLER / 50 HP · 1 escanear · 2 camuflaje · E volver cerca del mecha")
	game.feedback.sound("mecha_servo_2",mecha_origin,-5)
	return true
func make_parked()->void:
	if is_instance_valid(parked):return
	parked=StaticBody3D.new();parked.name="DormantMecha";add_child(parked);parked.global_position=mecha_origin;parked.rotation.y=mecha_yaw
	var shape:=CapsuleShape3D.new();shape.radius=1.0;shape.height=2.4
	var col:=CollisionShape3D.new();col.shape=shape;col.position.y=1.2;parked.add_child(col)
	parked.collision_layer=0 if is_replica else 1
func ray(from:Vector3,to:Vector3,extra:Array[RID]=[])->Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(from,to,1)
	var excluded:Array[RID]=[game.player.get_rid()];excluded.append_array(extra);query.exclude=excluded
	return game.get_world_3d().direct_space_state.intersect_ray(query)
func turn_surface(wanted:Vector3)->void:
	if wanted.length()<.9:return
	var next:Vector3=wanted.normalized()
	if normal.dot(next)<-.95:return
	forward=Quaternion(normal,next)*forward;normal=next
	forward=(forward-normal*forward.dot(normal)).normalized()
	game.player.up_direction=normal
func axis()->Vector2:
	if "input_state" in game:
		return game.input_state.axis if game.clock-float(game.input_state.time)<=.35 else Vector2.ZERO
	return Input.get_vector("left","right","forward","back")
func walk_surface(delta:float)->void:
	var change:float=wrapf(game.yaw-previous_yaw,-PI,PI);previous_yaw=game.yaw
	forward=forward.rotated(normal,change).normalized()
	var right:Vector3=forward.cross(normal).normalized();var input:Vector2=axis()
	var direction:Vector3=right*input.x-forward*input.y
	if game.stun>0:direction=Vector3.ZERO
	if direction.length()>.01:direction=direction.normalized()
	var origin:Vector3=game.player.global_position
	if direction.length()>.1:
		var front:Dictionary={}
		# The inner probe sees narrow roof overhangs before the capsule wedges under them.
		for offset in [.08,.32]:
			front=ray(origin+normal*offset,origin+normal*offset+direction*.72)
			if not front.is_empty():break
		if not front.is_empty() and front.normal.dot(direction)<-.3 and front.normal.dot(normal)<.95:
			turn_surface(front.normal);game.player.global_position=front.position+normal*.035
			right=forward.cross(normal).normalized();direction=(right*input.x-forward*input.y).normalized()
	var basis:=Basis(forward.cross(normal).normalized(),normal,-forward).orthonormalized()
	game.player.global_basis=basis
	game.player.velocity=direction*SPEED-normal*(5.0+fall_speed)
	game.player.move_and_slide()
	var support:Dictionary=ray(game.player.global_position+normal*.45,game.player.global_position-normal*.75)
	if not support.is_empty():
		fall_speed=0
		turn_surface(support.normal)
		game.player.global_position=support.position+normal*.025
	elif direction.length()>.1:
		# Probe around a convex edge, e.g. wall -> roof, without teleporting through it.
		var edge_origin:Vector3=game.player.global_position-normal*.18+direction*.48
		var edge:Dictionary=ray(edge_origin,edge_origin-direction*1.0)
		if not edge.is_empty():turn_surface(edge.normal);game.player.global_position=edge.position+normal*.025
		else:lose_support(delta)
	else:lose_support(delta)

func lose_support(delta:float)->void:
	# Once an edge has no supporting surface, ordinary world gravity takes over.
	normal=Vector3.UP;game.player.up_direction=normal
	forward=forward.slide(normal).normalized()
	if forward.length()<.1:forward=Vector3.FORWARD
	fall_speed=minf(35,fall_speed+24*delta)

func tick(delta:float)->void:
	if not active():return
	elapsed+=delta;scan_cd=maxf(0,scan_cd-delta);cloak_cd=maxf(0,cloak_cd-delta)
	game.stun=maxf(0,game.stun-delta);game.player_wakeup_protection=maxf(0,game.player_wakeup_protection-delta);game.ult_msg_time=maxf(0,game.ult_msg_time-delta)
	scan_time=maxf(0,scan_time-delta);cloak_time=maxf(0,cloak_time-delta)
	game.attack_buffer=0;game.ability_buffer=0;game.jump_buffer=0;game.block=false
	if game.moves.tick_player_freeze(delta):pose_chassis(delta);update_scan(delta);return
	if mode=="ejecting":
		game.player.velocity+=Vector3.DOWN*16*delta;game.player.move_and_slide()
		var hit:Dictionary=ray(game.player.global_position+Vector3.UP*.4,game.player.global_position-Vector3.UP*.15)
		if not hit.is_empty() and elapsed>.3:game.player.global_position=hit.position+Vector3.UP*.025;game.player.velocity=Vector3.ZERO;mode="spider";elapsed=0
		elif elapsed>2.0:mode="spider";elapsed=0
	elif mode=="spider":walk_surface(delta)
	elif mode=="returning":
		var head:Node3D=fusion.sequence.articulation.pivots.Cabeza
		game.player.global_position=return_start.lerp(head.global_position+Vector3.UP*.1,smoothstep(0,1,elapsed/.8))
		game.player.velocity=Vector3.ZERO
		if elapsed>=.8:finish_return();return
	dormant=move_toward(dormant,0.0 if mode=="returning" else 1.0,delta/.95)
	pose_chassis(delta);update_visual(delta);update_scan(delta)
	if game.player.global_position.y < -15:destroy()

func pose_chassis(delta:float)->void:
	if not is_instance_valid(fusion.sequence):return
	fusion.sequence.global_position=mecha_origin;fusion.sequence.rotation.y=mecha_yaw
	var art:Node3D=fusion.sequence.articulation
	art.gait_enabled=false;art.gait.initialized=false;art.procedural_blend=0;art.crouch_weight=0;art.tracking_view=false;art.action={};art.guarding=false;art.boosting=false
	var pose:Dictionary=art.angles();var k:float=smoothstep(0,1,dormant)
	for side in ["Der","Izq"]:
		pose["Muslo_"+side].x=-1.2*k;pose["Rodilla_"+side].x=2.25*k;pose["Pantorrilla_"+side].x=-.2*k;pose["Pie_"+side].x=-.15*k
		pose["BrazoSuperior_"+side].x=.3*k;pose["Antebrazo_"+side].x=.25*k
	pose.Torso_Abdomen.x=.32*k;pose.Torso_Pecho.x=.25*k;pose.Cabeza.x=.45*k
	art.apply_pose(pose,Vector3(0,-1.15*k/maxf(.1,art.global_basis.y.length()),0),delta)
	art.pivots.Cabeza.hide()
	fusion.sequence.set_engine_active(false)
	for entry in energy_materials:
		entry.material.albedo_color=entry.color*lerpf(1.0,.35,k)
		entry.material.albedo_color.a=entry.color.a
		entry.material.emission_energy_multiplier=entry.emission*(1-k)

func prepare_energy()->void:
	if not energy_materials.is_empty() or not is_instance_valid(fusion.sequence):return
	for mesh in fusion.sequence._fusion_root.find_children("*","MeshInstance3D",true,false):
		var original:Material=mesh.get_active_material(0)
		if not original is StandardMaterial3D:continue
		var copy:StandardMaterial3D=original.duplicate()
		energy_materials.append({"mesh":mesh,"override":mesh.material_override,"material":copy,"color":copy.albedo_color,"emission":copy.emission_energy_multiplier})
		mesh.material_override=copy
func restore_energy()->void:
	for entry in energy_materials:
		if is_instance_valid(entry.mesh):entry.mesh.material_override=entry.override
	energy_materials.clear()

func update_visual(delta:float)->void:
	if not is_instance_valid(rig):return
	rig.global_position=game.player.global_position
	rig.global_basis=game.player.global_basis*Basis(Vector3.UP,PI).scaled(Vector3.ONE*1.6)
	rig.tick(delta,game.player,normal,game.player.velocity.length()>.2,smoothstep(0,.65,elapsed) if mode=="ejecting" else (1-smoothstep(.3,.8,elapsed) if mode=="returning" else 1.0))
	rig.camouflage(cloak_time>0)

func request_return()->bool:
	if game.stun>0 or game.moves.player_freeze>0:tell("RECONEXIÓN / controles bloqueados");return false
	if game.player.global_position.distance_to(mecha_origin+Vector3.UP*1.1)>RETURN_RANGE:
		tell("RUSTCRAWLER / acércate o sube al mecha para reconectar");return false
	var exclude:Array[RID]=[]
	if is_instance_valid(parked):exclude.append(parked.get_rid())
	var head:Node3D=fusion.sequence.articulation.pivots.Cabeza
	var path_hit:Dictionary=ray(game.player.global_position+normal*.35,head.global_position,exclude)
	if not path_hit.is_empty():
		print("DOCK_OBSTRUCTION ",path_hit.collider.get_path()," at ",path_hit.position)
		tell("RECONEXIÓN / trayecto obstruido");return false
	var shape:=CapsuleShape3D.new();shape.radius=1.05;shape.height=mecha_height
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=mecha_origin+Vector3.UP*(mecha_height/2+.025);query.collision_mask=1
	var volume_exclude:Array[RID]=[game.player.get_rid()];volume_exclude.append_array(exclude);query.exclude=volume_exclude
	if not game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():tell("RECONEXIÓN / no hay espacio para reactivar el mecha");return false
	mode="returning";elapsed=0;cloak_time=0;return_start=game.player.global_position
	tell("RECONEXIÓN / restableciendo el núcleo del Sentinel")
	game.player.collision_layer=0;game.player.collision_mask=0
	game.feedback.sound("mecha_servo_1",mecha_origin,-3);return true
func finish_return()->void:
	game.player.global_position=mecha_origin;game.player.global_basis=Basis.IDENTITY;game.player.up_direction=Vector3.UP;game.player.motion_mode=CharacterBody3D.MOTION_MODE_GROUNDED
	game.player.collision_layer=int(fusion.base_state.layer);game.player.collision_mask=int(fusion.base_state.mask)
	fusion.apply_fused_dimensions();fusion.fused_capsule.height=mecha_height;game.robots.naoya.collision.position.y=mecha_height/2
	game.hp=mecha_hp;game.max_hp=fusion.FUSED_MAX_HP;game.player.velocity=Vector3.ZERO
	fusion.sequence.articulation.pivots.Cabeza.show();fusion.sequence.articulation.gait_enabled=true
	fusion.sequence.set_engine_active(true);fusion.last_position=mecha_origin
	cleanup();mode="attached";return_cd=5.0;fusion.camera_release=.6;view_manager().restore();fusion.sync_hurtbox()
	update_portrait()
	game.player.reset_physics_interpolation();tell("SENTINEL / cabeza reconectada · núcleo reactivado")

func ability(slot:int)->void:
	if mode!="spider" or game.stun>0 or game.moves.player_freeze>0:return
	if slot==1 and scan_cd<=0:
		scan_time=6;scan_cd=10;scan_revision+=1;cloak_time=0
		create_scan();tell("ESCÁNER / señales detectadas durante 6 s")
	elif slot==2:
		if cloak_time>0:cloak_time=0;tell("CAMUFLAJE / desactivado")
		elif cloak_cd<=0:cloak_time=8;cloak_cd=16;tell("CAMUFLAJE / 8 s · se rompe al recibir daño o escanear")
func create_scan()->void:
	clear_scan()
	if not local_view():return
	last_scan_revision=scan_revision
	for enemy in game.enemies:
		var target:Node3D=enemy.body
		if target.global_position.distance_to(game.player.global_position)>25:continue
		var marker:=Label3D.new();marker.font_size=34;marker.pixel_size=.006;marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED;marker.no_depth_test=true;marker.modulate=Color("82f5ed");add_child(marker);markers.append(marker);scan_targets.append(target)
	pulse=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=1;sphere.height=2;sphere.radial_segments=24;sphere.rings=12;pulse.mesh=sphere
	var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.albedo_color=Color(.2,.9,.85,.07);mat.cull_mode=BaseMaterial3D.CULL_DISABLED;pulse.material_override=mat;add_child(pulse);pulse.global_position=game.player.global_position
func update_scan(_delta:float)->void:
	if scan_time<=0:clear_scan();return
	for i in range(markers.size()):
		if is_instance_valid(scan_targets[i]):
			markers[i].global_position=scan_targets[i].global_position+Vector3.UP*1.2
			markers[i].text="SEÑAL · %d m" % roundi(game.player.global_position.distance_to(scan_targets[i].global_position))
	if is_instance_valid(pulse):
		var age:float=6-scan_time;pulse.scale=Vector3.ONE*maxf(.01,age*18);pulse.visible=age<1.4
func clear_scan()->void:
	for marker in markers:
		if is_instance_valid(marker):marker.queue_free()
	markers.clear();scan_targets.clear()
	if is_instance_valid(pulse):pulse.queue_free()
	pulse=null
func take_damage(amount:float)->void:
	if mode!="spider" and mode!="ejecting":return
	cloak_time=0;game.hp=maxf(0,game.hp-amount)
	if game.hp<=0:destroy()
func destroy()->void:
	if not active():return
	var death_point:Vector3=game.player.global_position
	game.feedback.particles(death_point,Color("a7dad9"),true,16)
	reset();game.hp=0;game.max_hp=fusion.FUSED_MAX_HP;game.charge=0
	game.player.global_position=mecha_origin;fusion.apply_fused_dimensions();game.player.reset_physics_interpolation()
	tell("RUSTCRAWLER DESTRUIDO / SEÑAL PERDIDA")
	game.on_player_death() # Original death timer, destruction and respawn flow, also on the host.
func camera_update(camera:Camera3D,delta:float)->void:
	view_manager().spider_overlay(game,camera)
	var eye:Vector3=game.player.global_position+normal*.55+forward*.35
	var view:Vector3=forward*cos(game.pitch)+normal*sin(game.pitch)
	camera.global_position=camera.global_position.lerp(eye,1-exp(-delta*18))
	if camera.global_position.distance_to(eye)>2:camera.global_position=eye
	camera.quaternion=camera.quaternion.slerp(Basis.looking_at(view,normal).get_rotation_quaternion(),1-exp(-delta*10))
	camera.near=.035;camera.fov=float(game.preferences.values.fov)
func cleanup()->void:
	restore_energy()
	clear_scan()
	if is_instance_valid(rig):rig.queue_free()
	if is_instance_valid(parked):parked.queue_free()
	rig=null;parked=null
func view_manager()->RefCounted:
	return game.session.arena.camera_view if "session" in game else game.camera_view
func update_portrait()->void:
	if not local_view() or not is_instance_valid(game.interface.identity):return
	if active() and is_instance_valid(rig):game.interface.identity.set_robot_portrait(rig,1.6,-1,1.1)
	elif is_instance_valid(fusion.sequence):game.interface.identity.set_robot_portrait(fusion.sequence._fusion_root,fusion.sequence._fusion_root.scale.x,-1,4.0)
func reset()->void:
	if active():
		game.player.up_direction=Vector3.UP;game.player.global_basis=Basis.IDENTITY;game.player.motion_mode=CharacterBody3D.MOTION_MODE_GROUNDED
		view_manager().restore()
	cleanup();mode="attached";cloak_time=0;scan_time=0;dormant=0;fall_speed=0;scan_cd=0;cloak_cd=0;return_cd=0
func snapshot()->Dictionary:
	return {"mode":mode,"elapsed":elapsed,"origin":mecha_origin,"yaw":mecha_yaw,"mecha_hp":mecha_hp,"mecha_height":mecha_height,"normal":normal,"forward":forward,"dormant":dormant,"scan_time":scan_time,"scan_cd":scan_cd,"scan_revision":scan_revision,"cloak_time":cloak_time,"cloak_cd":cloak_cd}
func accept(data:Dictionary,delta:float)->void:
	var incoming:String=data.get("mode","attached")
	if incoming=="attached":
		if active():reset();fusion.sequence.articulation.pivots.Cabeza.show();update_portrait()
		return
	is_replica=true
	var new_head:bool=not active()
	for key in ["mode","elapsed","mecha_hp","mecha_height","normal","forward","dormant","scan_time","scan_cd","scan_revision","cloak_time","cloak_cd"]:
		if data.has(key):set(key,data[key])
	mecha_origin=data.get("origin",Vector3.ZERO);mecha_yaw=float(data.get("yaw",0))
	make_visual();make_parked();prepare_energy();use_spider_collider()
	if new_head:update_portrait()
	game.player.global_basis=Basis(forward.cross(normal).normalized(),normal,-forward).orthonormalized()
	pose_chassis(delta);update_visual(delta)
	if scan_time>0 and scan_revision!=last_scan_revision:create_scan()
	update_scan(delta)
func _exit_tree()->void:cleanup()

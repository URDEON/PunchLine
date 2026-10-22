extends Node
signal changed
signal fired(hit: Dictionary)
var definitions: Array[Resource] = [preload("res://combat/m4a1.tres"),preload("res://combat/mp5a5.tres")]
var magazines: Array[int] = []
var reserves: Dictionary = {}
var index := 0
var cooldown := 0.0
var reload_remaining := 0.0
var aiming := false
var require_trigger_release := true
var shots := 0
var rng := RandomNumberGenerator.new()
var feedback: Node3D
var data: Resource:
	get: return definitions[index]

func setup(effect_host: Node3D) -> void:
	for definition in definitions:
		magazines.append(definition.magazine_size)
		reserves[definition.ammo_type] = definition.reserve_ammo
	feedback = effect_host
	rng.randomize()

func reset() -> void:
	reload_remaining = 0
	cooldown = 0
	require_trigger_release = true
	for i in range(definitions.size()): magazines[i] = definitions[i].magazine_size
	for definition in definitions: reserves[definition.ammo_type] = definition.reserve_ammo
	changed.emit()

func select(slot: int,body: CharacterBody3D) -> void:
	if slot<0 or slot>=definitions.size() or slot==index: return
	reload_remaining = 0
	index = slot
	cooldown = maxf(cooldown,0.18)
	body.visual.set_weapon(index)
	changed.emit()

func tick(body: CharacterBody3D,command: RefCounted,delta: float) -> void:
	cooldown = maxf(0,cooldown-delta)
	if not command.fire: require_trigger_release = false
	if command.weapon_slot>=0: select(command.weapon_slot,body)
	if reload_remaining>0:
		reload_remaining = maxf(0,reload_remaining-delta)
		if reload_remaining<=0:
			var amount := mini(data.magazine_size-magazines[index],reserves[data.ammo_type])
			magazines[index] += amount
			reserves[data.ammo_type] -= amount
			changed.emit()
	if command.reload and reload_remaining<=0 and magazines[index]<data.magazine_size and reserves[data.ammo_type]>0:
		reload_remaining = data.reload_seconds
		if body.visual.has_method("reload"): body.visual.reload(data.reload_seconds)
		changed.emit()
	aiming = command.aim and reload_remaining<=0
	if command.fire and not require_trigger_release and cooldown<=0 and reload_remaining<=0 and magazines[index]>0:
		if body.visual.has_method("ready_to_fire") and not body.visual.ready_to_fire(): return
		if not command.sprint or command.move.length()<0.1: fire(body)

func fire(body: CharacterBody3D) -> void:
	magazines[index] -= 1
	shots += 1
	cooldown = 1.0/data.shots_per_second
	var camera: Camera3D = body.view.camera
	var origin := camera.global_position
	var forward := -camera.global_basis.z
	var spread: float = deg_to_rad(data.spread_degrees)*(0.28 if aiming else 1.0)
	forward = (forward+camera.global_basis.x*rng.randf_range(-spread,spread)+camera.global_basis.y*rng.randf_range(-spread,spread)).normalized()
	var end: Vector3 = origin+forward*data.range_limit
	var query := PhysicsRayQueryParameters3D.create(origin,end,1|2|4)
	query.exclude = [body.get_rid()]
	var hit := body.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty(): end = hit.position
	var muzzle: Vector3 = body.visual.muzzle_position()
	var anchor := body.global_position+Vector3.UP*float(body.collider.shape.height)*0.7
	var clearance := PhysicsRayQueryParameters3D.create(anchor,muzzle,1)
	clearance.exclude = [body.get_rid()]
	var obstruction := body.get_world_3d().direct_space_state.intersect_ray(clearance)
	# A visible target from an offset TPS camera cannot be hit through a muzzle-side wall.
	var barrel := PhysicsRayQueryParameters3D.create(muzzle,end,1|2|4)
	barrel.exclude = [body.get_rid()]
	var blocked := body.get_world_3d().direct_space_state.intersect_ray(barrel)
	if not blocked.is_empty(): hit = blocked; end = blocked.position
	if not obstruction.is_empty(): hit = obstruction; end = obstruction.position
	if not hit.is_empty() and hit.collider.has_method("apply_hit"):
		hit.collider.apply_hit(data.damage_at(origin.distance_to(end)),end)
	feedback.shot(muzzle,end,data.id=="sentinel_cannon")
	body.visual.shot()
	body.view.kick(data.recoil)
	fired.emit(hit)
	changed.emit()

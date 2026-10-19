extends RefCounted
## Cámara local: altura de cabeza en reposo, nunca modifica la réplica de otro jugador.
const SELF_LAYER := 1 << 19
var heights: Dictionary = {}
var masked: Array = []
var visual_id := 0
var active := false
var cannon_view_weight := 0.0
var cockpit: CanvasLayer
var cockpit_frame: MeshInstance3D
var lens: CanvasLayer
func restore() -> void:
	for entry in masked:
		if is_instance_valid(entry[0]): entry[0].layers = entry[1]
	masked.clear(); visual_id = 0; active = false; cannon_view_weight = 0.0
	if is_instance_valid(cockpit): cockpit.hide()
	if is_instance_valid(cockpit_frame): cockpit_frame.hide()
	if is_instance_valid(lens): lens.hide()
func visual(game: Node3D) -> Node3D:
	if game.fusion.fused and is_instance_valid(game.fusion.sequence): return game.fusion.sequence._fusion_root
	if game.form != "BASE": return game.moves.curse
	return game.rig_holder
func eye_height(game: Node3D) -> float:
	if game.fusion.fused: return 3.52
	var source := visual(game)
	if source == null: return 1.55
	var key: String = str(source.get_instance_id())+game.form
	if heights.has(key): return heights[key]
	var height := 1.7
	var skeleton: Skeleton3D = game.visual_motion.find_skeleton(source)
	if skeleton != null:
		for i in range(skeleton.get_bone_count()):
			var name := String(skeleton.get_bone_name(i)).to_lower()
			if name in ["head","mixamorig:head"]:
				height = (skeleton.global_transform*skeleton.get_bone_global_rest(i).origin).y-game.player.global_position.y
				heights[key] = clampf(height,.65,3.8); return heights[key]
	# La medida geométrica se hace una vez por chasis/forma, no cada fotograma.
	var top := 0.0
	for mesh in source.find_children("*","MeshInstance3D",true,false):
		var box: AABB = game.player.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
		top = maxf(top,box.end.y)
	if top > .3: height = top*.86
	heights[key] = clampf(height,.65,3.8); return heights[key]
func update(game: Node3D, camera: Camera3D, distance: float, yaw: float, pitch: float, delta: float) -> bool:
	if distance > .55 or game.fusion.cinematic:
		if active: restore()
		return false
	var source := visual(game)
	if source == null: return false
	if visual_id != source.get_instance_id():
		restore(); visual_id = source.get_instance_id()
		for mesh in source.find_children("*","GeometryInstance3D",true,false):
			# Solo la cabeza invade los ojos del piloto. El torso, las piernas y
			# ambos brazos siguen visibles; la capa solo excluye esta cámara.
			if game.fusion.fused and not game.fusion.sequence.articulation.pivots.Cabeza.is_ancestor_of(mesh): continue
			masked.append([mesh,mesh.layers]); mesh.layers = (mesh.layers & ~1) | SELF_LAYER
	if game.fusion.fused and not is_instance_valid(cockpit):
		cockpit = CanvasLayer.new(); cockpit.layer = 2; camera.add_child(cockpit)
		var panel := preload("res://scripts/mecha_cockpit.gd").new(); cockpit.add_child(panel)
		cockpit_frame = preload("res://scripts/cockpit_frame.gd").new(); camera.add_child(cockpit_frame)
	if is_instance_valid(cockpit):
		cockpit.visible = game.fusion.fused
		cockpit_frame.visible = game.fusion.fused
		cockpit.get_child(0).host = game
	if game.fusion.fused and not is_instance_valid(lens):
		lens = preload("res://scripts/body_lens.gd").new(); camera.add_child(lens)
	if is_instance_valid(lens):
		lens.configure(game.preferences.values)
		lens.set_strength(float(game.preferences.values.body_lens) if game.fusion.fused else 0)
		lens.visible=game.fusion.fused
	active = true; camera.cull_mask &= ~SELF_LAYER
	var eye: Vector3 = game.player.get_global_transform_interpolated().origin+Vector3.UP*eye_height(game)
	if game.fusion.fused:
		var head: Node3D = game.fusion.sequence.articulation.pivots.Cabeza
		# La bisagra está detrás de la cara. Mantener los ojos delante de la
		# placa del pecho incluso al girar el cuello; pitch no hunde los ojos.
		var front: Vector3 = game.fusion.sequence.articulation.global_basis.z.normalized()
		var gaze: Vector3 = head.global_basis.z; gaze.y = 0; gaze = gaze.normalized()
		var eye_offset := gaze*.62
		eye_offset += front*maxf(0,.60-eye_offset.dot(front))
		eye = head.global_position+eye_offset+Vector3.UP*.07
	# La perspectiva se abre solo durante el modo cañón, sin desplazar el CharacterBody.
	# Retroceso reducido: alejar demasiado la cámara revelaría el interior del torso.
	var cannon_active: bool = game.fusion.fused and game.fusion.combat.current.get("id","") == "cannon"
	var target_deploy: float = game.fusion.sequence.articulation.deployment if cannon_active else 0.0
	cannon_view_weight = move_toward(cannon_view_weight,target_deploy,delta*3.5)
	if game.fusion.fused and cannon_view_weight > .001:
		var forward: Vector3 = game.fusion.sequence.articulation.global_basis.z.normalized()
		var right: Vector3 = game.fusion.sequence.articulation.global_basis.x.normalized()
		eye += (right*.35-forward*.38+Vector3.UP*.15)*cannon_view_weight
		for region in ["Torso_Pecho","Torso_Abdomen","Pelvis"]:
			for mesh in game.fusion.sequence.articulation.groups.get(region,[]):
				if not is_instance_valid(mesh) or not mesh.is_visible_in_tree(): continue
				var bounds: AABB = (mesh.global_transform*mesh.get_aabb()).grow(.06)
				if bounds.has_point(eye): eye.y = maxf(eye.y,bounds.end.y+.06)
	camera.global_position = game.fusion.blend_camera(camera,eye,delta)
	camera.rotation = Vector3(pitch,yaw,0); camera.near = .06
	camera.fov = lerpf(camera.fov,minf(105,float(game.preferences.values.fov)+10.0*cannon_view_weight),1-exp(-delta*10))
	game.fusion.camera_shake(camera,delta)
	return true

func spider_overlay(game:Node3D,camera:Camera3D,first_person:=true)->void:
	if not first_person:
		if active:restore()
		return
	var source:Node3D=game.fusion.spider.rig
	if is_instance_valid(source) and visual_id!=source.get_instance_id():
		restore();visual_id=source.get_instance_id()
		# This skin is a single mesh. Exclude it only from its owner's eye camera;
		# portraits, shadows and other players still see the complete spider.
		for mesh in source.find_children("*","GeometryInstance3D",true,false):
			masked.append([mesh,mesh.layers]);mesh.layers=(mesh.layers & ~1)|SELF_LAYER
	camera.cull_mask &= ~SELF_LAYER
	if not is_instance_valid(cockpit):
		cockpit=CanvasLayer.new();cockpit.layer=2;camera.add_child(cockpit)
		cockpit.add_child(preload("res://scripts/mecha_cockpit.gd").new())
		cockpit_frame=preload("res://scripts/cockpit_frame.gd").new();camera.add_child(cockpit_frame)
	if not is_instance_valid(lens):lens=preload("res://scripts/body_lens.gd").new();camera.add_child(lens)
	active=true;cockpit.show();cockpit_frame.show();cockpit.get_child(0).host=game
	lens.configure(game.preferences.values);lens.set_strength(float(game.preferences.values.body_lens))

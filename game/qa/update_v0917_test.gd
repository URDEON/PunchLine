extends SceneTree
var checks := 0
var passed := 0
var game: Node3D
func _initialize() -> void: run.call_deferred()
func check(ok: bool,title: String) -> void:
	checks += 1
	if ok: passed += 1
	print("PASS " if ok else "FAIL ",title)
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func render_stats(source: Node) -> Dictionary:
	var meshes: Array[MeshInstance3D] = []; preload("res://scripts/mesh_pose_snapshot.gd").collect(source,meshes)
	var result := {"instances":meshes.size(),"surfaces":0,"triangles":0,"materials":{}}
	for mesh in meshes:
		for i in range(mesh.mesh.get_surface_count()):
			result.surfaces += 1; var arrays := mesh.mesh.surface_get_arrays(i)
			result.triangles += (arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX] != null and arrays[Mesh.ARRAY_INDEX].size()>0 else arrays[Mesh.ARRAY_VERTEX].size())/3
			result.materials[mesh.get_active_material(i).get_instance_id()] = true
	return result
func run() -> void:
	game = load("res://main.tscn").instantiate(); root.add_child(game); await frames(12)
	var original_zoom: float = game.zoom
	game.zoom = 0; game.update_camera(.016)
	var base_eye: float = game.camera_view.eye_height(game)
	game.camera_lock = false; game.yaw = PI*.5
	check(game.camera_aim_locked(),"primera persona alinea cuerpo aunque el lock manual esté apagado")
	check(game.facing_forward().dot(Vector3.LEFT)>.999,"M1 y habilidades salen hacia la mira en primera persona")
	game.yaw = 0
	check(game.camera_view.active and is_equal_approx(game.camera.near,.06),"Naoya primera persona sin colisión del modelo propio")
	check(absf(game.camera.global_position.y-game.player.global_position.y-base_eye)<.02,"altura de ojos real de Naoya")
	game.zoom = original_zoom; game.update_camera(.016)
	check(not game.camera_view.active and game.camera_view.masked.is_empty(),"tercera persona restaura capas del cuerpo")
	game.robots.select(1)
	var eyes: Array = []
	for i in range(4):
		game.robots.forced = i; game.robots.spawn(); await frames(4)
		game.block = true; game.skill_vfx.update_jets()
		check(game.skill_vfx.guard_shield.visible and game.skill_vfx.guard_shield.mesh.size.y<2,"escudo frontal base "+game.robots.NAMES[i])
		game.block = false; game.skill_vfx.update_jets()
		check(not game.skill_vfx.guard_shield.visible,"escudo se apaga al soltar guardia "+str(i))
		game.zoom = 0; game.update_camera(.016); eyes.append(game.camera_view.eye_height(game))
		check(game.camera_view.active and eyes[-1]>.6 and eyes[-1]<2.1,"primera persona chasis "+str(i))
	game.zoom = 5.5; game.update_camera(.016)
	print("EYE_HEIGHTS ",base_eye," ",eyes)
	check(eyes.max()-eyes.min()>.015,"ojos distinguen la geometría de las variantes")
	game.player.position = Vector3(-16,.1,0); game.charge = 100; await frames(10)
	check(game.fusion.request(),"fusión con recursos optimizados")
	game.fusion.sequence.advance(11.5); await frames(3)
	var rig: Node3D = game.fusion.sequence.articulation
	var stats := render_stats(game.fusion.sequence._fusion_root)
	print("RENDER_STATS ",stats)
	check(stats.triangles<80000 and stats.triangles>20000,"cuerpo conserva silueta con menos de 80.000 triángulos")
	check(stats.surfaces<65,"agrupación rígida reduce superficies visibles")
	check(stats.materials.size()<=4,"atlas compartido reduce cambios de material")
	check(rig.all_parts.size()==112 and rig.render_batches.batches.size()>0,"112 piezas originales de montaje y bisagras conservadas")
	game.zoom = 0; game.update_camera(.016)
	check(game.camera_view.eye_height(game)==3.52,"ojos del mecha a 3,52 m")
	check(is_instance_valid(game.camera_view.cockpit) and game.camera_view.cockpit.visible,"cabina exclusiva del mecha en primera persona")
	check(game.camera_view.cockpit_frame.mesh.get_surface_count()==1 and game.camera_view.cockpit_frame.layers == 1 << 18,"bastidor de cabina 3D local en una sola superficie")
	var panel: Control = game.camera_view.cockpit.get_child(0)
	check(panel.host == game and panel.mouse_filter == Control.MOUSE_FILTER_IGNORE,"cabina usa telemetría real sin capturar entradas")
	game.zoom = 5.5; game.update_camera(.016)
	check(not game.camera_view.cockpit.visible,"cabina se oculta al salir de primera persona")
	var before: Vector3 = rig.cannon_transform.shoulder.rotation
	for i in range(180): rig.locomotion(.016,0,true,0,0,true)
	check(rig.cannon_transform.shoulder.rotation.distance_to(before)<.08,"reposo sin acumulación de rotación tras cachear cañón")
	game.fusion.reset(); game.queue_free(); await frames(3)
	var menu: Control = load("res://launcher.tscn").instantiate(); root.add_child(menu); await frames(3)
	var gallery: Control = menu.portrait
	for i in range(gallery.SUBJECTS.size()):
		gallery.show_subject(i); await frames(2)
		check((gallery.artwork.texture!=null if gallery.SUBJECTS[i][2]=="art" else is_instance_valid(gallery.model)),"galería: "+gallery.SUBJECTS[i][0])
	check(gallery.pivot.get_child_count()==1,"solo un personaje 3D residente en la galería")
	gallery.next_subject(); check(gallery.changing,"transición de galería animada")
	menu.queue_free(); await frames(3)
	print("RESULTADO ",passed,"/",checks); quit(0 if checks==passed else 1)

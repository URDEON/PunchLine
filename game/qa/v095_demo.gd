extends RefCounted
# Toda imagen proviene del juego ejecutado; los preparativos se anuncian en pantalla.
var demo
var game: Node3D
func prepare() -> void:
	demo.prepare(); game.set_paused(false)
	game.preferences.values.hold_attack = false
	for i in range(game.enemies.size()): game.set_dummy_mode(game.enemies[i],0)
	game.yaw = 0; game.pitch = -.18; game.zoom = 6.4
func play(owner_demo: SceneTree) -> void:
	demo = owner_demo; game = demo.game
	prepare()
	demo.say("Reposo · idle.fbx del usuario, adaptado al rig original")
	await demo.frames(90); demo.shot("v095_01_standing")
	demo.say("F + W · caminar con guardia; después W · correr")
	Input.action_press("block"); Input.action_press("forward"); await demo.frames(100)
	Input.action_release("block"); await demo.frames(100)
	Input.action_release("forward"); await demo.frames(30)
	prepare()
	demo.say("Laboratorio · NPC cristalizado; cámaras del frente y espalda")
	var npc: Dictionary = game.enemies[0]
	npc.body.position = game.player.position+Vector3(0,0,-1.8)
	game.moves.freeze_enemy(npc,5)
	await demo.frames(45); demo.shot("v095_02_vidrio_frontal")
	game.yaw = PI; await demo.frames(50); demo.shot("v095_03_vidrio_trasero")
	game.yaw = 0
	demo.say("M1 real · un golpe rompe el vidrio y restaura 3D")
	game.punch()
	await demo.frames(25)
	demo.verify(npc.projection_freeze == 0 and npc.hp < 100,"golpe rompe vidrio real")
	await demo.frames(55)
	prepare()
	demo.say("2 · counter fallido cristaliza a Naoya; duración real de 5 s")
	game.moves.press(2); await demo.frames(42)
	demo.verify(game.moves.player_freeze > 4,"penalización real de counter fallido")
	await demo.frames(130); game.yaw = PI; await demo.frames(90)
	await demo.frames(100)
	demo.verify(game.moves.player_freeze == 0,"cinco segundos restauran controles")
	prepare()
	demo.say("Laboratorio · atacante real para comprobar derribo físico del jugador")
	npc.body.position = game.player.position+Vector3(0,0,-1.65)
	game.set_dummy_mode(npc,2)
	for i in range(430):
		await demo.frames(1)
		if game.physical_ragdoll.active: break
	demo.verify(game.physical_ragdoll.active,"combo del NPC activa PhysicalBoneSimulator")
	demo.shot("v095_04_ragdoll"); await demo.frames(135)
	demo.verify(not game.physical_ragdoll.active,"recuperación del jugador")
	prepare()
	demo.say("K · Kogane con aleteo, flotación e inclinación")
	if not game.presentation.kogane_invoked: game.presentation.toggle_kogane()
	await demo.frames(120); demo.shot("v095_05_kogane")
	demo.say("Laboratorio · galería con seis variantes del mismo GLB")
	if not is_instance_valid(game.gallery): game.toggle_enemy_gallery()
	game.zoom = 11; await demo.frames(120); demo.shot("v095_06_variantes")
	prepare()
	demo.say("Laboratorio · fase2 vertical en reposo y boca abajo al avanzar")
	game.start_form("FORM2",true); await demo.frames(150)
	game.yaw = 1.4; await demo.frames(75); demo.shot("v095_07_fase2")
	Input.action_press("forward"); await demo.frames(75); Input.action_release("forward")
	demo.say("4 · dominio; F8 · cámara exterior, lateral y superior")
	game.moves.press(4); await demo.frames(80)
	game.domain_inspector.toggle(); await demo.frames(75); demo.shot("v095_08_dominio_exterior")
	game.domain_inspector.elevation = 1.4; await demo.frames(75); demo.shot("v095_09_dominio_superior")
	game.domain_inspector.toggle()
	demo.verify(game.moves.domain_time > 0,"inspección no cancela dominio")
	prepare()
	demo.say("Laboratorio · caída desde altura para activar Falling después de 4 s")
	game.player.position.y = 500; game.player.velocity = Vector3.DOWN
	await demo.frames(255)
	demo.verify(game.rig_current_anim == &"mixamo/Falling","caída prolongada real")
	demo.shot("v095_10_falling"); await demo.frames(50)
	prepare()
	demo.say("Prueba automatizada terminada · todos los sistemas ejecutados por Godot")
	await demo.frames(90)
	print("DEMO RESULT %d/%d" % [demo.checks-demo.failures,demo.checks])
	game.feedback.stop_all(); OS.delay_msec(100)
	game.queue_free(); await demo.process_frame; await demo.process_frame
	demo.quit(1 if demo.failures else 0)

extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var demo: Node3D = preload("res://FusionDemo.tscn").instantiate(); demo.autoplay = false; demo.automatic_process = false
	root.add_child(demo); demo.play_fusion(); demo.advance(11.5)
	var bounds := AABB(); var first := true
	var rig: Node3D = demo.articulation
	for mesh in rig.pieces.values()+rig.shoulder_covers:
		var box: AABB = mesh.global_transform*mesh.get_aabb()
		bounds = box if first else bounds.merge(box); first = false
	print("MECHA_BOUNDS ",bounds)
	for id in ["m1_hammer","hammer","m1_stomp"]:
		rig.action = {"id":id,"time":.55 if id == "m1_hammer" else (1.05 if id == "hammer" else .65),"contact":.55 if id == "m1_hammer" else (1.05 if id == "hammer" else .65),"duration":1.8}
		for i in range(25): rig.locomotion(1.0/60,0,true,0,0,true)
		var hand: MeshInstance3D = rig.pieces.Mano_Der
		var hand_bounds: AABB = hand.global_transform*hand.get_aabb()
		print("CONTACT_POSE ",id," hand=",hand_bounds," foot=",rig.sole_height("Der"))
	demo.stop(); demo.queue_free(); await create_timer(.25).timeout; quit.call_deferred()

extends Node3D
var host: Node3D
var panels: Array[Node3D] = []
var crowns: Array[Node3D] = []
func setup(game: Node3D) -> void:
	host = game
	var floor_shader := ShaderMaterial.new(); floor_shader.shader = preload("res://shaders/domain_clock.gdshader")
	var disc := MeshInstance3D.new(); var plane := PlaneMesh.new(); plane.size = Vector2(19.7,19.7)
	disc.mesh = plane; disc.position.y = .018; disc.material_override = floor_shader; add_child(disc)
	for i in range(24):
		var angle := TAU*i/24.0
		var pane := Node3D.new(); add_child(pane); pane.position = Vector3(sin(angle)*8.6,2.8,cos(angle)*8.6)
		pane.rotation.y = angle
		var glass := MeshInstance3D.new(); var rectangle := QuadMesh.new(); rectangle.size = Vector2(1.15,2.7)
		glass.mesh = rectangle; glass.material_override = game.presentation.transparent_material(Color("bca4f3"),.1)
		pane.add_child(glass)
		for side in [-1,1]: game.glow_box(pane,Vector3(.014,2.7,.014),Vector3(side*.575,0,0),Color("8671ba"))
		var mark := Label3D.new(); pane.add_child(mark); mark.text = "%02d" % (i+1)
		mark.position.y = 1.52; mark.font_size = 32; mark.pixel_size = .006; mark.modulate = Color("dec394")
		panels.append(pane)
	for i in range(3):
		var halo: MeshInstance3D = game.moves.ring(self,Vector3(0,6.5+i*.65,0),2.8+i*.65,Color("8d75b0"))
		halo.rotation.x = .12*(i-1); crowns.append(halo)
	var eye: MeshInstance3D = game.moves.sphere(self,Vector3(0,7.4,0),Vector3(1.0,.14,1.0),Color("d5c7ef"))
	eye.material_override = game.get_glow_material(Color("cbb4e5"))
	# Luces ambientales de coste fijo, sin sombras adicionales.
	for side in [-1,1]:
		var light := OmniLight3D.new(); add_child(light); light.position = Vector3(side*4,3,0)
		light.light_color = Color("b0a0d8"); light.light_energy = .65; light.omni_range = 12

func _process(delta: float) -> void:
	if host == null or host.paused: return
	for i in range(panels.size()): panels[i].position.y = 2.8+sin(host.clock*.55+i*.4)*.18
	for i in range(crowns.size()): crowns[i].rotation.y += delta*.07*(i+1)

extends Node3D
## Nubes de capas suaves; Compatibility usa partículas CPU con el mismo shader.
const CLOUD := preload("res://shaders/mecha_cloud.gdshader")
var bursts: Array[Dictionary] = []
var emitted := 0
var paused := false
var crowns_emitted := 0
const MAX_BURSTS := 10
const MAX_PARTICLES := 440

func make_emitter(count: int, lifetime: float, velocity: Vector2, size_range: Vector2, tint: Color, density: float) -> Node3D:
	var cpu: bool = ProjectSettings.get_setting("rendering/renderer/rendering_method", "gl_compatibility") == "gl_compatibility"
	var node: Node3D = CPUParticles3D.new() if cpu else GPUParticles3D.new()
	node.emitting = false; node.amount = count; node.lifetime = lifetime
	node.one_shot = true; node.explosiveness = .92; node.randomness = .32
	var gradient := Gradient.new(); gradient.offsets = PackedFloat32Array([0,.12,.58,1]); gradient.colors = PackedColorArray([Color(1,1,1,0),Color.WHITE,Color(1,1,1,.48),Color(1,1,1,0)])
	var curve := Curve.new(); curve.add_point(Vector2(0,.3)); curve.add_point(Vector2(.5,.82)); curve.add_point(Vector2(1,1))
	var quad := QuadMesh.new(); quad.size = Vector2.ONE
	var material := ShaderMaterial.new(); material.shader = CLOUD
	material.set_shader_parameter("tint",tint); material.set_shader_parameter("density",density)
	quad.material = material
	if cpu:
		node.mesh = quad; node.direction = Vector3.UP; node.spread = 84
		node.gravity = Vector3(0,.15,0); node.initial_velocity_min = velocity.x; node.initial_velocity_max = velocity.y
		node.scale_amount_min = size_range.x; node.scale_amount_max = size_range.y
		node.scale_amount_curve = curve; node.color_ramp = gradient
		node.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE; node.emission_sphere_radius = .12
		node.angular_velocity_min = -45; node.angular_velocity_max = 45
	else:
		node.draw_pass_1 = quad
		var process := ParticleProcessMaterial.new()
		process.direction = Vector3.UP; process.spread = 84
		process.gravity = Vector3(0,.15,0); process.initial_velocity_min = velocity.x; process.initial_velocity_max = velocity.y
		process.scale_min = size_range.x; process.scale_max = size_range.y
		var scale_texture := CurveTexture.new(); scale_texture.curve = curve; process.scale_curve = scale_texture
		var ramp := GradientTexture1D.new(); ramp.gradient = gradient; process.color_ramp = ramp
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE; process.emission_sphere_radius = .12
		process.angular_velocity_min = -45; process.angular_velocity_max = 45
		node.process_material = process
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

func puff(point: Vector3, strength: float = 1.0, tint: Color = Color(.68,.63,.53), layers: bool = true) -> void:
	if bursts.size() >= MAX_BURSTS or particle_count()+(44 if layers else 8) > MAX_PARTICLES: return
	emitted += 1
	var root := Node3D.new(); add_child(root); root.global_position = point
	for i in range(3 if layers else 1):
		var duration: float = [.55,1.15,1.65][i]
		var node := make_emitter([18,16,10][i] if layers else 8,duration,Vector2(.28,1.6 if i == 0 else .8)*strength,Vector2(.28,.78 if i == 0 else 1.12)*strength,tint,.53 if i == 0 else .27)
		root.add_child(node); node.position.y = .06+float(i)*.12; node.emitting = true
	bursts.append({"node":root,"life":1.85 if layers else .75})

func particle_count() -> int:
	var result := 0
	for burst in bursts:
		for emitter in burst.node.get_children(): result += emitter.amount
	return result

func crown(point: Vector3, strength: float = 1.0) -> void:
	if bursts.size() >= MAX_BURSTS or particle_count()+72 > MAX_PARTICLES: return
	var root := Node3D.new(); add_child(root); root.global_position = point
	for i in range(12):
		var angle := TAU*float(i)/12
		var radial := Vector3(cos(angle),.10,sin(angle))
		var emitter := make_emitter(6,1.3,Vector2(2.0,4.7)*strength,Vector2(.38,.95)*strength,Color(.76,.73,.66),.40)
		root.add_child(emitter); emitter.position = radial*.65*strength; emitter.position.y = .12
		if emitter is CPUParticles3D: emitter.direction = radial; emitter.spread = 18; emitter.gravity = Vector3(0,.2,0)
		else: emitter.process_material.direction = radial; emitter.process_material.spread = 18; emitter.process_material.gravity = Vector3(0,.2,0)
		emitter.emitting = true
	bursts.append({"node":root,"life":1.6}); emitted += 1; crowns_emitted += 1

func _process(delta: float) -> void:
	for i in range(bursts.size()-1,-1,-1):
		var burst: Dictionary = bursts[i]
		for node in burst.node.get_children(): node.speed_scale = 0 if paused else 1
		if paused: continue
		burst.life -= delta
		if burst.life <= 0: burst.node.queue_free(); bursts.remove_at(i)

func clear() -> void:
	for burst in bursts: burst.node.queue_free()
	bursts.clear()

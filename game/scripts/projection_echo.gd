extends "res://scripts/projection_frame.gd"
var silhouette: MeshInstance3D
var ink: StandardMaterial3D
var echo_glass: ShaderMaterial
var opacity := 1.0
func setup(color: Color = Color("bfe5ff")) -> void:
	super.setup(color)
	name = "ProjectionPoseFrame"
	echo_glass = GLASS.duplicate() as ShaderMaterial
	echo_glass.set_shader_parameter("transparency",.015)
	echo_glass.set_shader_parameter("edge_strength",.6)
	set_glass(pane)
	silhouette = MeshInstance3D.new(); silhouette.name = "FlatPlayerSilhouette"
	add_child(silhouette)
	ink = StandardMaterial3D.new()
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.cull_mode = BaseMaterial3D.CULL_DISABLED
	ink.albedo_color = Color(.65,.87,1,.19)
	ink.render_priority = 1
	silhouette.material_override = ink
	silhouette.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func set_glass(node: Node) -> void:
	if node is MeshInstance3D: node.material_override = echo_glass
	for child in node.get_children(): set_glass(child)
func set_pose(mesh: ArrayMesh) -> void: silhouette.mesh = mesh
func set_opacity(value: float) -> void:
	opacity = clampf(value,0,1)
	ink.albedo_color.a = .19*opacity
	echo_glass.set_shader_parameter("opacity",opacity)

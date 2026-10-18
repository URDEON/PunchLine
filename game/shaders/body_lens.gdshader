shader_type canvas_item;
render_mode unshaded;
uniform sampler2D scene : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength : hint_range(0.0,0.35) = 0.14;
void fragment() {
	vec2 p = SCREEN_UV - vec2(0.5);
	vec2 aspect = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float radius = dot(p * aspect, p * aspect);
	float edge_radius = dot(vec2(0.5) * aspect, vec2(0.5) * aspect);
	vec2 uv = vec2(0.5) + p * (1.0 + strength * radius) / (1.0 + strength * edge_radius);
	vec3 color = texture(scene, uv).rgb;
	float vignette = 1.0 - strength * 0.85 * smoothstep(0.15, edge_radius, radius);
	COLOR = vec4(color * vignette, 1.0);
}

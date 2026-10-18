shader_type spatial;
render_mode unshaded, cull_disabled;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	float angle = atan(p.y,p.x);
	float rings = pow(max(0.0,cos(radius*94.2478)),35.0);
	float ticks = pow(max(0.0,cos(angle*24.0)),45.0)*smoothstep(.6,.9,radius);
	float glow = rings*.35+ticks*.7;
	float breathing = .85+.15*sin(TIME*.75-radius*6.0);
	ALBEDO = mix(vec3(.026,.023,.048),vec3(.22,.16,.32),glow);
	EMISSION = vec3(.46,.35,.65)*glow*breathing;
}

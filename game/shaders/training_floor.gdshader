shader_type spatial;
render_mode diffuse_burley;
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = world_position.xz;
    vec2 cell = abs(fract(p / 3.0 - 0.5) - 0.5) * 3.0;
    float width = max(max(fwidth(p).x, fwidth(p).y), 0.003);
    float grout = 1.0 - smoothstep(0.015, 0.015 + width, min(cell.x, cell.y));
    float plaza = 1.0 - smoothstep(15.0, 15.2, length(p));
    float road = 0.0;
    float grain = fract(sin(dot(floor(p*16.0), vec2(12.9898,78.233)))*43758.5453);
    vec3 concrete = vec3(0.22,0.235,0.255) + (grain-0.5)*0.012;
    vec3 tiles = mix(vec3(0.255,0.245,0.265),vec3(0.16,0.16,0.18),grout*0.5);
    ALBEDO = mix(mix(concrete,tiles,plaza),vec3(0.09,0.105,0.125),road);
    float ring = 1.0-smoothstep(0.025,0.025+width,abs(length(p)-13.8));
    ALBEDO = mix(ALBEDO,vec3(0.56,0.47,0.34),ring*0.65);
    ROUGHNESS = mix(0.78,0.62,road);
}

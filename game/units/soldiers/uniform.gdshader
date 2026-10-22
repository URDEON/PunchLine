shader_type spatial;
uniform vec4 cloth_color : source_color = vec4(0.22,0.29,0.25,1.0);
varying vec3 garment_position;
void vertex() { garment_position = VERTEX; }
void fragment() {
	vec3 cell = floor(garment_position * 75.0);
	float patch = fract(sin(dot(cell,vec3(17.13,41.71,93.17)))*43758.5453);
	vec3 fabric = cloth_color.rgb;
	if (patch > 0.72) fabric *= 0.55;
	else if (patch < 0.22) fabric = mix(fabric,vec3(0.48,0.51,0.39),0.55);
	ALBEDO = fabric;
	ROUGHNESS = 0.92;
}

shader_type spatial;
render_mode cull_disabled;
uniform float wind_strength : hint_range(0.0,1.0) = .55;
uniform float fade_start = 42.0;
uniform float fade_end = 58.0;
uniform vec3 root_color : source_color = vec3(.105,.17,.042);
uniform vec3 tip_color : source_color = vec3(.28,.38,.11);
void vertex() {
	vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	float distance_to_eye=distance(world,CAMERA_POSITION_WORLD);
	float fade=1.0-smoothstep(fade_start,fade_end,distance_to_eye);
	VERTEX*=fade;
	float gust=sin(TIME*1.5+world.x*.35+world.z*.22)+.4*sin(TIME*2.7+world.z*.8);
	VERTEX.xz+=vec2(.11,.06)*gust*wind_strength*UV.y*UV.y*fade;
}
void fragment() {
	if (!FRONT_FACING) NORMAL=-NORMAL;
	ALBEDO=mix(root_color,tip_color,UV.y)*COLOR.rgb;
	ROUGHNESS=.95;
	BACKLIGHT=ALBEDO*.20;
}

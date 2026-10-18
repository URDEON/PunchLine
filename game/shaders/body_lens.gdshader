shader_type canvas_item;
render_mode unshaded;
uniform sampler2D scene : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength : hint_range(0.0,0.35) = 0.14;
uniform float chromatic : hint_range(0.0,1.0) = 0.3;
uniform float bloom : hint_range(0.0,1.0) = 0.35;
uniform float lens_dirt : hint_range(0.0,1.0) = 0.25;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
vec3 bright(vec2 uv) { return max(texture(scene,clamp(uv,vec2(.001),vec2(.999))).rgb-vec3(.82),vec3(0.0)); }
void fragment() {
	vec2 p = SCREEN_UV - vec2(0.5);
	vec2 aspect = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float radius = dot(p * aspect, p * aspect);
	float edge_radius = dot(vec2(0.5) * aspect, vec2(0.5) * aspect);
	vec2 uv = vec2(0.5) + p * (1.0 + strength * radius) / (1.0 + strength * edge_radius);
	vec3 color = texture(scene, uv).rgb;
	vec2 fringe=p*radius*chromatic*.008;
	color.r=texture(scene,clamp(uv+fringe,vec2(.001),vec2(.999))).r;
	color.b=texture(scene,clamp(uv-fringe,vec2(.001),vec2(.999))).b;
	vec2 spread=SCREEN_PIXEL_SIZE*8.0;
	vec3 glow=bright(uv)*.2;
	for(int i=0;i<8;i++) {
		float angle=float(i)*.785398;
		glow+=bright(uv+vec2(cos(angle),sin(angle))*spread)*.1;
	}
	float grime=hash(floor(SCREEN_UV*vec2(230.0,150.0)));
	grime=smoothstep(.78,.99,grime)*.4+smoothstep(.25,.8,radius)*.25;
	float smear=pow(max(0.0,sin(SCREEN_UV.x*37.0+sin(SCREEN_UV.y*19.0)*1.4)),18.0)*.12;
	color+=glow*bloom*(1.0+lens_dirt*(grime+smear)*5.0);
	color*=1.0-lens_dirt*(grime+smear)*.12;
	float vignette = 1.0 - strength * 0.85 * smoothstep(0.15, edge_radius, radius);
	COLOR = vec4(color * vignette, 1.0);
}

shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float seed=0.0;
void fragment(){
 vec2 uv=UV-vec2(.42+.12*sin(seed),.52);
 float angle=atan(uv.y,uv.x);float radius=length(uv);
 float fracture=abs(sin(angle*3.0+seed+sin(radius*37.0)*.12))*radius;
 float hairline=(1.0-smoothstep(.002,.010,fracture))*(1.0-smoothstep(.18,.7,radius));
 ALBEDO=vec3(.11,.10,.085);ALPHA=hairline*.78;
}

shader_type spatial;
render_mode cull_disabled;
void fragment(){
 vec2 p=UV*vec2(22.0,18.0);
 float a=abs(fract(p.x+p.y)-.5);float b=abs(fract(p.x-p.y)-.5);
 float wire=1.0-smoothstep(.045,.10,min(a,b));
 ALBEDO=vec3(.31,.37,.35);METALLIC=.75;ROUGHNESS=.54;
 float distance_fade=1.0-smoothstep(35.0,90.0,length(VERTEX));
 ALPHA=wire*distance_fade;ALPHA_SCISSOR_THRESHOLD=.45;
}

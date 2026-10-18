shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled;
uniform float throttle : hint_range(0.0,1.5) = 1.0;
uniform float seed = .0;
varying vec4 particle_color;
void vertex(){
 particle_color=COLOR;
 vec3 sc=vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(vec4(INV_VIEW_MATRIX[0].xyz*sc.x,0),vec4(INV_VIEW_MATRIX[1].xyz*sc.y,0),vec4(INV_VIEW_MATRIX[2].xyz*sc.z,0),MODEL_MATRIX[3]);
}
void fragment(){
 float y=UV.y; float wobble=sin(y*24.0-TIME*37.0+seed)*.045+sin(y*43.0-TIME*53.0)*.025;
 float width=mix(.42,.07,y)*(1.0+.12*sin(TIME*48.0+seed));
 float x=abs(UV.x-.5+wobble*y);
 float edge=1.0-smoothstep(width*.28,width,x);
 float tip=1.0-smoothstep(.6,1.0,y);
 float core=1.0-smoothstep(.015,.12,x+y*.035);
 vec3 color=mix(vec3(.06,.34,1.0),vec3(.16,.85,1.0),edge);
 color=mix(color,vec3(.92,.99,1.0),core*tip);
 ALBEDO=color; EMISSION=color*(1.5+core*2.0)*throttle;
 ALPHA=edge*tip*smoothstep(.0,.06,y)*throttle*particle_color.a;
}

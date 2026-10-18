shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled;
uniform vec4 tint : source_color = vec4(.68,.63,.53,1.0);
uniform float density = .62;
varying vec4 particle_color;
varying vec2 noise_seed;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise2(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){
 particle_color=COLOR;
 noise_seed=MODEL_MATRIX[3].xz*.37;
 vec3 sc=vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
 float angle=INSTANCE_CUSTOM.x;
 vec3 right=INV_VIEW_MATRIX[0].xyz*cos(angle)+INV_VIEW_MATRIX[1].xyz*sin(angle);
 vec3 up=INV_VIEW_MATRIX[1].xyz*cos(angle)-INV_VIEW_MATRIX[0].xyz*sin(angle);
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(vec4(right*sc.x,0),vec4(up*sc.y,0),vec4(INV_VIEW_MATRIX[2].xyz*sc.z,0),MODEL_MATRIX[3]);
}
void fragment(){
 vec2 p=UV*2.0-1.0;
 float n=noise2(UV*5.0+noise_seed+vec2(TIME*.11,-TIME*.07))*.65+noise2(UV*11.0-noise_seed-TIME*.06)*.35;
 float soft=1.0-smoothstep(.20,.98,length(p)+(.5-n)*.26);
 ALBEDO=tint.rgb*(.72+.23*UV.y+.14*n)*particle_color.rgb;
 ALPHA=soft*density*particle_color.a;
}

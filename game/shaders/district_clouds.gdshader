shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;
uniform bool night=false;
varying vec2 world_xz;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float clouds(vec2 p){return noise(p)*.56+noise(p*2.05)*.27+noise(p*4.13)*.12+noise(p*8.17)*.05;}
void vertex(){world_xz=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;}
void fragment(){
 vec2 p=world_xz*.0070+vec2(TIME*.0014,TIME*.00045);
 float density=clouds(p);float alpha=smoothstep(.54,.70,density);
 float sun_edge=clouds(p+vec2(.055,.025));
 float light=clamp(.65+(density-sun_edge)*5.0,.12,1.0);
 float edge=1.0-smoothstep(480.0,690.0,length(world_xz));
 vec3 shade=mix(vec3(.52,.61,.69),vec3(.98,.97,.92),light);
 ALBEDO=night?shade*vec3(.19,.25,.38):shade;
 ALPHA=alpha*edge*.87;
}

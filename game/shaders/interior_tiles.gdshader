shader_type spatial;
varying vec3 world_position;
varying vec3 world_normal;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;world_normal=MODEL_NORMAL_MATRIX*NORMAL;}
void fragment(){
 vec2 uv=world_position.xz/.75;
 vec2 edge=min(fract(uv),1.0-fract(uv));vec2 aa=max(fwidth(uv),vec2(.001));
 float seam=max(1.0-smoothstep(.006-aa.x,.006+aa.x,edge.x),1.0-smoothstep(.006-aa.y,.006+aa.y,edge.y));
 vec2 cell=floor(uv);float shade=.5+.5*sin(dot(cell,vec2(2.37,5.73)));
 vec3 stone=mix(vec3(.27,.28,.25),vec3(.34,.34,.30),shade*.35);
 ALBEDO=world_normal.y<-.5?vec3(.55,.54,.50):mix(stone,vec3(.13,.14,.13),seam*.55);ROUGHNESS=.58;SPECULAR=.30;
}

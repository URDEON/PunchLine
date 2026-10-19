shader_type fog;
uniform float amount : hint_range(0.0,1.0) = .35;
uniform vec3 mist_color : source_color = vec3(.70,.77,.78);
void fog() {
 vec3 edge=smoothstep(vec3(0.0),vec3(.18,.35,.18),min(UVW,vec3(1.0)-UVW));
 vec3 p=WORLD_POSITION*vec3(.32,.6,.32)+vec3(TIME*.025,0.0,TIME*.015);
 float cloud=.5+.25*sin(p.x+sin(p.z*1.7))+.25*sin(p.z*.7+p.y*.9);
 DENSITY=amount*.06*edge.x*edge.y*edge.z*cloud;
 ALBEDO=mist_color;
}

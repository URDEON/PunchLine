shader_type spatial;
render_mode cull_back;
varying vec3 world_position;
varying vec3 world_normal;
float hash(vec2 p){vec3 q=fract(vec3(p.xyx)*.1031);q+=dot(q,q.yzx+33.33);return fract((q.x+q.y)*q.z);}
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;world_normal=MODEL_NORMAL_MATRIX*NORMAL;}
void fragment(){
 vec2 uv=world_position.xz/vec2(.60,.40);
 uv.x+=mod(floor(uv.y),2.0)*.5;
 vec2 cell=floor(uv);vec2 edge=min(fract(uv),1.0-fract(uv));
 vec2 aa=max(fwidth(uv),vec2(.001));
 float grout=(1.0-smoothstep(.012-aa.x,.012+aa.x,edge.x))+(1.0-smoothstep(.018-aa.y,.018+aa.y,edge.y));
 float variation=hash(cell);
 vec3 stone=mix(vec3(.17,.19,.17),vec3(.33,.32,.28),variation);
 float pores=hash(floor(world_position.xz*180.0));
 stone*=.97+.045*pores;
 vec3 finish=mix(stone,vec3(.08,.09,.08),clamp(grout,0.,1.)*.62);
 ALBEDO=mix(vec3(.22,.23,.20),finish,smoothstep(.6,.9,abs(world_normal.y)));
 ROUGHNESS=.88;SPECULAR=.22;
}

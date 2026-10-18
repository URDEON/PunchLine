shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 tint : source_color = vec4(.4,.8,1.,1.);
uniform float age : hint_range(0.,1.) = 0.;
uniform int mode = 0;
uniform bool billboard = true;
varying float seed;
void vertex(){
 seed=MODEL_MATRIX[3].x*.31+MODEL_MATRIX[3].z*.19;
 if(billboard){
  vec3 sc=vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
  MODELVIEW_MATRIX=VIEW_MATRIX*mat4(vec4(INV_VIEW_MATRIX[0].xyz*sc.x,0.),vec4(INV_VIEW_MATRIX[1].xyz*sc.y,0.),vec4(INV_VIEW_MATRIX[2].xyz*sc.z,0.),MODEL_MATRIX[3]);
 }
}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 vec2 p=UV*2.-1.; float r=length(p); float a=atan(p.y,p.x);
 float envelope=(1.-smoothstep(.6,1.,age))*smoothstep(0.,.06,age+.03);
 float fine=sin(a*13.+r*27.-TIME*19.+seed)*.5+.5;
 float soft=pow(max(0.,1.-r),2.);
 if(mode==1){
  float crescent=exp(-pow((r-.68)*17.,2.));
  soft=crescent*smoothstep(-.6,.2,p.x)*(1.-smoothstep(.88,1.,r))*(.5+fine*.5);
 }else if(mode==2){
  vec2 g=p*vec2(7.,8.); vec2 cell=fract(g)-.5;
  float hex=abs(length(cell)-.38); float grid=exp(-hex*55.);
  soft=(.10+grid*.6)*(1.-smoothstep(.65,1.,r))+exp(-pow((r-.86)*24.,2.))*.6;
 }else if(mode==3){
  soft=pow(max(0.,1.-abs(p.y)),3.)*smoothstep(-1.,-.6,p.x)*(1.-smoothstep(.35,1.,p.x));
  soft*=.65+.35*sin(p.x*22.-TIME*35.);
 }else if(mode==4){
  float jagged=sin(a*9.+seed)*.045+sin(a*17.-seed)*.025;
  soft=exp(-pow((r-.63-jagged)*16.,2.))*(.25+.75*fine)*(1.-smoothstep(.9,1.,r));
 }
 ALBEDO=tint.rgb; EMISSION=mix(tint.rgb,vec3(1.),pow(soft,3.)*.7)*soft*1.5;
 ALPHA=clamp(soft*envelope*tint.a,0.,.9);
}

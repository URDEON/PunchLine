shader_type canvas_item;
render_mode unshaded;
uniform sampler2D scene : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D heat_image : filter_linear, repeat_disable;
uniform int mode = 0;
float random(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void fragment() {
 vec3 source=texture(scene,SCREEN_UV).rgb;
 float grey=dot(source,vec3(.2126,.7152,.0722));
 vec3 color=source;
 if (mode==1) {
  float amplified=pow(clamp(grey,0.0,1.0),.65);
  float gain=amplified/(amplified+.25);
  float grain=(random(floor(FRAGCOORD.xy)+floor(TIME*12.0))-.5)*.025;
  color=vec3(.10,.72,.21)*(gain+.025+grain);
 } else if (mode==2) {
  vec4 heat=texture(heat_image,SCREEN_UV);
  color=mix(vec3(.015,.035,.09)+vec3(.08,.16,.23)*grey,heat.rgb,heat.a);
 } else if (mode==3) {
  vec4 objects=texture(heat_image,SCREEN_UV);
  color=mix(vec3(.025,.085,.10)*grey+vec3(.008,.015,.025),objects.rgb,objects.a);
 }
 float radius=length((SCREEN_UV-.5)*vec2(1.0,.75));
 color*=1.0-.35*smoothstep(.30,.64,radius);
 COLOR=vec4(color,1.0);
}

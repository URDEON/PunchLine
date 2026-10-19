shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
uniform int vision_mode = 2;
uniform float temperature = 1.0;
void fragment() {
 float rim=pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),1.5);
 if (vision_mode==2) {
  float value=clamp(temperature*(.66+.34*abs(dot(normalize(NORMAL),normalize(VIEW)))),0.0,1.0);
  vec3 cold=mix(vec3(.06,.14,.60),vec3(.95,.08,.015),smoothstep(.1,.65,value));
  ALBEDO=mix(cold,vec3(1.0,.90,.22),smoothstep(.65,1.0,value));
  ALPHA=1.0;
 } else {
  ALBEDO=mix(vec3(.07,.28,.32),vec3(.55,1.0,.95),rim);
  ALPHA=.20+rim*.75;
 }
}

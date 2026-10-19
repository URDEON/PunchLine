shader_type spatial;
uniform vec4 paint_color:source_color=vec4(.3,.5,.6,1.0);
void fragment(){
 float wav=sin(UV.x*160.0);float ridge=.93+.07*wav;
 float edge=min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y));
 float wear=(1.0-smoothstep(.008,.025,edge))*.38;
 ALBEDO=mix(paint_color.rgb*ridge,vec3(.24,.17,.10),wear);
 METALLIC=.62;ROUGHNESS=.55+wear*.3;
}

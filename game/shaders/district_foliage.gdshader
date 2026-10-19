shader_type spatial;
render_mode cull_disabled;
uniform sampler2D leaves:source_color,filter_linear_mipmap,repeat_disable;
uniform vec3 tint:source_color=vec3(.10,.23,.065);
uniform float wind=.55;
uniform vec4 leaf_region=vec4(.10,.02,.80,.70);
void vertex(){
 vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.xz+=vec2(.13,.07)*sin(TIME*1.1+world.x*.23+world.z*.37)*wind*(1.0-UV.y);
}
void fragment(){
 vec4 tex=texture(leaves,leaf_region.xy+UV*leaf_region.zw);float luminance=dot(tex.rgb,vec3(.2126,.7152,.0722));
 ALBEDO=mix(tex.rgb,tint*(.42+.58*clamp(luminance*2.5,0.0,1.0)),.96)*COLOR.rgb;
 ALPHA=tex.a;ALPHA_SCISSOR_THRESHOLD=.48;ROUGHNESS=.92;
 if(!FRONT_FACING)NORMAL=-NORMAL;
 BACKLIGHT=ALBEDO*.32;
}

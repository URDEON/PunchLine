shader_type spatial;
render_mode cull_disabled;
uniform sampler2D base_texture : source_color, filter_linear_mipmap;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap;
uniform sampler2D orm_texture : filter_linear_mipmap;
uniform sampler2D regions_a : filter_linear;
uniform sampler2D regions_b : filter_linear;
uniform vec4 jacket : source_color = vec4(.16,.18,.22,1);
uniform vec4 pants : source_color = vec4(.28,.3,.35,1);
uniform vec4 hat : source_color = vec4(.16,.18,.22,1);
uniform vec4 hoodie : source_color = vec4(.85,.85,.85,1);
uniform vec4 shoes : source_color = vec4(.8,.8,.8,1);
uniform vec4 hair : source_color = vec4(.12,.09,.07,1);
uniform vec4 skin : source_color = vec4(.8,.58,.4,1);
vec3 cloth(vec3 original,vec3 tint,float lum,float print_protection) {
    vec3 result=tint * clamp(lum/.075,.25,2.8);
    return mix(result,original,smoothstep(.25,.65,lum)*print_protection);
}
void fragment() {
    vec3 original=texture(base_texture,UV).rgb;
    float lum=dot(original,vec3(.2126,.7152,.0722));
    vec4 a=texture(regions_a,UV); vec4 b=texture(regions_b,UV);
    vec3 col=original;
    col=mix(col,cloth(original,jacket.rgb,lum,1.0),a.r);
    col=mix(col,cloth(original,pants.rgb,lum,1.0),a.g);
    col=mix(col,cloth(original,hat.rgb,lum,1.0),a.b);
    col=mix(col,hoodie.rgb*clamp(lum/.65,.0,1.4),a.a);
    col=mix(col,shoes.rgb*clamp(lum/.6,.0,1.4),b.r);
    col=mix(col,hair.rgb*clamp(lum/.045,.3,2.0),b.g);
    col=mix(col,original*skin.rgb/vec3(.68,.47,.30),b.b);
    ALBEDO=clamp(col,vec3(0),vec3(1));
    NORMAL_MAP=texture(normal_texture,UV).rgb;
    vec3 orm=texture(orm_texture,UV).rgb;
    AO=orm.r; ROUGHNESS=max(orm.g,.6); METALLIC=0.0;
}

shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
void fragment() {
    vec4 tint = COLOR;
    vec2 offset = vec2(sin(SCREEN_UV.y * 30.0), cos(SCREEN_UV.x * 28.0)) * SCREEN_PIXEL_SIZE * 1.2;
    vec3 scene = texture(screen_texture, SCREEN_UV + offset).rgb;
    COLOR = vec4(mix(scene, tint.rgb, 0.16), tint.a);
}

shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform vec4 glass_color : source_color = vec4(0.75, 0.9, 1.0, 1.0);
uniform float transparency : hint_range(0.0, 1.0) = 0.04;
uniform float edge_strength : hint_range(0.0, 5.0) = 0.92;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
// Medidas locales del GLB original. El borde está en su propia superficie.
uniform vec2 pane_center = vec2(-0.002185285, -0.001676619);
uniform vec2 pane_half_size = vec2(0.743557036, 0.949678361);
varying vec2 pane_coordinates;

void vertex() {
    pane_coordinates = (VERTEX.xy - pane_center) / pane_half_size;
}

void fragment() {
    // abs conserva la transparencia al observar el vidrio desde detrás.
    float fresnel = pow(1.0 - clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), 3.0);
    // El Fresnel no marca por sí solo los bordes de un panel visto de frente.
    float edge = smoothstep(0.986, 0.999, max(abs(pane_coordinates.x), abs(pane_coordinates.y)));
    ALBEDO = glass_color.rgb;
    EMISSION = glass_color.rgb * (fresnel + edge * 0.32) * edge_strength;
    ALPHA = clamp(transparency + fresnel * 0.65 + edge * 0.18, 0.0, 1.0) * opacity;
}

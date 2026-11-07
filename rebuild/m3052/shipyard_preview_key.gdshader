shader_type canvas_item;

// User's Elite V2 source previews are RGB on a flat #1c1c24 backdrop.
// Key out ONLY that studio backdrop, exposing the game's sea underneath.
// Keep the original color render, so sails, heraldry and hull stay authentic.
// No alpha-key applied to the two existing original player previews.
uniform vec3 studio_backdrop : source_color = vec3(0.1098039, 0.1098039, 0.1411765);
uniform float edge_start : hint_range(0.0, 0.2) = 0.010;
uniform float edge_end : hint_range(0.0, 0.2) = 0.080;

void fragment() {
    vec4 src = texture(TEXTURE, UV);
    vec3 deviation = abs(src.rgb - studio_backdrop);
    float distinct = max(deviation.r, max(deviation.g, deviation.b));
    float ship_alpha = smoothstep(edge_start, edge_end, distinct);
    COLOR = vec4(src.rgb, src.a * ship_alpha);
}

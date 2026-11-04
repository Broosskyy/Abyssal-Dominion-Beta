// Same M12 approximation and recovered UV scale/tint/speed; now one shared shader.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform sampler2D coast_foam : repeat_enable, filter_linear_mipmap;
void fragment() {
    vec2 uv = UV * vec2(0.1, 0.083) + vec2(TIME * 0.05, 0.0);
    float coverage = texture(coast_foam, uv).a;
    ALBEDO = vec3(0.88, 0.97, 1.0);
    ALPHA = coverage * 0.391;
}

shader_type canvas_item;
render_mode unshaded;
uniform float sea_time = 0.0;
// Keep the hull, rigging, quay and horizon rigid. Only open water moves.
void fragment() {
	vec2 uv = UV;
	float water = smoothstep(0.65, 0.85, uv.x) * smoothstep(0.62, 0.80, uv.y);
	vec2 ripple = vec2(sin(uv.y * 125.0 - sea_time * 1.9), cos(uv.x * 98.0 + uv.y * 46.0 - sea_time * 1.2));
	vec4 base = texture(TEXTURE, uv + ripple * vec2(0.0016, 0.0008) * water);
	float crest = pow(max(0.0, sin(uv.y * 245.0 - sea_time * 2.3 + sin(uv.x * 56.0))), 14.0);
	float shimmer = crest * (0.5 + 0.5 * sin(uv.x * 170.0 + sea_time * 0.7)) * water;
	COLOR = vec4(base.rgb + vec3(0.10, 0.19, 0.23) * shimmer * 0.22, base.a) * COLOR;
}

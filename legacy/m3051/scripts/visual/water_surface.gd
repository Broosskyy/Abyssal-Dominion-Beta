class_name WaterSurface
extends MeshInstance3D



func _ready() -> void:
	add_to_group("regional_water_surface")
	var plane := PlaneMesh.new()
	# M198: visual-master sea covers the complete 360x360 gameplay chart plus edge margin.
	plane.size = Vector2(390.0, 390.0)
	var subdivisions := WorldVisualBudgetCatalog.int_value(get_tree(), "water_subdivisions", 64)
	plane.subdivide_width = subdivisions
	plane.subdivide_depth = subdivisions
	mesh = plane
	material_override = _create_water_material()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var settings := ClientSettings.current(get_tree())
	if settings != null: settings.changed.connect(_apply_motion)
	_apply_motion()

func apply_region_profile(profile: Dictionary) -> void:
	var material := material_override as ShaderMaterial
	if material == null: return
	material.set_shader_parameter("shallow_color", Color(str(profile.get("shallow", "087a99"))))
	material.set_shader_parameter("mid_color", Color(str(profile.get("mid", "034c75"))))
	material.set_shader_parameter("deep_color", Color(str(profile.get("deep", "011f3d"))))
	material.set_shader_parameter("foam_color", Color(str(profile.get("foam", "c2eff2"))))
	material.set_shader_parameter("wave_height", float(profile.get("wave_height", 0.085)))
	material.set_shader_parameter("wave_speed", float(profile.get("wave_speed", 0.48)))
	material.set_shader_parameter("macro_contrast", float(profile.get("macro_contrast", 0.14)))
	material.set_shader_parameter("surface_roughness", float(profile.get("surface_roughness", 0.64)))
	material.set_shader_parameter("specular_strength", float(profile.get("specular_strength", 0.17)))
	material.set_shader_parameter("micro_contrast", float(profile.get("micro_contrast", 0.16)))
	material.set_shader_parameter("crest_strength", float(profile.get("crest_strength", 0.055)))

func _apply_motion() -> void:
	var settings := ClientSettings.current(get_tree())
	(material_override as ShaderMaterial).set_shader_parameter("motion_scale", 0.15 if settings != null and settings.values.reduced_motion else 1.0)


func _create_water_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_back;

uniform vec3 shallow_color : source_color = vec3(0.035, 0.48, 0.60);
uniform vec3 mid_color : source_color = vec3(0.012, 0.30, 0.46);
uniform vec3 deep_color : source_color = vec3(0.004, 0.12, 0.24);
uniform vec3 foam_color : source_color = vec3(0.76, 0.94, 0.95);
uniform float wave_height = 0.085;
uniform float wave_speed = 0.48;
uniform float motion_scale = 1.0;
uniform float macro_contrast = 0.14;
uniform float surface_roughness = 0.64;
uniform float specular_strength = 0.17;
uniform float micro_contrast = 0.16;
uniform float crest_strength = 0.055;
uniform float m215_whitecap_detail = 0.11;
uniform sampler2D water_normal : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D foam_texture : source_color, repeat_enable, filter_linear_mipmap;

varying float wave_mix;
varying float world_band;

void vertex() {
	float t = TIME * motion_scale;
	float a = sin(VERTEX.x * 0.16 + t * wave_speed);
	float b = cos(VERTEX.z * 0.205 - t * wave_speed * 0.79);
	float c = sin((VERTEX.x + VERTEX.z) * 0.082 + t * 0.28);
	float d = sin((VERTEX.x * 0.047 - VERTEX.z * 0.061) - t * 0.19);
	wave_mix = (a + b + c * 0.72 + d * 0.46) / 3.18;
	world_band = sin((VERTEX.x * 0.035) + (VERTEX.z * 0.027) + t * 0.06) * 0.5 + 0.5;
	VERTEX.y += wave_mix * wave_height;
}

void fragment() {
	float t = TIME * motion_scale;
	float light_mix = clamp(wave_mix * 0.5 + 0.5, 0.0, 1.0);
	float macro = mix(world_band, sin((UV.x * 7.0 + UV.y * 4.5) + t * 0.07) * 0.5 + 0.5, 0.38);
	float broad = sin(UV.x * 16.0 - UV.y * 11.0 + t * 0.045) * 0.5 + 0.5;
	float micro = sin(UV.x * 92.0 + UV.y * 67.0 + t * 0.21) * 0.5 + 0.5;
	vec3 water = mix(deep_color, mid_color, smoothstep(0.16, 0.78, light_mix));
	water = mix(water, shallow_color, clamp(macro * macro_contrast, 0.0, 0.28));
	water *= 0.94 + (broad - 0.5) * micro_contrast;
	water += shallow_color * max(micro - 0.79, 0.0) * 0.045;
	vec2 normal_uv = UV * 8.2 + vec2(t * 0.0085, t * -0.0055);
	vec2 normal_uv_b = UV.yx * 13.5 + vec2(t * -0.0045, t * 0.0060);
	vec3 normal_a = texture(water_normal, normal_uv).rgb * 2.0 - 1.0;
	vec3 normal_b = texture(water_normal, normal_uv_b).rgb * 2.0 - 1.0;
	vec3 normal_sample = normalize(mix(normal_a, normal_b, 0.40)) * 0.5 + 0.5;
	float foam_noise = texture(foam_texture, UV * 3.35 + vec2(t * -0.0045, t * 0.0028)).r;
	float crest = smoothstep(0.86, 1.0, light_mix) * foam_noise * 0.032;
	crest *= crest_strength / 0.032;
	// M215: sparse micro-whitecaps improve sea motion at the higher master-reference camera.
	float whitecap = smoothstep(0.91, 0.995, light_mix) * smoothstep(0.72, 0.96, foam_noise) * m215_whitecap_detail;
	ALBEDO = mix(water, foam_color, clamp(crest + whitecap, 0.0, 0.22));
	NORMAL_MAP = normal_sample;
	NORMAL_MAP_DEPTH = 0.22;
	ROUGHNESS = clamp(surface_roughness + (1.0 - light_mix) * 0.08, 0.42, 0.82);
	METALLIC = 0.0;
	SPECULAR = clamp(specular_strength, 0.10, 0.26);
}
"""
	var result := ShaderMaterial.new()
	result.shader = shader
	var normal_tex := TextureMaterialCatalog.texture("ocean_normal")
	var foam_tex := TextureMaterialCatalog.texture("ocean_foam")
	if normal_tex != null:
		result.set_shader_parameter("water_normal", normal_tex)
	if foam_tex != null:
		result.set_shader_parameter("foam_texture", foam_tex)
	return result

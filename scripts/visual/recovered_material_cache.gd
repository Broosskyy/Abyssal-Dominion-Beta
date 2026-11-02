class_name RecoveredMaterialCache
extends RefCounted
## Shared immutable materials only. Never use for per-instance wake/fade animation.

const LIMIT := 96
static var _materials: Dictionary = {}
static var _coast: ShaderMaterial


static func surface(texture_path: String, normal_path: String, tint: Color, roughness: float, double_sided := false) -> StandardMaterial3D:
	var key := JSON.stringify([texture_path, normal_path, tint.r, tint.g, tint.b, tint.a, roughness, double_sided])
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = roughness
	if double_sided:
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		material.albedo_texture = load(texture_path) as Texture2D
	if not normal_path.is_empty() and ResourceLoader.exists(normal_path):
		material.normal_enabled = true
		material.normal_texture = load(normal_path) as Texture2D
	if _materials.size() >= LIMIT:
		_materials.erase(_materials.keys()[0])
	_materials[key] = material
	return material


static func coast() -> ShaderMaterial:
	if _coast == null:
		_coast = ShaderMaterial.new()
		_coast.shader = preload("res://assets/production/shaders/recovered_coast.gdshader")
		_coast.set_shader_parameter("coast_foam", load("res://assets/recovered_test/m12/coast_foam.png"))
	return _coast


static func count() -> int:
	return _materials.size()

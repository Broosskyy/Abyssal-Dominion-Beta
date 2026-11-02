class_name VisualAssetCatalog
extends RefCounted
## Stable visual slots. Overrides never contain stats, collisions or input geometry.
const SLOTS := "res://data/visual_slots.json"
const OVERRIDES := "res://data/visual_overrides.json"
static var slots: Dictionary = {}
static var overrides: Dictionary = {}
static var textures: Dictionary = {}
static var diagnostics: Array[String] = []

static func ensure_loaded() -> void:
	if slots.is_empty(): reload_catalog()

static func reload_catalog() -> void:
	diagnostics.clear()
	slots = _read(SLOTS)
	overrides = _read(OVERRIDES)
	textures.clear()
	for kind in ["models", "ui", "vfx", "audio"]:
		if not slots.get(kind) is Dictionary: slots[kind] = {}
		if not overrides.get(kind) is Dictionary: overrides[kind] = {}
		for id in overrides[kind]:
			if not slots[kind].has(id): diagnostics.append("Unknown slot: " + str(id))

static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_note("Missing catalog: " + path)
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary or parser.data.get("schema") != 1:
		_note("Invalid catalog/schema: " + path)
		return {}
	return parser.data

static func info(kind: String, id: String) -> Dictionary:
	ensure_loaded()
	return slots.get(kind, {}).get(id, {}).duplicate(true)

static func model_override(id: String) -> Dictionary:
	ensure_loaded()
	if not overrides.models.has(id): return {}
	var value: Variant = overrides.models.get(id, {})
	if not value is Dictionary or not slots.models.has(id): return {}
	var path: String = str(value.get("path", ""))
	if not safe_path(path, ["glb"]) or not ResourceLoader.exists(path):
		_note(id + ": replacement missing/invalid; using placeholder")
		return {}
	return {"path": path, "fit_reference": value.get("fit_reference", true) == true,
		"scale": vector(value.get("scale", [1, 1, 1]), Vector3.ONE, 0.001, 1000),
		"offset": vector(value.get("offset", [0, 0, 0]), Vector3.ZERO, -1000, 1000),
		"rotation_degrees": vector(value.get("rotation_degrees", [0, 0, 0]), Vector3.ZERO, -360, 360)}


static func resource_override(kind: String, id: String, extensions: Array) -> Resource:
	ensure_loaded()
	var group: Variant = overrides.get(kind, {})
	var slot_group: Variant = slots.get(kind, {})
	if not group is Dictionary or not slot_group is Dictionary or not slot_group.has(id):
		return null
	var value: Variant = group.get(id, {})
	if not value is Dictionary:
		return null
	var path := str(value.get("path", ""))
	if not safe_path(path, extensions) or not ResourceLoader.exists(path):
		if not path.is_empty():
			_note("%s/%s: replacement missing/invalid; using fallback" % [kind, id])
		return null
	return load(path)

static func safe_path(path: String, extensions: Array) -> bool:
	return path.begins_with("res://assets/") and not path.contains("..") and not path.contains("\\") and path.get_extension().to_lower() in extensions

static func vector(value: Variant, fallback: Vector3, minimum: float, maximum: float) -> Vector3:
	if not value is Array or value.size() != 3: return fallback
	for component in value:
		if not (component is float or component is int) or not is_finite(float(component)) or component < minimum or component > maximum: return fallback
	return Vector3(value[0], value[1], value[2])

static func texture(id: String) -> Texture2D:
	ensure_loaded()
	if textures.has(id): return textures[id]
	var entry := info("ui", id)
	if entry.is_empty(): return null
	var fallback := str(entry.get("path", ""))
	var replacement: Variant = overrides.ui.get(id, {})
	var path := str(replacement.get("path", fallback)) if replacement is Dictionary else fallback
	if not safe_path(path, ["svg", "png", "webp", "jpg", "jpeg"]) or not ResourceLoader.exists(path):
		_note(id + ": UI replacement missing/invalid; using placeholder")
		path = fallback
	var result := load(path) as Texture2D
	if result == null and path != fallback: result = load(fallback) as Texture2D
	textures[id] = result
	return result

static func _note(message: String) -> void:
	if not diagnostics.has(message): diagnostics.append(message)

static func slice_margin(id: String) -> float:
	ensure_loaded()
	var replacement: Variant = overrides.ui.get(id, {})
	var value: Variant = replacement.get("slice_margin", 12) if replacement is Dictionary else 12
	if not (value is int or value is float) or not is_finite(float(value)): return 12.0
	var image := texture(id)
	var limit := minf(image.get_width(), image.get_height()) * 0.5 if image != null else 12.0
	return float(value) if value >= 0 and value <= limit else 12.0

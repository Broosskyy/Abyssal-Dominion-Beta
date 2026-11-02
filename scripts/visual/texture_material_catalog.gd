class_name TextureMaterialCatalog
extends RefCounted
const SLOTS := "res://data/m64_texture_slots.json"
const OVERRIDES := "res://data/m64_texture_overrides.json"
static var _slots: Dictionary = {}
static var _overrides: Dictionary = {}
static var _cache: Dictionary = {}

static func _ensure() -> void:
	if not _slots.is_empty(): return
	var a: Variant = JSON.parse_string(FileAccess.get_file_as_string(SLOTS))
	var b: Variant = JSON.parse_string(FileAccess.get_file_as_string(OVERRIDES))
	_slots = a.get("slots",{}) if a is Dictionary else {}
	_overrides = b.get("slots",{}) if b is Dictionary else {}

static func path_for(id: String) -> String:
	_ensure()
	var info: Dictionary = _slots.get(id,{})
	if info.is_empty(): return ""
	var fallback := str(info.get("fallback",""))
	var override: Variant = _overrides.get(id,{})
	if override is Dictionary:
		var path := str(override.get("path",""))
		if _safe(path) and ResourceLoader.exists(path): return path
	return fallback

static func texture(id: String) -> Texture2D:
	_ensure()
	if _cache.has(id): return _cache[id]
	var path := path_for(id)
	var result := load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	_cache[id] = result
	return result

static func _safe(path: String) -> bool:
	return path.begins_with("res://assets/") and not path.contains("..") and path.get_extension().to_lower() in ["png","webp","jpg","jpeg"]

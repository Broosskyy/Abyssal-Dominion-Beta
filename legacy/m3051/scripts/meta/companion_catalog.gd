class_name CompanionCatalog
extends Node

const PATH := "res://data/m152_companion_catalog.json"
static var config: Dictionary = {}
static var errors := PackedStringArray()

func _ready() -> void:
	add_to_group("companion_catalog"); _ensure(); _validate(); get_tree().root.set_meta("m152_companions", summary())

static func all() -> Array:
	_ensure(); return (config.get("companions", []) as Array).duplicate(true)

static func by_id(id: String) -> Dictionary:
	for row in all():
		if row is Dictionary and str(row.get("id", "")) == id: return (row as Dictionary).duplicate(true)
	return {}

static func summary() -> Dictionary:
	_ensure(); return {"milestone":"M152","definitions":all().size(),"active_slots":int(config.get("active_slots_initial",1)),"errors":errors.duplicate(),"valid":errors.is_empty(),"server_authority_online":true,"admin_type":"companion"}

static func _ensure() -> void:
	if not config.is_empty(): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH)); config = parsed if parsed is Dictionary else {}

static func _validate() -> void:
	errors.clear(); var ids := {}; var roles := {}
	for row in all():
		var id := str(row.get("id", "")); var role := str(row.get("role", "")); var assets := row.get("assets", {}) as Dictionary
		if id.is_empty() or ids.has(id): errors.append("duplicate_or_empty:" + id)
		ids[id] = true; roles[role] = true
		for key in ["model","icon","portrait","vfx","audio"]:
			if str(assets.get(key, "")).is_empty(): errors.append("missing_asset_%s:%s" % [key,id])
		if not ResourceLoader.exists(str(assets.get("icon", ""))): errors.append("missing_icon:" + id)
	if roles.size() < 6: errors.append("insufficient_role_variety")

class_name VisualSlotReferenceValidator
extends RefCounted
## M54 static/runtime-safe validator. It reports references; it never mutates assets.

const CODE_ROOTS := ["res://scripts", "res://data"]
const EXTENSIONS := [".gd", ".json", ".tscn"]

static func report() -> Dictionary:
	VisualAssetCatalog.ensure_loaded()
	var known: Dictionary = {}
	for kind in ["models","ui","vfx","audio"]:
		for id in VisualAssetCatalog.slots.get(kind, {}):
			known[str(id)] = kind
	var referenced: Dictionary = {}
	_scan_dir("res://scripts", referenced)
	_scan_dir("res://data", referenced)
	var unknown: Array[String] = []
	for id in referenced:
		if not known.has(id):
			unknown.append(str(id))
	unknown.sort()
	return {
		"known_slots": known.size(),
		"referenced_literal_slots": referenced.size(),
		"unknown_literal_slots": unknown,
		"catalog_diagnostics": VisualAssetCatalog.diagnostics.duplicate(),
	}

static func _scan_dir(path: String, referenced: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null: return
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if name in [".",".."]:
			name = dir.get_next()
			continue
		var child := path.path_join(name)
		if dir.current_is_dir():
			_scan_dir(child, referenced)
		elif name.get_extension().to_lower() in ["gd","json","tscn"]:
			_scan_text(FileAccess.get_file_as_string(child), referenced)
		name = dir.get_next()
	dir.list_dir_end()

static func _scan_text(text: String, referenced: Dictionary) -> void:
	# Stable slot literals are intentionally constrained to known naming families.
	var regex := RegEx.new()
	regex.compile("\"([a-z0-9_]+)\"")
	for match in regex.search_all(text):
		var id := match.get_string(1)
		if id.begins_with("ship_") or id.begins_with("npc_") or id.begins_with("island_") or id.begins_with("m42_") or id.begins_with("mastery_") or id.begins_with("shipyard_") or id.begins_with("status_") or id.begins_with("harbor_module_"):
			referenced[id] = true

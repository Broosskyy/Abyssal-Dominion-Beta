class_name AssetImportProfileCatalog
extends RefCounted
const PATH := "res://data/m58_asset_import_profiles.json"
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {}
	return _data

static func profile(id: String) -> Dictionary:
	return data().get("profiles",{}).get(id,{}).duplicate(true)

static func is_p0_wave(id: String) -> bool:
	return not profile(id).is_empty()

static func qa_lines(id: String, bounds: AABB, source_path: String, classification: String) -> Array[String]:
	var p := profile(id)
	if p.is_empty(): return []
	var result: Array[String] = []
	result.append("IMPORT · %s" % ("OK" if not source_path.is_empty() else "FEHLT"))
	result.append("QUELLE · %s" % source_path)
	result.append("KLASSE · %s" % classification)
	result.append("BOUNDING BOX · %.2f × %.2f × %.2f m" % [bounds.size.x,bounds.size.y,bounds.size.z])
	result.append("WASSERLINIE · cyan Y=0; Pivot/Unterkante visuell prüfen")
	result.append("FORWARD · +Z; Bug muss in QA-Ansicht konsistent zeigen")
	result.append("MOBILE · Silhouette/Scale/Kontrast aus Seekartenkamera prüfen")
	result.append("FALLBACK · muss bei fehlendem/ungültigem Override erhalten bleiben")
	return result

static func expected_override_path(id: String) -> String:
	return str(profile(id).get("override_example",{}).get("path",""))

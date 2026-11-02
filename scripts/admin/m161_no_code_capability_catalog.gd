class_name M161NoCodeCapabilityCatalog
extends Node
const PATH := "res://data/m161_no_code_authoring_matrix.json"
var data: Dictionary = {}
func _ready() -> void:
	add_to_group("no_code_capability_catalog")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	data = parsed if parsed is Dictionary else {}
func summary() -> Dictionary:
	var families: Dictionary = data.get("families", {})
	var types := 0
	for key in families: types += (families[key] as Array).size()
	return {"families":families.size(),"authorable_types":types,"exceptions":(data.get("exceptions_requiring_code", []) as Array).size()}

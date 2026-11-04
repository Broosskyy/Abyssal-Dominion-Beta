class_name M120PlaceholderAudit
extends RefCounted
const PATH:="res://data/m120_asset_placeholder_registry.json"
static func data()->Dictionary:
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return v if v is Dictionary else {}
static func all_ship_ids()->Array[String]:
	var out:Array[String]=[]
	for row in data().get("starter",[]):out.append(str(row.get("id","")))
	for row in data().get("main_progression",[]):out.append(str(row.get("id","")))
	return out
static func missing_contracts()->Array[String]:
	var missing:Array[String]=[]
	var d:=data()
	for group in ["starter","main_progression","void_pl36_40","world_placeholders"]:
		for row in d.get(group,[]):
			if str(row.get("id","")).is_empty() or str(row.get("fallback","")).is_empty():missing.append(group)
	return missing

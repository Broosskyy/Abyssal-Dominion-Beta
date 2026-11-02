class_name P0ReplacementQa
extends RefCounted
const PATH:="res://data/m101_p0_replacement_matrix.json"
static func data()->Dictionary:
	var parsed:=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {"assets":[]}
static func ids()->Array[String]:
	var result:Array[String]=[]
	for row in data().get("assets",[]):result.append(str(row.get("id","")))
	return result
static func status(id:String)->Dictionary:
	for row in data().get("assets",[]):
		if str(row.get("id",""))!=id:continue
		var info: Dictionary = row.duplicate(true)
		var override: Dictionary = VisualAssetCatalog.model_override(id)
		info["replacement_active"]=not override.is_empty()
		info["runtime_state"]="FINAL/OVERRIDE" if not override.is_empty() else "FALLBACK"
		info["forward_axis"]="+Z"
		info["waterline"]="Y=0"
		info["gameplay_collision"]="wrapper_owned"
		if id=="monster_early_01":info["animation_contract"]="semantic bridge; gameplay independent"
		return info
	return {"id":id,"runtime_state":"UNKNOWN"}
static func summary()->Dictionary:
	var final_count:=0
	var fallback_count:=0
	var missing_slot:=0
	for id in ids():
		var row:=status(id)
		if not bool(row.get("slot_exists",false)):missing_slot+=1
		elif bool(row.get("replacement_active",false)):final_count+=1
		else:fallback_count+=1
	return {"total":ids().size(),"final":final_count,"fallback":fallback_count,"missing_slot":missing_slot}

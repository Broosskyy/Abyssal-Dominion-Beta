class_name P0AssetPublishValidator
extends RefCounted
const PATH:="res://data/m140_p0_replacement_readiness.json"
static func validate_record(row:Dictionary)->PackedStringArray:
	var errors:=PackedStringArray();var slot:=str(row.get("asset_slot",""))
	if slot.is_empty():return errors
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary:return errors
	for asset in parsed.get("assets",[]):
		if str(asset.get("slot_id",""))!=slot:continue
		if not bool(asset.get("replacement_ready",false)):errors.append(slot+":replacement_contract_not_ready")
		var required:Array=asset.get("required_anchors",[])
		var supplied:Array=row.get("sockets",row.get("anchors",[]))
		if row.get("type","")=="ship" and not supplied.is_empty():
			for anchor in required:
				if str(anchor) not in supplied:errors.append(slot+":missing_anchor:"+str(anchor))
		break
	return errors

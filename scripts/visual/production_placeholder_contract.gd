class_name ProductionPlaceholderContract
extends RefCounted
const PATH:="res://data/m136_production_placeholder_registry.json"
const SILHOUETTES:="res://data/m138_ship_silhouette_profiles.json"
const P0_SILHOUETTES:="res://data/m141_p0_ship_silhouette_profiles.json"
static var _data:Dictionary={}
static func data()->Dictionary:
	if _data.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=parsed if parsed is Dictionary else {}
	return _data
static func slot(id:String)->Dictionary:
	for family in data().get("families",[]):
		if id in family.get("slots",[]):return {"id":id,"family":str(family.get("id","")),"priority":str(family.get("priority","")),"placeholder":str(family.get("placeholder","")),"required_anchors":family.get("required_anchors",[])}
	return {}
static func quality_profile(id:String,compact:bool)->Dictionary:
	var row:Dictionary=slot(id)
	return {"lod":"LOD1","vfx_quality":"canonical","slot_known":not row.is_empty(),"priority":row.get("priority","P3"),"responsive_ui_only":compact}
static func audit()->PackedStringArray:
	var errors:=PackedStringArray();var ids:Dictionary={}
	for family in data().get("families",[]):
		for value in family.get("slots",[]):
			var id:=str(value)
			if id.is_empty() or ids.has(id):errors.append("duplicate_or_empty:"+id)
			ids[id]=true
	return errors

static func ship_silhouette(id:String)->Dictionary:
	var p0:Variant=JSON.parse_string(FileAccess.get_file_as_string(P0_SILHOUETTES))
	if p0 is Dictionary:
		var profiles:Dictionary=p0.get("profiles",{})
		if profiles.has(id):return (profiles[id] as Dictionary).duplicate(true)
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(SILHOUETTES))
	if not parsed is Dictionary:return {}
	for row in parsed.get("profiles",[]):
		if str(row.get("slot_id",""))==id:return (row as Dictionary).duplicate(true)
	return {}

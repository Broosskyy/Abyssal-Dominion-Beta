class_name ArtifactCatalog
extends Node

const PATH := "res://data/m152_artifact_catalog.json"
static var config:Dictionary={}; static var errors:=PackedStringArray()
func _ready()->void:add_to_group("artifact_catalog");_ensure();_validate();get_tree().root.set_meta("m152_artifacts",summary())
static func all()->Array:_ensure();return (config.get("artifacts",[]) as Array).duplicate(true)
static func by_id(id:String)->Dictionary:
	for row in all():
		if row is Dictionary and str(row.get("id",""))==id:return (row as Dictionary).duplicate(true)
	return {}
static func summary()->Dictionary:_ensure();return {"milestone":"M152","definitions":all().size(),"active_slots":int(config.get("initial_active_slots",2)),"errors":errors.duplicate(),"valid":errors.is_empty(),"server_authority_online":true,"admin_type":"artifact"}
static func _ensure()->void:
	if not config.is_empty():return
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH));config=parsed if parsed is Dictionary else {}
static func _validate()->void:
	errors.clear();var ids:={};var families:={}
	for row in all():
		var id:=str(row.get("id",""));var family:=str(row.get("family",""));ids[id]=int(ids.get(id,0))+1;families[family]=true
		if id.is_empty() or int(ids[id])>1:errors.append("duplicate_or_empty:"+id)
		if not ResourceLoader.exists(str(row.get("icon",""))):errors.append("missing_icon:"+id)
		if not row.get("effect",{}) is Dictionary:errors.append("missing_effect:"+id)
	if families.size()<6:errors.append("insufficient_family_variety")

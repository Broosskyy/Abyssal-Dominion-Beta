class_name ArtifactLoadout
extends Node

var equipped: Array[String] = ["ARTIFACT-STAR-COMPASS","ARTIFACT-TIDE-BULWARK"]
func _ready()->void:add_to_group("artifact_loadout");set_meta("authority","LOCAL_PREVIEW_ONLY")
func equip(ids:Array[String])->Dictionary:
	var limit:=int(ArtifactCatalog.config.get("initial_active_slots",2))
	if ids.size()>limit:return {"ok":false,"error":"slot_limit"}
	for id in ids:
		if ArtifactCatalog.by_id(id).is_empty():return {"ok":false,"error":"unknown_artifact","id":id}
	equipped=ids.duplicate();return {"ok":true,"equipped":equipped.duplicate(),"authority":"LOCAL_PREVIEW_ONLY"}
func effect_preview()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for id in equipped:
		var row:=ArtifactCatalog.by_id(id);result.append({"id":id,"effect":row.get("effect",{}),"applied_to_gameplay":false})
	return result

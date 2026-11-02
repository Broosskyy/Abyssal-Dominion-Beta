class_name AfkRewardCatalog
extends Node

const PATH:="res://data/m152_afk_reward_profiles.json"
static var config:Dictionary={};static var errors:=PackedStringArray()
func _ready()->void:add_to_group("afk_reward_catalog");_ensure();_validate();get_tree().root.set_meta("m152_afk_rewards",summary())
static func profile(id:String)->Dictionary:
	_ensure()
	for row in config.get("profiles",[]):
		if row is Dictionary and str(row.get("id",""))==id:return (row as Dictionary).duplicate(true)
	return {}
static func profiles()->Array:_ensure();return (config.get("profiles",[]) as Array).duplicate(true)
static func cap_seconds()->int:_ensure();return int((config.get("caps",{}) as Dictionary).get("default_seconds",28800))
static func forbidden()->Array:_ensure();return (config.get("forbidden_rewards",[]) as Array).duplicate()
static func summary()->Dictionary:_ensure();return {"milestone":"M152","profiles":profiles().size(),"cap_seconds":cap_seconds(),"errors":errors.duplicate(),"valid":errors.is_empty(),"production_authority":"SERVER_REQUIRED","admin_type":"afk_reward_profile"}
static func _ensure()->void:
	if not config.is_empty():return
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH));config=parsed if parsed is Dictionary else {}
static func _validate()->void:
	errors.clear();var ids:={}
	for row in profiles():
		var id:=str(row.get("id",""));ids[id]=int(ids.get(id,0))+1
		if id.is_empty() or int(ids[id])>1:errors.append("duplicate_or_empty:"+id)
		for forbidden_id in forbidden():
			if forbidden_id in JSON.stringify(row):errors.append("forbidden_reward:"+id+":"+str(forbidden_id))
	if cap_seconds()>43200:errors.append("cap_above_master_limit")

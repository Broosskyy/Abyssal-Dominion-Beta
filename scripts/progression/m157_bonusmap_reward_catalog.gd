class_name M157BonusMapRewardCatalog
extends RefCounted
const PATH:="res://data/m157_bonusmap_rewards.json"
static func data()->Dictionary:
	if not FileAccess.file_exists(PATH):return {}
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}
static func map_row(kind:String)->Dictionary:return (data().get("maps",{}).get(kind,{}) as Dictionary).duplicate(true)
static func completion_summary(kind:String)->String:
	var reward:Dictionary=map_row(kind).get("completion_reward",{})
	var parts:Array[String]=[]
	for id in reward.keys():parts.append("%s ×%d"%[str(id).replace("_"," ").capitalize(),int(reward[id])])
	return ", ".join(parts)

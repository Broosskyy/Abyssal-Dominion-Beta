class_name MainShipRewardCatalog
extends RefCounted
const PATH := "res://data/pl6_15_ship_rewards.json"
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if not _data.is_empty(): return _data
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	_data = parsed if parsed is Dictionary else {}
	return _data

static func reward_for_boss(defeated_map_level: int) -> Dictionary:
	var tree:=Engine.get_main_loop() as SceneTree
	if tree!=null:
		for row in DynamicContentResolver.active_records(tree,"ship_reward"):
			if str(row.get("trigger","boss"))=="boss" and int(row.get("defeated_map_level",-1))==defeated_map_level:return row.duplicate(true)
	for row in data().get("boss_rewards", []):
		if int(row.get("defeated_map_level",-1)) == defeated_map_level:
			return row.duplicate(true)
	return {}

static func reward_ship_for_boss(defeated_map_level: int) -> String:
	return str(reward_for_boss(defeated_map_level).get("ship_id",""))

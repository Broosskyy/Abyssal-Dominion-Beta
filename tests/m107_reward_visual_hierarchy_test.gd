extends Node
func _ready()->void:
	var locator:=ServiceLocator.new();add_child(locator)
	var contract:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m107_reward_bundle_contract.json"))
	assert(contract.domains.has("wallet"))
	assert(contract.domains.has("inventory"))
	var hierarchy:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m107_pl1_5_visual_hierarchy.json"))
	assert(int(hierarchy.mobile.max_simultaneous_teaching_cards)==1)
	var polish:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m107_mobile_world_polish.json"))
	assert(int(polish.performance.new_world_nodes)==0)
	assert(not bool(polish.guild_objectives.capture_authority))
	print("M107_REWARD_VISUAL_HIERARCHY_PASS")

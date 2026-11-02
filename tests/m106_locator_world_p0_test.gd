extends Node
func _ready()->void:
	var local:=ServiceLocator.new()
	add_child(local)
	assert(local.is_in_group("service_locator"))
	var polish:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m106_mobile_world_polish.json"))
	assert(int(polish.world.havens_reach_module_count_before)==int(polish.world.havens_reach_module_count_after))
	assert(int(polish.performance.no_marker_budget_increase)==1)
	var checklist:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m106_p0_final_art_checklist.json"))
	assert(checklist.assets.size()==13)
	assert(int(checklist.summary.native_pass)==0)
	print("M106_LOCATOR_WORLD_P0_PASS")

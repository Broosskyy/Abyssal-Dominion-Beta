extends Node
func _ready()->void:
	var p:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m79_marker_priority.json"))
	var b:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m79_pl1_5_visual_budget.json"))
	var s:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m79_save_migration_fixtures.json"))
	assert(int(p.priority.objective)>int(p.priority.wreck))
	assert(int(p.priority.monster_warning)>int(p.priority.salvage))
	assert(int(b.sector_budget.semantic_poi_max)==4)
	assert(s.cases.size()==5)
	assert(WorldMarkerPriorityCatalog.priority("monster_warning")>WorldMarkerPriorityCatalog.priority("wreck"))
	print("M79_MARKER_WORLD_BUDGET_PASS")

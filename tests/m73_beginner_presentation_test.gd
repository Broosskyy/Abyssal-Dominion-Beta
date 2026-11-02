extends Node
func _ready()->void:
	var q:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m73_beginner_quest_presentation.json"))
	var mobile:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m73_mobile_world_readability.json"))
	var wave:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m73_asset_production_wave.json"))
	assert(q.levels.size()==5)
	assert(q.objective_order==["sink","loot","dock"])
	assert(int(mobile.poi_minimap_max)==6)
	assert(wave.next_models.size()==6)
	print("M73_BEGINNER_PRESENTATION_PASS")

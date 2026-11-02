extends Node
func _ready()->void:
	var composition:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m71_havens_reach_composition.json"))
	var poi:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m72_poi_catalog.json"))
	var migration:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m78_game_state_migration_audit.json"))
	assert(composition.modules.size()>=14)
	assert(poi.types.has("wreck_beacon"))
	assert(poi.types.has("monster_warning"))
	assert(migration.load_order[1]=="ship_roster")
	assert(migration.load_order[2]=="voyage")
	assert(not bool(migration.global_save_version_changed))
	print("M78_WORLD_CONTENT_MIGRATION_PASS")

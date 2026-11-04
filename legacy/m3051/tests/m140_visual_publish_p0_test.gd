extends Node
func _ready()->void:
	assert(WorldSectorRegistry.validate().is_empty())
	var pos:=WorldSaveMigration.sanitize_local_position([999.0,-999.0],36.0)
	assert(abs(pos.x)<=33.5 and abs(pos.z)<=33.5)
	var islands:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m139_island_silhouette_profiles.json"))
	assert((islands.get("profiles",[]) as Array).size()==20)
	var region:=RegionalNpcVisualAdapter.profile("shattered_shores")
	assert(not region.is_empty())
	var p0:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m140_p0_replacement_readiness.json"))
	assert((p0.get("assets",[]) as Array).size()==22)
	var invalid:={"schema_version":1,"config_version":"bad","content":{"records":[
		{"type":"sector","id":"SECTOR-TEST-A","name":"A","pirate_level":6,"region_id":"crimson_sea","map_position":[20,20],"neighbors":{"right":"SECTOR-TEST-B"},"enabled":true},
		{"type":"sector","id":"SECTOR-TEST-B","name":"B","pirate_level":7,"region_id":"crimson_sea","map_position":[21,20],"neighbors":{},"enabled":true}
	]}}
	assert(not ContentPublishValidator.validate_snapshot(invalid).is_empty())
	print("M140_VISUAL_PUBLISH_P0_PASS")

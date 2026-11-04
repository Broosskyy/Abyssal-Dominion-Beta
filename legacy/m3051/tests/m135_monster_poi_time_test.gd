extends Node
func _ready()->void:
	var rng:=RandomNumberGenerator.new();rng.seed=9
	var table:={"entries":[
		{"content_id":"NPC-A","kind":"npc","weight":1.0},
		{"content_id":"MON-A","kind":"monster","weight":1.0}
	]}
	assert(not DynamicSpawnTable.weighted_pick_any(table,rng,["npc","monster"]).is_empty())
	var time:=TrustedTimeService.new()
	assert(not time.trusted())
	assert(time.sync_from_server(2000000000.0,false).get("ok",true)==false)
	assert(time.sync_from_server(2000000000.0,true).get("ok",false)==true)
	assert(time.trusted())
	var row:=WorldSectorRegistry.by_id("SECTOR-001")
	assert((row.get("map_position",[]) as Array).size()>=2)
	var example:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m135_example_monster_event.json"))
	assert(ContentPublishValidator.validate_snapshot(example).is_empty())
	print("M135_MONSTER_POI_TIME_PASS")

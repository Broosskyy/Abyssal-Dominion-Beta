extends Node
func _ready()->void:
	var pool:=DynamicSpawnPoolResolver.resolve(get_tree(),{"region_id":"x"},{"id":"x","npc_slots":["NPC-A"],"monster_slots":["MON-A"],"boss_slot":"NPC-ADM-A"},["raider"])
	assert("NPC-A" in pool.npc_ids)
	assert("MON-A" in pool.monster_ids)
	assert("NPC-ADM-A" in pool.admiral_ids)
	var service:=ContentRuntimeService.new()
	assert(service.request_publish("x").get("ok",true)==false)
	var pipeline:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m133_publish_pipeline.json"))
	assert(bool(pipeline.get("no_fake_server",false)))
	print("M133_WORLD_CONTENT_PASS")

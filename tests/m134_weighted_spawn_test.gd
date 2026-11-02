extends Node
func _ready()->void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=42
	var table:={"entries":[{"content_id":"A","kind":"npc","weight":10.0},{"content_id":"B","kind":"npc","weight":1.0}]}
	assert(not DynamicSpawnTable.weighted_pick(table,rng,"npc").is_empty())
	var schema:=JSON.parse_string(FileAccess.get_file_as_string("res://data/admin_content_type_registry.json"))
	assert((schema.content_types as Dictionary).has("spawn_table"))
	assert((schema.content_types as Dictionary).has("formation"))
	var example:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m134_example_weighted_event.json"))
	assert(ContentPublishValidator.validate_snapshot(example).is_empty())
	print("M134_WEIGHTED_SPAWN_PASS")

extends Node
func _ready()->void:
	var schema:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m131_progression_admin_schema.json"))
	assert(int(schema.range[0])==1 and int(schema.range[1])==50)
	var component_errors:=ContentBehaviorEngine.validate_components([{"kind":"damage","amount":10},{"kind":"heal","hull":20}])
	assert(component_errors.is_empty())
	assert((ProgressionBandOverlay.apply(25,{"map_xp_goal":1}) as Dictionary).has("map_xp_goal"))
	print("M131_ADMIN_RUNTIME_PASS")

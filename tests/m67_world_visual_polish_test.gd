extends Node
func _ready() -> void:
	var p := JSON.parse_string(FileAccess.get_file_as_string("res://data/m67_world_visual_profiles.json"))
	var h := JSON.parse_string(FileAccess.get_file_as_string("res://data/m67_havens_reach_composition.json"))
	assert(p.profiles.size() == 4)
	assert(h.layers.size() == 8)
	for id in p.profiles:
		assert(not WorldVisualProfileCatalog.profile(str(id)).is_empty())
	print("M67_WORLD_VISUAL_POLISH_PASS")

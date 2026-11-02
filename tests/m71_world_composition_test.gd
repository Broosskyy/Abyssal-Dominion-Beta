extends Node
func _ready() -> void:
	var p:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m71_island_composition_profiles.json"))
	var h:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m71_havens_reach_composition.json"))
	var b:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m71_world_composition_budget.json"))
	assert(p.profiles.size()==6)
	assert(p.profiles.has("thin_spit"))
	assert(p.profiles.has("cliff_cove"))
	assert(h.modules.size()>=8)
	assert(bool(h.visual_only))
	assert(float(b.low.decor_density)<float(b.high.decor_density))
	print("M71_WORLD_COMPOSITION_PASS")

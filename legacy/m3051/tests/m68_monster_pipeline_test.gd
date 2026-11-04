extends Node
func _ready() -> void:
	var c := JSON.parse_string(FileAccess.get_file_as_string("res://data/m68_early_monster_asset_contract.json"))
	var p := MonsterVisualProfileCatalog.profile("monster_early_01")
	assert(c.asset_id == "monster_early_01")
	assert(c.animation_states.required.size() >= 5)
	assert(c.visual_anchors.size() == 4)
	assert(not p.is_empty())
	assert(str(c.gameplay_boundary).contains("MUST NOT"))
	print("M68_MONSTER_PIPELINE_PASS")

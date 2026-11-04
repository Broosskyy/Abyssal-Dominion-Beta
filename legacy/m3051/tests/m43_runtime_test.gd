extends Node

func _ready() -> void:
	var ux := JSON.parse_string(FileAccess.get_file_as_string("res://data/m43_combat_ux.json"))
	assert(ux is Dictionary)
	assert(int(ux.mobile.long_press_ms) == 420)
	assert(bool(ux.visual_rules.unique_ammo_trails))
	var visual := JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_visual_contract.json"))
	assert(visual is Dictionary and visual.milestone == "M43")
	for id in PlayerInventory.AMMO_IDS:
		assert(visual.ammo.has(id))
		assert(visual.ammo[id].has("trail_profile"))
	print("M43_RUNTIME_CONTRACT_PASS")

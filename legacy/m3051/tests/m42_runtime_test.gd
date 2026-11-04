extends Node

func _ready() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_visual_contract.json"))
	assert(raw is Dictionary)
	assert(raw.get("schema", 0) == 1)
	assert(raw.get("authority", "") == "visual_only_no_gameplay_values")
	assert((raw.get("ammo", {}) as Dictionary).size() == 8)
	for id in PlayerInventory.AMMO_IDS:
		assert((raw.ammo as Dictionary).has(id))
		assert(VisualAssetCatalog.info("ui", "m42_" + id).get("classification", "") == "ORIGINAL_PLACEHOLDER")
	for id in ["repair", "boost", "veil", "storm_bolt", "infernal_barrel", "crystal_barrier", "armor_corrosive", "repair_blocker", "leviathan_hook", "recall_compass"]:
		assert((raw.action_items as Dictionary).has(id))
	print("M42_RUNTIME_CONTRACT_PASS")

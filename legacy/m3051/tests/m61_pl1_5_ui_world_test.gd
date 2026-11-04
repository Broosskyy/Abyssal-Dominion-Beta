extends Node
func _ready() -> void:
	var c := JSON.parse_string(FileAccess.get_file_as_string("res://data/m61_pl1_5_ui_world_contract.json"))
	assert(c.families.cannon_ammo.size() == 8)
	assert(c.families.harpoon_payload.size() == 3)
	assert(c.families.support_payload.size() == 3)
	assert(c.families.world_nameplates.size() == 6)
	for id in PlayerInventory.AMMO_IDS:
		assert(not VisualAssetCatalog.info("ui","ui_ammo_" + id).is_empty())
	for id in ["world_nameplate_friendly","world_nameplate_neutral","world_nameplate_hostile","world_nameplate_elite","world_nameplate_admiral","world_nameplate_monster"]:
		assert(not VisualAssetCatalog.info("ui",id).is_empty())
	print("M61_PL1_5_UI_WORLD_PASS")

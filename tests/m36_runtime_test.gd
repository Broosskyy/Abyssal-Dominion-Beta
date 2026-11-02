extends SceneTree

func _init() -> void:
	var inventory_script = load("res://scripts/progression/player_inventory.gd")
	var economy = JSON.parse_string(FileAccess.get_file_as_string("res://data/early_economy.json"))
	assert(inventory_script != null)
	assert(economy is Dictionary)
	assert(economy.milestone == "M36")
	assert(economy.live_authority == false)
	assert(economy.offers.iron.price == 30)
	assert(economy.emergency_standard_ammo.minimum_stock == 30)
	print("M36_RUNTIME_CONTRACT_PASS")
	quit()

extends Node

func _ready() -> void:
	var status := JSON.parse_string(FileAccess.get_file_as_string("res://data/status_visuals.json"))
	var matrix := JSON.parse_string(FileAccess.get_file_as_string("res://data/asset_replacement_matrix.json"))
	var future := JSON.parse_string(FileAccess.get_file_as_string("res://data/production_future_slots.json"))
	assert(status is Dictionary)
	assert(status.statuses.size() >= 9)
	assert(matrix is Dictionary)
	assert(matrix.principles.missing_final_assets_never_break_gameplay == true)
	assert(future.ships.size() == 50)
	assert(future.island_bases.size() == 20)
	VisualAssetCatalog.reload_catalog()
	assert(not VisualAssetCatalog.info("ui", "status_burn").is_empty())
	assert(not VisualAssetCatalog.info("vfx", "ammo_ember_impact").is_empty())
	print("M45_RUNTIME_CONTRACT_PASS")

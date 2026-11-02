extends Node
func _ready() -> void:
	var contract := JSON.parse_string(FileAccess.get_file_as_string("res://data/m50_consolidation_contract.json"))
	var report := JSON.parse_string(FileAccess.get_file_as_string("res://data/m50_missing_assets_report.json"))
	assert(contract.consolidation.dedicated_harbor_equipment_screen == true)
	assert(contract.consolidation.harbor_module_replacement_adapter == true)
	assert(report.total_slots > 0)
	assert(report.missing_by_priority.has("P0"))
	assert(ProductionCoverage.report().total > 0)
	print("M50_CONSOLIDATION_CONTRACT_PASS")

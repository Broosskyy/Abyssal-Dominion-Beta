extends Node
func _ready() -> void:
	var contract := JSON.parse_string(FileAccess.get_file_as_string("res://data/m54_contract.json"))
	var defense := JSON.parse_string(FileAccess.get_file_as_string("res://data/m54_defense_stack.json"))
	var references := JSON.parse_string(FileAccess.get_file_as_string("res://data/m54_visual_reference_report.json"))
	assert(contract.risk_repair.alpha_tween_subproperties_removed == true)
	assert(contract.risk_repair.quickbar_ammo_icon_mapping_fixed == true)
	assert(defense.order[1] == "temporary barrier pool")
	assert(defense.order[2] == "shield pool")
	assert(references.unknown_explicit_references.size() == 0)
	print("M54_RISK_REPAIR_CONTRACT_PASS")

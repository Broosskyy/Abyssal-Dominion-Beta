extends Node
func _ready() -> void:
	var modules := JSON.parse_string(FileAccess.get_file_as_string("res://data/regional_equipment_modules.json"))
	var roles := JSON.parse_string(FileAccess.get_file_as_string("res://data/regional_npc_roles.json"))
	var harbor := JSON.parse_string(FileAccess.get_file_as_string("res://data/harbor_module_slots.json"))
	var contract := JSON.parse_string(FileAccess.get_file_as_string("res://data/m49_runtime_contract.json"))
	assert(modules.modules.size() == 6)
	assert(modules.rules.slots.size() == 4)
	assert(roles.regions.size() == 3)
	assert(harbor.modules.size() == 4)
	assert(contract.runtime.overheal_contribution == 0)
	assert(not RegionalEquipmentCatalog.module("veil_support_core").is_empty())
	print("M49_RUNTIME_CONTRACT_PASS")

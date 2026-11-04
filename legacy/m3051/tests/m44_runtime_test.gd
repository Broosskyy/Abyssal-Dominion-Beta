extends Node

func _ready() -> void:
	assert(PlayerInventory.QUICK_SLOT_COUNT == 4)
	assert(PlayerInventory.DEFAULT_QUICK_SLOTS.size() == 4)
	assert(PlayerInventory.DEFAULT_QUICK_SLOTS[0].id == "iron")
	assert(PlayerInventory.DEFAULT_QUICK_SLOTS[3].id == "veil")
	var contract := JSON.parse_string(FileAccess.get_file_as_string("res://data/m44_quickbar_contract.json"))
	assert(contract is Dictionary)
	assert(contract.quickbar.per_ship_persistent == true)
	assert(contract.quickbar.supported_binding_kinds.size() == 4)
	print("M44_RUNTIME_CONTRACT_PASS")

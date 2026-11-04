extends Node

func _ready() -> void:
	assert(PlayerInventory.AMMO_IDS.size() == 8)
	assert(CombatCatalog.AMMO.size() == 8)
	for id in ["iron", "explosive", "chain", "piercing", "ember", "venom", "shatter", "spectral"]:
		assert(PlayerInventory.START_STOCK.has(id))
	assert(PlayerInventory.START_STOCK.has("veil"))
	assert(CombatCatalog.AMMO[4].effect == "burn")
	assert(CombatCatalog.AMMO[5].effect == "venom")
	assert(CombatCatalog.AMMO[6].effect == "armor_break")
	assert(CombatCatalog.AMMO[7].effect == "spectral_mark")
	print("M40_RUNTIME_CONTRACT_PASS")

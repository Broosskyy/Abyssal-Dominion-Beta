extends SceneTree

func _init() -> void:
	assert(CombatSupportContracts.validate().is_empty())
	assert(EquipmentEconomyContracts.validate().is_empty())
	assert(GuildWorldHooks.validate().is_empty())
	var support := CombatSupportContracts.read()
	assert(support.supplies.powder.consume_rule == "valid_cannon_salvo_only")
	assert(support.supplies.plates.consume_rule == "valid_incoming_damage_only")
	assert(support.support_weapon.overheal_contribution == 0)
	var economy := EquipmentEconomyContracts.read()
	assert(economy.upgrade_rules.normal_failure_destroys_valuable_equipment == false)
	var guild := GuildWorldHooks.read()
	assert(guild.persistence == false)
	assert(guild.server_authority_required == true)
	print("M37_RUNTIME_CONTRACT_PASS")
	quit()

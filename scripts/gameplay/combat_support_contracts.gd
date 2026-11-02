class_name CombatSupportContracts
extends RefCounted

const PATH := "res://data/combat_support_contracts.json"

static func read() -> Dictionary:
	if not FileAccess.file_exists(PATH): return {}
	var value = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return value if value is Dictionary else {}

static func validate() -> Array[String]:
	var errors: Array[String] = []
	var data := read()
	if data.get("schema", 0) != 1 or data.get("milestone", "") != "M37": errors.append("support schema")
	if data.get("live_authority_required", false) != true: errors.append("support authority boundary")
	var supplies: Dictionary = data.get("supplies", {})
	if supplies.get("powder", {}).get("consume_rule", "") != "valid_cannon_salvo_only": errors.append("powder consume rule")
	if supplies.get("plates", {}).get("consume_rule", "") != "valid_incoming_damage_only": errors.append("plate consume rule")
	if data.get("support_weapon", {}).get("overheal_contribution", -1) != 0: errors.append("overheal contribution")
	return errors

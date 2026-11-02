class_name EquipmentEconomyContracts
extends RefCounted

const PATH := "res://data/equipment_economy.json"

static func read() -> Dictionary:
	if not FileAccess.file_exists(PATH): return {}
	var value = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return value if value is Dictionary else {}

static func recipe(id: String) -> Dictionary:
	var value: Variant = read().get("prototype_recipes", {}).get(id, {})
	return value.duplicate(true) if value is Dictionary else {}

static func validate() -> Array[String]:
	var errors: Array[String] = []
	var data := read()
	if data.get("schema", 0) != 1 or data.get("milestone", "") not in ["M37", "M48"]: errors.append("equipment economy schema")
	var rules: Dictionary = data.get("upgrade_rules", {})
	if rules.get("uses_gold_and_material_components", false) != true: errors.append("upgrade material rule")
	if rules.get("normal_failure_destroys_valuable_equipment", true) != false: errors.append("destructive upgrade rule")
	return errors

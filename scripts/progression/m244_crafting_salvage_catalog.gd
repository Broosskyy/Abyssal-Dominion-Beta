class_name M244CraftingSalvageCatalog
extends RefCounted

const PATH := "res://data/m244_crafting_salvage_contract.json"

static func read() -> Dictionary:
	if not FileAccess.file_exists(PATH): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}

static func categories() -> Array:
	return read().get("crafting_categories", []) as Array

static func recipe_category(recipe_id: String) -> String:
	return str((read().get("recipe_category_overrides", {}) as Dictionary).get(recipe_id, "supplies"))

static func salvage_return_for_module(module_id: String, definition: Dictionary) -> Dictionary:
	var contract := read()
	var overrides: Dictionary = contract.get("salvage_overrides", {}) as Dictionary
	if overrides.has(module_id) and overrides[module_id] is Dictionary:
		return (overrides[module_id] as Dictionary).duplicate(true)
	if bool(definition.get("salvage_allowed", true)) == false:
		return {}
	var binding := str(definition.get("binding", "unbound"))
	if binding in ["bound", "special", "quest", "event_locked"]:
		return {}
	var cost: Dictionary = definition.get("cost", {}) as Dictionary
	var materials: Dictionary = cost.get("materials", {}) as Dictionary
	var fraction := clampf(float((contract.get("prototype_salvage", {}) as Dictionary).get("return_fraction", 0.0)), 0.0, 1.0)
	var result: Dictionary = {}
	for material in materials:
		var amount := int(floor(float(materials[material]) * fraction))
		if amount > 0: result[str(material)] = amount
	return result

static func gold_refund_allowed() -> bool:
	return bool((read().get("prototype_salvage", {}) as Dictionary).get("gold_refund", false))

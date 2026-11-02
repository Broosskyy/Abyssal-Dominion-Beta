class_name GameplayRuleset
extends RefCounted
const PATH:="res://data/m129_gameplay_rules_defaults.json"
static var _fallback:Dictionary={}
static func fallback()->Dictionary:
	if _fallback.is_empty():
		var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH));_fallback=v if v is Dictionary else {}
	return _fallback
static func rule_value(tree: SceneTree, rule_path: String, default: Variant = null) -> Variant:
	var registry := LiveConfigRegistry.current(tree) if tree != null else null
	if registry != null:
		var remote: Variant = registry.value_at("rules." + rule_path, null)
		if remote != null:
			return remote
	var node: Variant = fallback()
	for key in rule_path.split("."):
		if not node is Dictionary or not (node as Dictionary).has(key):
			return default
		node = (node as Dictionary)[key]
	return node

static func dictionary(tree: SceneTree, path: String, default: Dictionary = {}) -> Dictionary:
	var value: Variant = rule_value(tree, path, default)
	return (value as Dictionary).duplicate(true) if value is Dictionary else default.duplicate(true)

static func array(tree: SceneTree, path: String, default: Array = []) -> Array:
	var value: Variant = rule_value(tree, path, default)
	return (value as Array).duplicate(true) if value is Array else default.duplicate(true)

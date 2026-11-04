class_name WorldVisualBudgetCatalog
extends RefCounted
const PATH := "res://data/m63_world_visual_budgets.json"
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {}
	return _data

static func tier(tree: SceneTree) -> Dictionary:
	var id := str(tree.root.get_meta("quality_tier","high")) if tree != null else "high"
	return data().get("tiers",{}).get(id, data().get("tiers",{}).get("high",{})).duplicate(true)

static func int_value(tree: SceneTree, key: String, fallback: int) -> int:
	return maxi(0, int(tier(tree).get(key,fallback)))

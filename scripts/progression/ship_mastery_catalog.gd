class_name ShipMasteryCatalog
extends RefCounted
const PATH := "res://data/ship_mastery.json"
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if not _data.is_empty(): return _data
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	_data = parsed if parsed is Dictionary else {}
	return _data

static func runtime_data()->Dictionary:
	var tree:=Engine.get_main_loop() as SceneTree
	var registry:=LiveConfigRegistry.current(tree) if tree!=null else null
	var override:=registry.dictionary("rules.ship_mastery",{}) if registry!=null else {}
	return override if not override.is_empty() else data()
static func max_level() -> int:
	return int(runtime_data().get("max_level",10))

static func xp_to_next(level: int) -> int:
	if level >= max_level(): return 0
	return int(runtime_data().get("xp_curve_to_next_level", {}).get(str(level), 150 * level))

static func progress(level: int, xp: int) -> float:
	if level >= max_level(): return 1.0
	return clampf(float(xp) / maxf(1.0, float(xp_to_next(level))), 0.0, 1.0)

static func milestone(level: int) -> Dictionary:
	var value: Variant = runtime_data().get("milestones", {}).get(str(level), {})
	return value.duplicate(true) if value is Dictionary else {}

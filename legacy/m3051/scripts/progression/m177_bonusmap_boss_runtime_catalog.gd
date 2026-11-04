class_name M177BonusMapBossRuntimeCatalog
extends RefCounted

const PATH := "res://data/m177_bonusmap_boss_runtime.json"
static var _cache: Dictionary = {}

static func data() -> Dictionary:
	if _cache.is_empty(): _cache = JsonDataLoader.load_dictionary(PATH)
	return _cache

static func map_profile(id: String) -> Dictionary:
	return ((data().get("maps", {}) as Dictionary).get(id, {}) as Dictionary).duplicate(true)

static func mechanic(id: String) -> Dictionary:
	return ((data().get("mechanics", {}) as Dictionary).get(id, {}) as Dictionary).duplicate(true)

static func reward_rarity(map_id: String) -> String:
	return str(map_profile(map_id).get("reward_rarity", "rare"))

class_name ShipCatalog
extends RefCounted

const SHIPS := [
	{
		"id": "clipper",
		"display_name": "Clipper",
		"role": "Balanced broadside frigate",
		"price": 0,
		"hull": 1000.0,
		"armor": 0.08,
		"speed": 6.5,
		"acceleration": 3.2,
		"turn_speed": 56.0,
		"damage": 72.0,
	},
	{
		"id": "barco_low",
		"display_name": "Swift Barco",
		"role": "Fast scout and loot runner",
		"price": 600,
		"hull": 720.0,
		"armor": 0.04,
		"speed": 8.2,
		"acceleration": 4.4,
		"turn_speed": 74.0,
		"damage": 61.0,
	},
	{
		"id": "chalupa",
		"display_name": "Iron Chalupa",
		"role": "Armored close-range vessel",
		"price": 1200,
		"hull": 1350.0,
		"armor": 0.16,
		"speed": 5.4,
		"acceleration": 2.6,
		"turn_speed": 44.0,
		"damage": 84.0,
	},
]


static func _overlay(profile:Dictionary)->Dictionary:
	var out:=profile.duplicate(true)
	var tree:=Engine.get_main_loop() as SceneTree
	if tree==null:return out
	var registry:=LiveConfigRegistry.current(tree)
	if registry==null:return out
	var override:=registry.dictionary("ships."+str(out.get("id","")),{})
	for key in override.keys():out[key]=override[key]
	return out
static func ship(index: int) -> Dictionary:
	return _overlay(SHIPS[posmod(index, SHIPS.size())])


static func profile_by_id(ship_id: String) -> Dictionary:
	var tree:=Engine.get_main_loop() as SceneTree
	if tree!=null:
		var dynamic:=DynamicContentResolver.by_id(tree,"ship",ship_id)
		if not dynamic.is_empty():return dynamic
	for profile in SHIPS:
		if str(profile.id) == ship_id:
			return _overlay(profile)
	var design := MainProgressionFleet.design(ship_id)
	if design.is_empty():
		return SHIPS[0]
	var fallback_id := str(design.get("fallback_profile", BeginnerRules.START_SHIP))
	var base := SHIPS[0].duplicate(true)
	for profile in SHIPS:
		if str(profile.id) == fallback_id:
			base = profile.duplicate(true)
			break
	var number := 100 if design.has("prestige_rank") else maxi(1, int(ship_id.trim_prefix("ship_main_")))
	var tier := clampi((number - 1) / 5, 0, 9)
	base.id = ship_id
	base.display_name = str(design.get("display_name", ship_id))
	base.role = "Main progression · %s · placeholder visual" % str(design.get("role", "balanced"))
	base.price = 0
	var main_tree:=Engine.get_main_loop() as SceneTree
	var registry:=LiveConfigRegistry.current(main_tree) if main_tree!=null else null
	var scaling:=registry.dictionary("ships.main_progression_scaling",{}) if registry!=null else {}
	base.hull = float(base.hull) * (1.0 + tier * float(scaling.get("hull_per_tier",0.035)))
	base.damage = float(base.damage) * (1.0 + tier * float(scaling.get("damage_per_tier",0.03)))
	base.speed = float(base.speed) * (1.0 + tier * float(scaling.get("speed_per_tier",0.01)))
	return base


static func index_of(ship_id: String) -> int:
	for index in SHIPS.size():
		if str(SHIPS[index].id) == ship_id:
			return index
	return 0


static func has_ship(ship_id: String) -> bool:
	var tree:=Engine.get_main_loop() as SceneTree
	if tree!=null and not DynamicContentResolver.by_id(tree,"ship",ship_id).is_empty():return true
	for profile in SHIPS:
		if str(profile.id) == ship_id:
			return true
	return not MainProgressionFleet.design(ship_id).is_empty()


static func mastery_scaled_profile(ship_id: String, mastery_level: int) -> Dictionary:
	var profile := profile_by_id(ship_id).duplicate(true)
	var level := clampi(mastery_level, 1, ShipMasteryCatalog.max_level())
	var tree:=Engine.get_main_loop() as SceneTree
	var registry:=LiveConfigRegistry.current(tree) if tree!=null else null
	var scaling:=registry.dictionary("ships.main_progression_scaling",{}) if registry!=null else {}
	var bonus := 1.0 + float(level - 1) * float(scaling.get("mastery_stat_per_level",0.02))
	profile.hull = float(profile.hull) * bonus
	profile.damage = float(profile.damage) * bonus
	return profile


static func stat_deltas(current_id: String, current_level: int, candidate_id: String, candidate_level: int) -> Dictionary:
	var current := mastery_scaled_profile(current_id, current_level)
	var candidate := mastery_scaled_profile(candidate_id, candidate_level)
	return {
		"hull": float(candidate.hull) - float(current.hull),
		"damage": float(candidate.damage) - float(current.damage),
		"speed": float(candidate.speed) - float(current.speed),
		"armor": float(candidate.armor) - float(current.armor),
		"turn_speed": float(candidate.turn_speed) - float(current.turn_speed),
	}

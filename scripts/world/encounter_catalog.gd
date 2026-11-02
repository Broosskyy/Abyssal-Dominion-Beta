class_name EncounterCatalog
extends RefCounted

const DATA_PATH := "res://data/encounters.json"

var data: Dictionary = {}


func _init() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if parsed is Dictionary:
		data = parsed
	else:
		push_error("Missing or invalid encounter catalog: " + DATA_PATH)


func biome_profile(biome: String) -> Dictionary:
	return data.get("biomes", {}).get(biome, {})


func npc_profile(archetype: String, level: int, admiral: bool = false, elite: bool = false) -> Dictionary:
	var base: Dictionary = data.get("archetypes", {}).get(archetype, {}).duplicate(true)
	if base.is_empty():
		return {}
	var scaling: Dictionary = data.scaling
	var tree:=Engine.get_main_loop() as SceneTree
	var registry:=LiveConfigRegistry.current(tree) if tree!=null else null
	if registry!=null:
		var npc_cfg:Dictionary=registry.dictionary("npc",{})
		# Future verified snapshots can embed full archetypes/scaling; source path remains fallback.
		var archetypes:Variant=npc_cfg.get("archetypes",{})
		if archetypes is Dictionary and (archetypes as Dictionary).has(archetype):
			for key in (archetypes as Dictionary)[archetype].keys():base[key]=(archetypes as Dictionary)[archetype][key]
		var scale_override:Variant=npc_cfg.get("scaling",{})
		if scale_override is Dictionary:
			for key in scale_override.keys():scaling[key]=scale_override[key]
	var difficulty: int = maxi(0, level - 1)
	base.hull = float(base.hull) * (1.0 + difficulty * float(scaling.hull_per_level))
	base.damage = float(base.damage) * (1.0 + difficulty * float(scaling.damage_per_level))
	var reward_scale: float = 1.0 + difficulty * float(scaling.reward_per_level)
	if elite and not admiral:
		var elite_data: Dictionary = data.get("elite", {})
		base.hull *= float(elite_data.get("hull_multiplier", 1.2))
		base.damage *= float(elite_data.get("damage_multiplier", 1.1))
		reward_scale *= float(elite_data.get("reward_multiplier", 1.3))
	if admiral:
		base.hull *= float(data.admiral.hull_multiplier)
		base.damage *= float(data.admiral.damage_multiplier)
		reward_scale *= float(data.admiral.reward_multiplier)
	base.xp = roundi(float(base.xp) * reward_scale)
	base.coins = roundi(float(base.coins) * reward_scale)
	return base


func loot_profile(tier: String) -> Dictionary:
	return data.get("loot_tiers", {}).get(tier, {"multiplier": 1.0, "label": "SALVAGE"})

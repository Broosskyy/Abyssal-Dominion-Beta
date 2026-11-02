class_name ItemUiIconCatalog
extends RefCounted

const M204_ITEM_IDS := ["wood", "metal", "components", "stormglass", "ember_ore", "veil_silk", "reinforced_timber", "precision_gears", "admiral_component", "abyss_scale", "corrupted_pearl", "ancient_guardian_fragment", "legendary_fragment", "ancient_relic_core", "dominion_shard", "sun_core_fragment", "guild_masonry", "ward_resin", "arcane_shard", "siege_core", "harpoon_tempered", "harpoon_stormhook", "harpoon_relic", "ward_tonic", "powder_charge", "hunter_flare", "siege_repair_kit", "master_gunlock", "citadel_blueprint", "siege_beacon", "ward_crystal", "siege_powder", "silver_chart_fragment", "gold_chart_fragment", "abyss_chart_fragment", "gold_map_token", "legendary_command_seal", "dominion_crest", "talent_compass", "talent_chart"]

const ITEM_IDS := [
	"crystal_blessing", "sea_chart", "repair_crew", "smoke_screen", "war_banner",
	"tower_parts", "guild_timber", "guild_steel", "enchanted_rope", "cannon_oil",
	"monster_bait", "admiral_seal"
]

static func slot(id: String) -> String:
	if id in ["harpoon", "harpoon_tempered", "harpoon_stormhook", "harpoon_relic"]:
		return M206DeckEquipmentPresentationCatalog.harpoon_icon_slot(id)
	if id in M204_ITEM_IDS:
		return "ui_item_" + id
	if id in ITEM_IDS:
		return "ui_item_" + id
	return CombatUiIconCatalog.slot(id)

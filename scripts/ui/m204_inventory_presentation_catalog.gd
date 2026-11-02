class_name M204InventoryPresentationCatalog
extends RefCounted

const MATERIALS := ["wood", "metal", "components", "stormglass", "ember_ore", "veil_silk", "reinforced_timber", "precision_gears", "admiral_component", "abyss_scale", "corrupted_pearl", "ancient_guardian_fragment", "legendary_fragment", "ancient_relic_core", "dominion_shard", "sun_core_fragment", "guild_masonry", "ward_resin", "arcane_shard", "siege_core"]
const EQUIPMENT := ["harpoon_tempered", "harpoon_stormhook", "harpoon_relic", "ward_tonic", "powder_charge", "hunter_flare", "siege_repair_kit", "master_gunlock", "citadel_blueprint", "siege_beacon", "ward_crystal", "siege_powder"]
const CURRENCIES := ["silver_chart_fragment", "gold_chart_fragment", "abyss_chart_fragment", "gold_map_token", "legendary_command_seal", "dominion_crest"]
const NAVIGATION := ["talent_compass", "talent_chart"]

static func icon_slot(id:String)->String:
	var slot := ItemUiIconCatalog.slot(id)
	return slot

static func category(id:String)->String:
	if id in MATERIALS: return "MATERIAL"
	if id in EQUIPMENT: return "AUSRÜSTUNG"
	if id in CURRENCIES: return "KARTEN & SIEGEL"
	if id in NAVIGATION: return "FORTSCHRITT"
	if CombatCatalog.ammo_index_by_id(id) >= 0: return "MUNITION"
	if id in ActionItemCatalog.item_ids() or id in ["powder","plates"]: return "AKTIV-ITEM"
	if id.begins_with("harpoon") or id in ["hunter_standard","barbed_chain","abyss_piercer"]: return "HARPUNE"
	return "VORRAT"

static func compact_label(id:String)->String:
	return id.replace("_", " ").capitalize()

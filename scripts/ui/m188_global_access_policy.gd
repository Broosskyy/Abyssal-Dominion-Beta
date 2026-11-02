class_name M188GlobalAccessPolicy
extends RefCounted
## M188 keeps global meta routes distinct from physical harbor interaction.

const GLOBAL_ROUTES := ["ships", "shipyard", "equipment", "loadouts", "quests", "events", "guild", "rankings", "itemshop", "progression"]
const HARBOR_LOCAL := ["repair_service", "local_supply_market", "regional_vendor", "regional_crafting", "harbor_npc", "harbor_quest", "harbor_event_hook"]

static func is_global_route(id:String)->bool:
	return id in GLOBAL_ROUTES

static func contextual_target_action(player:Node)->String:
	return "harbor" if player != null and player.has_meta("nearby_port") else "target"

static func harbor_entry_label(player:Node)->String:
	return "HAFEN" if contextual_target_action(player) == "harbor" else "ZIEL"

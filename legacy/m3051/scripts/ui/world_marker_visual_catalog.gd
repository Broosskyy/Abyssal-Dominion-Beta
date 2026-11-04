class_name WorldMarkerVisualCatalog
extends RefCounted

const SERVICES := {
	"shipyard":"service_shipyard", "repair":"service_repair", "market":"service_market",
	"arsenal":"service_arsenal", "quests":"service_quests"
}
const MARKERS := {
	"quest":"marker_quest", "objective":"marker_objective", "loot":"marker_loot",
	"repair":"marker_repair", "monster":"marker_monster", "elite":"marker_elite",
	"admiral":"marker_admiral", "port":"minimap_port", "player":"minimap_player",
	"salvage":"m72_poi_salvage", "wreck":"m72_poi_wreck", "shrine":"m72_poi_shrine",
	"monster_nest":"m72_poi_nest", "monster_warning":"m76_first_monster",
	"wreck_beacon":"m72_poi_wreck", "navigation":"m72_poi_navigation", "supply":"m72_poi_supply"
}

static func service_slot(id: String) -> String:
	return str(SERVICES.get(id,"world_interact"))

static func marker_slot(id: String) -> String:
	return str(MARKERS.get(id,"world_interact"))

static func port_slot(safe: bool = true) -> String:
	return "world_safe_harbor" if safe else "minimap_port"

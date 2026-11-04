class_name M228LivingSeaEncounterCatalog
extends RefCounted

## Presentation/movement identity for existing encounter slots.
## Spawn counts, combat stats, rewards and event authority remain elsewhere.
const REGION_TEMPERAMENT := {
	"shattered_shores": "coastal_patrol",
	"crimson_sea": "raider_sweep",
	"drowned_reach": "wreck_hunter",
	"stormbound_expanse": "storm_screen",
	"cursed_dominion": "cursed_hunt",
	"abyssal_frontier": "rift_patrol",
	"sunken_empire": "relic_guard",
	"void_sea": "void_stalk",
	"sovereign_waters": "formation_patrol",
	"abyssal_dominion": "dominion_hunt",
	"dreadwater_march": "marching_line",
	"iron_maw_reach": "siege_screen"
}

static func profile(region_id:String, kind:String, slot:int, passive_until_attacked:bool)->Dictionary:
	var normalized_kind := "monster" if kind == "monster" else ("admiral" if kind == "admiral" else "patrol")
	var temperament := str(REGION_TEMPERAMENT.get(region_id, "open_sea_patrol"))
	var route_radius := 7.5 + float(posmod(slot, 3)) * 2.25
	var route_speed := 0.30 + float(posmod(slot + 1, 3)) * 0.05
	if normalized_kind == "monster":
		route_radius = 10.5
		route_speed = 0.24
	elif normalized_kind == "admiral":
		route_radius = 5.5
		route_speed = 0.18
	return {
		"temperament": temperament,
		"patrol_pattern": "territory_orbit" if normalized_kind == "monster" else ("staging_orbit" if normalized_kind == "admiral" else "lane_orbit"),
		"route_radius": route_radius,
		"route_speed": route_speed,
		"relation_read": "neutral_until_attacked" if passive_until_attacked else ("boss_hostile" if normalized_kind == "admiral" else "hostile"),
		"world_role": normalized_kind,
		"region_id": region_id,
		"slot": slot,
		"world_read_priority": 3 if normalized_kind == "admiral" else (2 if normalized_kind == "monster" else 1),
		"safe_lane_respected": normalized_kind != "admiral"
	}

static func apply(ship:ShipMotor, region_id:String, kind:String, slot:int, passive_until_attacked:bool)->void:
	if ship == null:return
	var p:=profile(region_id,kind,slot,passive_until_attacked)
	ship.set_meta("m228_living_sea_profile",p)
	ship.set_meta("m228_patrol_pattern",str(p.get("patrol_pattern","lane_orbit")))
	ship.set_meta("m228_patrol_radius",float(p.get("route_radius",8.0)))
	ship.set_meta("m228_patrol_pace",float(p.get("route_speed",0.32)))
	ship.set_meta("m228_relation_read",str(p.get("relation_read","hostile")))
	ship.set_meta("m228_region_temperament",str(p.get("temperament","open_sea_patrol")))
	ship.set_meta("m228_world_read_priority",int(p.get("world_read_priority",1)))

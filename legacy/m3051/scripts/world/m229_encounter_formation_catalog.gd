class_name M229EncounterFormationCatalog
extends RefCounted

## Readable group/territory identity layered onto existing M228 encounter slots.
## It never creates ships, changes stats, or owns navigation/combat authority.
const REGION_FORMATION := {
	"shattered_shores":"loose_column", "crimson_sea":"raider_wedge", "drowned_reach":"wreck_arc",
	"stormbound_expanse":"storm_line", "cursed_dominion":"hunt_pair", "abyssal_frontier":"rift_screen",
	"sunken_empire":"relic_guard", "void_sea":"stalker_arc", "sovereign_waters":"naval_column",
	"abyssal_dominion":"dominion_wedge", "dreadwater_march":"march_line", "iron_maw_reach":"siege_screen"
}

static func profile(region_id:String, kind:String, slot:int, rank:String)->Dictionary:
	var normalized := "monster" if kind == "monster" else ("admiral" if kind == "admiral" else "patrol")
	var role := "territory" if normalized == "monster" else ("command" if normalized == "admiral" else "formation")
	var danger := "boss" if normalized == "admiral" else ("territory" if normalized == "monster" else ("elite" if rank == "elite" else "standard"))
	return {
		"formation_read": str(REGION_FORMATION.get(region_id,"loose_column")),
		"formation_slot": posmod(slot,3),
		"group_role": role,
		"danger_read": danger,
		"territory_read": "monster_realm" if normalized == "monster" else ("admiral_staging" if normalized == "admiral" else "regional_patrol_lane"),
		"event_zone_ready": true,
		"member_spacing_visual": 5.5 + float(posmod(slot,2))*1.5,
		"world_read_priority": 4 if normalized == "admiral" else (3 if normalized == "monster" else (2 if rank == "elite" else 1))
	}

static func apply(ship:ShipMotor, region_id:String, kind:String, slot:int, rank:String)->void:
	if ship == null:return
	var p:=profile(region_id,kind,slot,rank)
	ship.set_meta("m229_encounter_formation",p)
	ship.set_meta("m229_formation_read",str(p.formation_read))
	ship.set_meta("m229_formation_slot",int(p.formation_slot))
	ship.set_meta("m229_group_role",str(p.group_role))
	ship.set_meta("m229_danger_read",str(p.danger_read))
	ship.set_meta("m229_territory_read",str(p.territory_read))
	ship.set_meta("m229_event_zone_ready",true)
	ship.set_meta("m229_member_spacing_visual",float(p.member_spacing_visual))
	ship.set_meta("m229_world_read_priority",int(p.world_read_priority))

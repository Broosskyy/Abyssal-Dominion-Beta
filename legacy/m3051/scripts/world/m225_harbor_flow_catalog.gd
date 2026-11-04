class_name M225HarborFlowCatalog
extends RefCounted
## M225 presentation/state contract for harbor arrival, docking and leaving.
## Navigation/collision remain authoritative in existing world/player systems.

const SERVICES := ["shipyard", "repair", "market", "arsenal"]
const SERVICE_LABELS := {
	"shipyard": "WERFT",
	"repair": "REPARATUR",
	"market": "MARKT",
	"arsenal": "ARSENAL"
}

static func dock_state(player:Node)->String:
	if player == null: return "at_sea"
	if bool(player.get_meta("m225_docked", false)): return "docked"
	if player.has_meta("nearby_port"): return "approach"
	return "at_sea"

static func state_label(player:Node)->String:
	match dock_state(player):
		"docked": return "ANGELEGT"
		"approach": return "HAFEN IN REICHWEITE"
		_: return "AUF SEE"

static func primary_action(player:Node)->String:
	return "ABLEGEN" if dock_state(player) == "docked" else "ANLEGEN"

static func service_route(service_id:String)->String:
	match service_id:
		"shipyard": return "progress"
		"market": return "shop"
		"arsenal": return "equipment"
		"repair": return "harbor"
		_: return "harbor"

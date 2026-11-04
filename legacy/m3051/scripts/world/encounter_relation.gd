class_name EncounterRelation
extends RefCounted
## Presentation-only relation contract for local encounters.
## It does not grant/deny targeting, rewards or authoritative PvP rights.
const PLAYER := "PLAYER"
const NEUTRAL := "NEUTRAL"
const HOSTILE := "HOSTILE"

static func status(ship: Node) -> String:
	if ship == null:
		return HOSTILE
	if ship.is_in_group("player"):
		return PLAYER
	if bool(ship.get_meta("passive_until_attacked", false)) and not bool(ship.get_meta("provoked", false)):
		return NEUTRAL
	return HOSTILE

static func label(ship: Node) -> String:
	match status(ship):
		PLAYER: return "PLAYER"
		NEUTRAL: return "NEUTRAL"
		_: return "HOSTILE"

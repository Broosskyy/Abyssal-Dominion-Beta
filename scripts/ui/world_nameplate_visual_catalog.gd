class_name WorldNameplateVisualCatalog
extends RefCounted

static func slot(ship: ShipMotor, relation: String, own: bool) -> String:
	if own:
		return "world_nameplate_friendly"
	var kind := str(ship.get_meta("encounter_kind",""))
	var rarity := str(ship.get_meta("rarity","common"))
	if kind == "monster":
		return "world_nameplate_monster"
	if bool(ship.get_meta("is_admiral",false)) or rarity == "boss":
		return "world_nameplate_admiral"
	if rarity == "elite":
		return "world_nameplate_elite"
	if relation == EncounterRelation.NEUTRAL:
		return "world_nameplate_neutral"
	return "world_nameplate_hostile"

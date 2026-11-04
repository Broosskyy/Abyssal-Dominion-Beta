class_name HomeSummary
extends RefCounted
## Tolerant read-only projection; never repairs or overwrites a game save.

static func from_save(saved: Dictionary) -> Dictionary:
	var roster: Variant = saved.get("ship_roster", {})
	var selected := BeginnerRules.START_SHIP
	if roster is Dictionary:
		var requested: Variant = roster.get("selected_ship_id", BeginnerRules.START_SHIP)
		var owned: Variant = roster.get("owned_ship_ids", [BeginnerRules.START_SHIP])
		if requested is String and owned is Array and ShipCatalog.has_ship(requested):
			if owned.has(requested):
				selected = requested
	var world: Variant = saved.get("world", {})
	var coordinate:=Vector2i.ZERO
	var stable_id:=""
	if world is Dictionary:
		stable_id=str(world.get("sector_id",""))
		var sector:Variant=world.get("sector",[])
		if stable_id.is_empty() and sector is Array and sector.size()==2 and is_finite(float(sector[0])) and is_finite(float(sector[1])):
			coordinate=Vector2i(int(sector[0]),int(sector[1]));stable_id=WorldSectorRegistry.id_for_coord(coordinate)
	var row:=WorldSectorRegistry.by_id(stable_id)
	var sector_name:String=str(row.get("display_name","Unknown Sea")) if not row.is_empty() else "Unknown Sea"
	var ship := ShipCatalog.ship(ShipCatalog.index_of(selected))
	return {"ship_id": selected, "ship_name": ship.display_name, "sector_name": sector_name}

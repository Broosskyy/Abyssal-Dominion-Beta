class_name M230EncounterWorldReadCatalog
extends RefCounted

## Presentation-only bridge from M229 encounter semantics into the zoomed-out world HUD.
## No spawn, AI, combat, collision or navigation authority lives here.

static func danger_radius(ship:Node3D)->float:
	var read:=str(ship.get_meta("m229_danger_read","standard"))
	return {"standard":0.0,"elite":9.0,"territory":13.0,"boss":16.0}.get(read,0.0)

static func danger_alpha(ship:Node3D)->float:
	var read:=str(ship.get_meta("m229_danger_read","standard"))
	return {"standard":0.0,"elite":0.28,"territory":0.34,"boss":0.42}.get(read,0.0)

static func rank_badge(ship:Node3D)->String:
	var read:=str(ship.get_meta("m229_danger_read","standard"))
	return {"elite":"ELITE","territory":"REVIER","boss":"ADMIRAL"}.get(read,"")

static func formation_glyph(ship:Node3D)->String:
	var formation:=str(ship.get_meta("m229_formation_read",""))
	if "wedge" in formation:return "⌄"
	if "arc" in formation:return "⌒"
	if "line" in formation:return "—"
	if "screen" in formation:return "≋"
	if "column" in formation:return "⋮"
	return "·"

static func world_zone_visible(ship:Node3D, selected:bool)->bool:
	if selected:return true
	return int(ship.get_meta("m229_world_read_priority",1))>=2

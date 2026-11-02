class_name M219WorldReadabilityCatalog
extends RefCounted

const LOOT_PRIORITY := {
	"common": 62, "uncommon": 64, "rare": 68, "epic": 72, "legendary": 78, "boss": 82
}

static func loot_priority(tier: String, loot_type: String = "") -> int:
	if loot_type == "admiral_chest":
		return 82
	return int(LOOT_PRIORITY.get(tier, 62))

static func nameplate_rank(ship: ShipMotor, selected: bool, own: bool) -> int:
	if own: return 100
	if selected: return 96
	if bool(ship.get_meta("is_admiral", false)) or str(ship.get_meta("rarity", "")) == "boss": return 90
	if str(ship.get_meta("rarity", "")) == "elite": return 78
	return 52

static func marker_label_visible(kind: String, distance: float, priority: int) -> bool:
	if kind == "loot": return distance <= 38.0 or priority >= 72
	return kind in ["event_portal", "event_wreck", "event_boss", "objective", "admiral"] and distance <= 40.0

static func compact_nameplate_width(selected: bool, boss: bool) -> Vector2:
	return Vector2(310.0 if selected else (292.0 if boss else 244.0), 46.0 if selected else (40.0 if boss else 34.0))

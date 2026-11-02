class_name M221MinimapNavigationCatalog
extends RefCounted
## Presentation-only minimap hierarchy for the five gameplay master references.
## No route, spawn, collision, combat, quest or reward authority lives here.

const PLAYER_RADIUS := 5.0
const TARGET_RADIUS := 10.5
const TRACKED_RADIUS := 8.0
const ADMIRAL_RADIUS := 5.5
const PORT_RADIUS := 4.5
const LOOT_RADIUS := 3.2

static func ship_heading_2d(ship: Node3D) -> Vector2:
	if ship == null:
		return Vector2.UP
	var forward := -ship.global_transform.basis.z
	var heading := Vector2(forward.x, forward.z)
	return heading.normalized() if heading.length_squared() > 0.0001 else Vector2.UP

static func marker_radius(kind: String, selected := false, tracked := false, admiral := false) -> float:
	if selected:
		return TARGET_RADIUS
	if tracked:
		return TRACKED_RADIUS
	if admiral:
		return ADMIRAL_RADIUS
	match kind:
		"port": return PORT_RADIUS
		"loot": return LOOT_RADIUS
		"player": return PLAYER_RADIUS
		_: return 3.0

static func course_label(distance: float, detouring: bool) -> String:
	return "%s · %.0fm" % ["KURS UM LAND" if detouring else "KURS", maxf(0.0, distance)]

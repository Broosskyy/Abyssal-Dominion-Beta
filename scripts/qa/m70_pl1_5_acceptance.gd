class_name M70Pl15Acceptance
extends RefCounted
## Runtime-safe local acceptance helpers. These report observable state only.
## They do not mutate rewards, combat, progression or backend state.

static func snapshot(player: ShipMotor) -> Dictionary:
	if player == null:
		return {"ready":false}
	var voyage := player.get_node_or_null("Voyage") as VoyageProgress
	var roster := player.get_node_or_null("ShipRoster") as PlayerShipRoster
	var inventory := player.get_node_or_null("Inventory") as PlayerInventory
	var target := (player.get_node_or_null("Weapons") as ShipWeapons).selected_target() if player.get_node_or_null("Weapons") != null else null
	return {
		"ready":true,
		"map_level":voyage.map_level() if voyage != null else -1,
		"beginner_complete":voyage.beginner_complete() if voyage != null else false,
		"owned_starters":{
			"small":roster.owns_ship(BeginnerRules.START_SHIP) if roster != null else false,
			"medium":roster.owns_ship("clipper") if roster != null else false,
			"large":roster.owns_ship("chalupa") if roster != null else false,
		},
		"at_port":inventory.at_port() if inventory != null else false,
		"target_relation":EncounterRelation.status(target) if target != null else "",
		"target_kind":str(target.get_meta("encounter_kind","")) if target != null else "",
	}

static func mobile_layout_report(safe: Rect2) -> Dictionary:
	var layout := NauticalLayout.calculate(safe)
	var min_size := INF
	var outside := 0
	for rect: Rect2 in layout.actions.values():
		if not rect.has_area(): continue
		min_size = minf(min_size, minf(rect.size.x, rect.size.y))
		if not safe.intersects(rect): outside += 1
	return {
		"safe":safe,
		"ui_scale":layout.ui_scale,
		"touch_density":layout.touch_density,
		"minimum_action_extent":0.0 if is_inf(min_size) else min_size,
		"fully_outside_safe_area":outside,
	}

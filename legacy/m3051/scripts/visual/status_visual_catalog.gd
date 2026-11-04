class_name StatusVisualCatalog
extends RefCounted
## M45 visual-only status presentation. No gameplay values are derived here.

const PATH := "res://data/status_visuals.json"
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if not _data.is_empty():
		return _data
	if not FileAccess.file_exists(PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	_data = parsed if parsed is Dictionary else {}
	return _data

static func active(ship: ShipMotor) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if ship == null:
		return result
	var health := ship.get_node_or_null("Health") as ShipHealth
	if health == null:
		return result
	var now := Time.get_ticks_msec() / 1000.0
	var defs: Dictionary = data().get("statuses", {})
	for id in defs:
		var entry: Dictionary = defs[id]
		var remaining := 0.0
		match str(entry.get("source", "")):
			"ammo_effect_until":
				remaining = maxf(0.0, float(health.ammo_effect_until.get(id, 0.0)) - now)
			"repair_block_until":
				remaining = maxf(0.0, health.repair_block_until - now)
			"temporary_barrier_until":
				remaining = maxf(0.0, health.temporary_barrier_until - now) if health.barrier_remaining() > 0.0 else 0.0
			"ship_meta_veil_until":
				remaining = maxf(0.0, float(ship.get_meta("veil_until", 0.0)) - now) if ship.get_meta("veil_active", false) else 0.0
			"inventory_toggle":
				if ship.is_in_group("player"):
					var inventory := ship.get_node_or_null("Inventory") as PlayerInventory
					if inventory != null:
						var enabled := inventory.powder_enabled if id == "powder" else inventory.plates_enabled
						remaining = 99999.0 if enabled else 0.0
		if remaining > 0.0:
			var state := entry.duplicate(true)
			state["id"] = id
			state["remaining"] = remaining
			result.append(state)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("priority", 0)) > int(b.get("priority", 0)))
	return result

class_name M240SustainSupportRuntime
extends Node

signal state_changed

const CONTRACT_PATH := "res://data/m240_sustain_support_contract.json"
var repair_active := false
var repair_master_tier := 1
var shield_master_tier := 1
var _repair_tick := 0.0
var _shield_tick := 0.0
var _last_damage_at := -999.0

@onready var ship: ShipMotor = get_parent() as ShipMotor
@onready var health: ShipHealth = ship.get_node("Health") as ShipHealth

func _ready() -> void:
	if health != null:
		health.damage_applied.connect(_on_damage_applied)

func _process(delta: float) -> void:
	if health == null or health.is_sunk: return
	_repair_tick -= delta
	_shield_tick -= delta
	if repair_active and _repair_tick <= 0.0:
		_repair_tick = _repair_row().get("interval", 1.0)
		var amount := float(_repair_row().get("base_rate", 0.0)) * _repair_multiplier()
		health.repair(amount, ship, "repair")
	if _shield_tick <= 0.0:
		_shield_tick = _shield_row().get("interval", 1.0)
		var delay := float(_shield_row().get("delay", 5.0))
		if Time.get_ticks_msec()/1000.0 - _last_damage_at >= delay:
			health.restore_shield(float(_shield_row().get("base_rate", 0.0)) * _shield_multiplier(), ship)

func toggle_repair() -> bool:
	if health == null or health.is_sunk or health.repair_blocked(): return false
	if float(_repair_row().get("base_rate", 0.0)) <= 0.0: return false
	if not repair_active and health.current_health >= health.max_health: return false
	repair_active = not repair_active
	_repair_tick = 0.0
	state_changed.emit()
	return repair_active

func stop_repair() -> void:
	if repair_active:
		repair_active = false
		state_changed.emit()

func repair_status() -> String:
	if health == null or health.is_sunk: return "GESPERRT"
	if health.repair_blocked(): return "REPARATUR BLOCKIERT"
	if float(_repair_row().get("base_rate", 0.0)) <= 0.0: return "KEIN REPARATURMEISTER"
	if health.current_health >= health.max_health: return "HÜLLE VOLL"
	return ("REPARATUR AKTIV · %s" % _repair_row().get("label", "")) if repair_active else "REPARATUR BEREIT"

func _on_damage_applied(_target: Node3D, _attacker: Node3D, _actual: float, _slowed: bool, _critical: bool) -> void:
	_last_damage_at = Time.get_ticks_msec()/1000.0
	# Interruption policy is deliberately data/balance-ready; prototype keeps manual hull repair active.

func _repair_multiplier() -> float:
	var inv := ship.get_node_or_null("Inventory") as PlayerInventory
	return inv.module_modifier("repair_rate_mult", 1.0) if inv != null else 1.0

func _shield_multiplier() -> float:
	var inv := ship.get_node_or_null("Inventory") as PlayerInventory
	return inv.module_modifier("shield_recovery_mult", 1.0) if inv != null else 1.0

func _repair_row() -> Dictionary:
	return _tier_row("repair_masters", _effective_officer_tier("repair_master", repair_master_tier))

func _shield_row() -> Dictionary:
	return _tier_row("shield_masters", _effective_officer_tier("shield_master", shield_master_tier))

func _effective_officer_tier(family: String, legacy_fallback: int) -> int:
	if ship == null: return clampi(legacy_fallback, 1, 3)
	var crew := ship.get_node_or_null("CrewOfficers") as M241CrewOfficerRuntime
	if crew == null: return clampi(legacy_fallback, 1, 3)
	# No assigned contract means that sustain family is not active.
	return crew.effective_tier(family)

func _tier_row(key: String, tier: int) -> Dictionary:
	if tier <= 0: return {"tier": 0, "label": "Kein Officer", "base_rate": 0.0, "interval": 1.0, "delay": 9999.0}
	var data := _contract()
	for row in data.get(key, []):
		if int(row.get("tier", 0)) == tier: return row
	return {}

func _contract() -> Dictionary:
	if not FileAccess.file_exists(CONTRACT_PATH): return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
	return parsed if parsed is Dictionary else {}

func export_state() -> Dictionary:
	return {"repair_active": repair_active, "repair_master_tier": _effective_officer_tier("repair_master", repair_master_tier), "shield_master_tier": _effective_officer_tier("shield_master", shield_master_tier)}

func import_state(data: Dictionary) -> void:
	repair_active = bool(data.get("repair_active", false))
	repair_master_tier = clampi(int(data.get("repair_master_tier", 1)), 1, 3)
	shield_master_tier = clampi(int(data.get("shield_master_tier", 1)), 1, 3)

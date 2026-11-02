class_name SupportContributionTelemetry
extends Node
## M49 local prototype telemetry only. It grants no rewards and claims no server authority.

signal changed

var hull_healed := 0.0
var shield_restored := 0.0
var successful_actions := 0
var unique_targets: Dictionary = {}

func record_support(kind: String, actual_amount: float, target: ShipMotor) -> void:
	if actual_amount <= 0.0: return
	if kind == "shield":
		shield_restored += actual_amount
	else:
		hull_healed += actual_amount
	successful_actions += 1
	if target != null:
		unique_targets[target.get_instance_id()] = true
	changed.emit()

func total_effective_support() -> float:
	return hull_healed + shield_restored

func overheal_contribution() -> float:
	return 0.0

func summary() -> String:
	return "Hull %.0f · Shield %.0f · Aktionen %d · Ziele %d · Overheal 0" % [hull_healed, shield_restored, successful_actions, unique_targets.size()]

func export_state() -> Dictionary:
	return {"hull_healed": hull_healed, "shield_restored": shield_restored, "successful_actions": successful_actions}

func import_state(data: Dictionary) -> void:
	hull_healed = maxf(0.0, float(data.get("hull_healed", 0.0)))
	shield_restored = maxf(0.0, float(data.get("shield_restored", 0.0)))
	successful_actions = maxi(0, int(data.get("successful_actions", 0)))
	changed.emit()

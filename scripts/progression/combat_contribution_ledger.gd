class_name CombatContributionLedger
extends RefCounted
## M57 local presentation/telemetry ledger. It never grants a ship or currency.

const PATH := "res://data/m57_combat_contribution_contract.json"
var counters: Dictionary = {}
var recent: Array[Dictionary] = []

func _init() -> void:
	for row in contract().get("categories", []):
		counters[str(row.get("id",""))] = 0

static func contract() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}

func record(category_id: String, amount: int = 1, context: Dictionary = {}) -> bool:
	if not counters.has(category_id) or amount <= 0:
		return false
	counters[category_id] = int(counters[category_id]) + amount
	recent.push_front({
		"category_id": category_id,
		"amount": amount,
		"context": context.duplicate(true),
		"local_sequence": total_records() + 1
	})
	if recent.size() > 24:
		recent.resize(24)
	return true

func total_records() -> int:
	var total := 0
	for value in counters.values():
		total += int(value)
	return total

func export_state() -> Dictionary:
	return {"counters":counters.duplicate(true),"recent":recent.duplicate(true)}

func import_state(data: Dictionary) -> void:
	var saved: Variant = data.get("counters",{})
	if saved is Dictionary:
		for id in counters:
			counters[id] = maxi(0,int(saved.get(id,0)))
	recent.clear()
	var rows: Variant = data.get("recent",[])
	if rows is Array:
		for row in rows:
			if row is Dictionary:
				recent.append((row as Dictionary).duplicate(true))
				if recent.size() >= 24: break

func summary_rows() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in contract().get("categories",[]):
		var row := (definition as Dictionary).duplicate(true)
		row["count"] = int(counters.get(str(row.get("id","")),0))
		result.append(row)
	return result

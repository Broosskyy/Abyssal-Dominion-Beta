class_name M246AchievementCollectionRuntime
extends Node
## M246 V3.8 achievements + collections read-only server replica.
## The client may present cached progress, but never completes achievements or grants rewards online.
signal changed
const PATH := "res://data/m246_achievements_collections_contract.json"
var revision := -1
var authoritative_snapshot: Dictionary = {}

func contract() -> Dictionary:
	if not FileAccess.file_exists(PATH): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}

func ingest_authoritative_snapshot(snapshot: Dictionary) -> bool:
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < revision: return false
	revision = incoming_revision
	authoritative_snapshot = snapshot.duplicate(true)
	changed.emit()
	return true

func clear_authoritative_snapshot() -> void:
	revision = -1
	authoritative_snapshot = {}
	changed.emit()

func snapshot() -> Dictionary:
	if authoritative_snapshot.is_empty():
		return {
			"source":"LOCAL_PREVIEW", "revision":-1,
			"summary":{}, "achievements":[], "collections":[],
			"recent_completions":[], "claim_receipts":[], "profile_showcase":[]
		}
	var out := authoritative_snapshot.duplicate(true)
	out["source"] = "SERVER"
	return out

func achievement_rows() -> Array:
	var rows = snapshot().get("achievements", [])
	return rows as Array if rows is Array else []

func collection_rows() -> Array:
	var rows = snapshot().get("collections", [])
	return rows as Array if rows is Array else []

func recent_completion_rows() -> Array:
	var rows = snapshot().get("recent_completions", [])
	return rows as Array if rows is Array else []

func claim_receipt_rows() -> Array:
	var rows = snapshot().get("claim_receipts", [])
	return rows as Array if rows is Array else []

func profile_showcase_rows() -> Array:
	var rows = snapshot().get("profile_showcase", [])
	return rows as Array if rows is Array else []

func local_category_preview() -> Dictionary:
	var scope: Dictionary = contract().get("master_scope", {})
	return {
		"achievement_categories": (scope.get("achievement_categories", []) as Array).duplicate(),
		"collection_families": (scope.get("collection_families", []) as Array).duplicate(),
		"reward_families": (scope.get("reward_families", []) as Array).duplicate()
	}

func export_state() -> Dictionary:
	# Cached replica only. Save data never becomes reward/completion authority.
	return {"revision":revision,"authoritative_snapshot":authoritative_snapshot.duplicate(true)}

func import_state(state: Dictionary) -> void:
	var cached = state.get("authoritative_snapshot", {})
	if cached is Dictionary and not (cached as Dictionary).is_empty():
		revision = int(state.get("revision", int((cached as Dictionary).get("revision", -1))))
		authoritative_snapshot = (cached as Dictionary).duplicate(true)
		changed.emit()

func can_client_complete_achievement() -> bool: return false
func can_client_advance_collection() -> bool: return false
func can_client_claim_reward() -> bool: return false
func can_client_generate_receipt() -> bool: return false
func can_client_set_profile_showcase() -> bool: return false

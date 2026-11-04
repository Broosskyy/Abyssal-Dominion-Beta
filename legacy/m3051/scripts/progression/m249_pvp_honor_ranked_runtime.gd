class_name M249PvpHonorRankedRuntime
extends Node
## M249 V3.8 PvP / Honor / Ranked read-only server replica.
## Live flagging, Honor, MMR, Rank Points, matchmaking, combat timers, anti-farm verdicts and settlement remain server-authoritative.
signal changed
const PATH := "res://data/m249_pvp_honor_ranked_contract.json"
var revision := -1
var authoritative_snapshot: Dictionary = {}
var local_preferences: Dictionary = {"ranked_view":"current_season"}

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
		return {"source":"LOCAL_PREVIEW","revision":-1,"zone":{},"protection":{},"honor":{},"ranked":{},"queue":{},"combat_timer":{},"modifiers":{},"settlement":{}}
	var out := authoritative_snapshot.duplicate(true)
	out["source"] = "SERVER"
	return out

func zone_state() -> Dictionary:
	var value = snapshot().get("zone", {})
	return value as Dictionary if value is Dictionary else {}

func protection_state() -> Dictionary:
	var value = snapshot().get("protection", {})
	return value as Dictionary if value is Dictionary else {}

func honor_state() -> Dictionary:
	var value = snapshot().get("honor", {})
	return value as Dictionary if value is Dictionary else {}

func ranked_state() -> Dictionary:
	var value = snapshot().get("ranked", {})
	return value as Dictionary if value is Dictionary else {}

func queue_state() -> Dictionary:
	var value = snapshot().get("queue", {})
	return value as Dictionary if value is Dictionary else {}

func combat_timer_state() -> Dictionary:
	var value = snapshot().get("combat_timer", {})
	return value as Dictionary if value is Dictionary else {}

func hud_state() -> Dictionary:
	if str(snapshot().get("source", "")) != "SERVER": return {"source":"LOCAL_PREVIEW"}
	return {"source":"SERVER","zone":zone_state(),"protection":protection_state(),"combat_timer":combat_timer_state()}

func set_local_preferences(preferences: Dictionary) -> void:
	# Presentation only; never mutates competitive state.
	local_preferences = preferences.duplicate(true)
	changed.emit()

func export_state() -> Dictionary:
	return {"revision":revision,"authoritative_snapshot":authoritative_snapshot.duplicate(true),"local_preferences":local_preferences.duplicate(true)}

func import_state(state: Dictionary) -> void:
	var cached = state.get("authoritative_snapshot", {})
	if cached is Dictionary and not (cached as Dictionary).is_empty():
		revision = int(state.get("revision", int((cached as Dictionary).get("revision", -1))))
		authoritative_snapshot = (cached as Dictionary).duplicate(true)
	var prefs = state.get("local_preferences", {})
	if prefs is Dictionary and not (prefs as Dictionary).is_empty(): local_preferences = (prefs as Dictionary).duplicate(true)
	changed.emit()

func can_client_mutate_pvp_flag() -> bool: return false
func can_client_mutate_honor() -> bool: return false
func can_client_mutate_mmr_or_rank_points() -> bool: return false
func can_client_set_match_result() -> bool: return false
func can_client_set_combat_timer() -> bool: return false
func can_client_override_anti_farm() -> bool: return false
func can_client_settle_pvp_reward() -> bool: return false

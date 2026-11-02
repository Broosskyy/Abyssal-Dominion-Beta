class_name M251MetaProgressionRuntime
extends Node

signal changed

var revision := -1
var authoritative_snapshot: Dictionary = {}

func _ready() -> void:
	add_to_group("m251_meta_progression")
	set_meta("authority", "SERVER_REPLICA_ONLY")

func ingest_authoritative_snapshot(snapshot: Dictionary) -> bool:
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < revision:
		return false
	revision = incoming_revision
	authoritative_snapshot = snapshot.duplicate(true)
	changed.emit()
	return true

func snapshot() -> Dictionary:
	if authoritative_snapshot.is_empty():
		return {
			"revision": revision,
			"source": "LOCAL_PREVIEW",
			"companions": [],
			"active_companion": {},
			"artifacts": [],
			"artifact_loadout": [],
			"afk": {},
			"claim_receipts": []
		}
	var result := authoritative_snapshot.duplicate(true)
	result["source"] = "SERVER"
	return result

func companion_rows() -> Array:
	return (snapshot().get("companions", []) as Array).duplicate(true)

func active_companion() -> Dictionary:
	var row = snapshot().get("active_companion", {})
	return (row as Dictionary).duplicate(true) if row is Dictionary else {}

func artifact_rows() -> Array:
	return (snapshot().get("artifacts", []) as Array).duplicate(true)

func artifact_loadout_rows() -> Array:
	return (snapshot().get("artifact_loadout", []) as Array).duplicate(true)

func afk_state() -> Dictionary:
	var row = snapshot().get("afk", {})
	return (row as Dictionary).duplicate(true) if row is Dictionary else {}

func claim_receipt_rows() -> Array:
	return (snapshot().get("claim_receipts", []) as Array).duplicate(true)

func local_definition_preview() -> Dictionary:
	return {
		"companion_definitions": CompanionCatalog.all().size(),
		"artifact_definitions": ArtifactCatalog.all().size(),
		"afk_profiles": AfkRewardCatalog.profiles().size(),
		"companion_roles": ["combat", "defense", "support", "hunter", "loot_salvage", "navigation", "exploration", "utility"],
		"artifact_families": ["war", "defense", "navigation", "hunter", "fortune", "support", "exploration", "guild", "event", "abyssal"],
		"authority": "DEFINITION_PREVIEW_ONLY"
	}

func export_state() -> Dictionary:
	return {"revision": revision, "cached_server_snapshot": authoritative_snapshot.duplicate(true)}

func import_state(data: Dictionary) -> void:
	var cached = data.get("cached_server_snapshot", {})
	if cached is Dictionary and not (cached as Dictionary).is_empty():
		authoritative_snapshot = (cached as Dictionary).duplicate(true)
		revision = maxi(int(data.get("revision", authoritative_snapshot.get("revision", -1))), int(authoritative_snapshot.get("revision", -1)))
		changed.emit()

func can_client_grant_companion() -> bool: return false
func can_client_upgrade_companion() -> bool: return false
func can_client_mutate_companion_traits() -> bool: return false
func can_client_set_companion_loadout() -> bool: return false
func can_client_grant_artifact() -> bool: return false
func can_client_upgrade_artifact() -> bool: return false
func can_client_mutate_artifact_resonance() -> bool: return false
func can_client_set_artifact_loadout() -> bool: return false
func can_client_calculate_authoritative_offline_time() -> bool: return false
func can_client_resolve_afk_reward() -> bool: return false
func can_client_claim_afk_reward() -> bool: return false
func can_client_generate_afk_receipt() -> bool: return false

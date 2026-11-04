class_name M245SpecialPveOracleRuntime
extends Node
## M245 V3.8 Special-PvE / Compass-Cauldron-successor replica.
## Live resource balances, reward rolls, pity and claims remain server authoritative.
signal changed
const PATH := "res://data/m245_special_pve_oracle_contract.json"
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
			"resource_label":"Tide Essence", "resource_amount":-1,
			"pity_current":-1, "pity_threshold":-1,
			"last_reward":{}, "claim_state":"server_required",
			"reward_pool_state":"definition_ready_server_resolution_required"
		}
	var out := authoritative_snapshot.duplicate(true)
	out["source"] = "SERVER"
	return out

func export_state() -> Dictionary:
	# Cached replica only; never turns a local save into reward authority.
	return {"revision":revision,"authoritative_snapshot":authoritative_snapshot.duplicate(true)}

func import_state(state: Dictionary) -> void:
	var cached = state.get("authoritative_snapshot", {})
	if cached is Dictionary and not (cached as Dictionary).is_empty():
		revision = int(state.get("revision", int((cached as Dictionary).get("revision", -1))))
		authoritative_snapshot = (cached as Dictionary).duplicate(true)
		changed.emit()

func can_client_spend_resource() -> bool: return false
func can_client_resolve_reward() -> bool: return false
func can_client_advance_pity() -> bool: return false
func can_client_claim_reward() -> bool: return false
func can_client_convert_duplicate() -> bool: return false

func local_pool_preview() -> Array:
	# Non-reward preview: categories only, no roll, quantity or rarity odds invented.
	return contract().get("reward_pool_categories", []) as Array

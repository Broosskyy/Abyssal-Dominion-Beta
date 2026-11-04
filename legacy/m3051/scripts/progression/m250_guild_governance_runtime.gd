class_name M250GuildGovernanceRuntime
extends Node

signal changed
const PATH := "res://data/m250_guild_governance_contract.json"
var revision := -1
var authoritative_snapshot: Dictionary = {}

func ingest_authoritative_snapshot(snapshot: Dictionary) -> bool:
	var incoming := int(snapshot.get("revision", -1))
	if incoming < 0 or incoming <= revision: return false
	revision = incoming
	authoritative_snapshot = snapshot.duplicate(true)
	changed.emit()
	return true

func snapshot() -> Dictionary:
	if authoritative_snapshot.is_empty():
		return {"source":"LOCAL_PREVIEW", "revision":revision, "membership":{}, "members":[], "treasury":{}, "vault":{}, "diplomacy":[], "war":{}, "rating":{}, "island":{}}
	var out := authoritative_snapshot.duplicate(true)
	out["source"] = "SERVER"
	out["revision"] = revision
	return out

func export_state() -> Dictionary:
	return {"revision":revision, "cached_server_snapshot":authoritative_snapshot.duplicate(true)}

func import_state(state: Dictionary) -> void:
	var cached: Variant = state.get("cached_server_snapshot", {})
	if cached is Dictionary:
		authoritative_snapshot = cached.duplicate(true)
		revision = int(state.get("revision", authoritative_snapshot.get("revision", -1)))
		changed.emit()

func can_client_mutate_membership() -> bool: return false
func can_client_mutate_roles() -> bool: return false
func can_client_transfer_treasury() -> bool: return false
func can_client_transfer_vault() -> bool: return false
func can_client_declare_war() -> bool: return false
func can_client_mutate_diplomacy() -> bool: return false
func can_client_mutate_rating() -> bool: return false
func can_client_mutate_island_ownership() -> bool: return false

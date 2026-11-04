class_name M243WantedBountyRuntime
extends Node
## V3.8 M243 read-only Wanted/Bounty replica.
## Player Wanted, PvP qualification, anti-farm and reward settlement remain server authoritative.
var revision := -1
var authoritative_snapshot: Dictionary = {}

func ingest_authoritative_snapshot(snapshot: Dictionary) -> bool:
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < revision:
		return false
	revision = incoming_revision
	authoritative_snapshot = snapshot.duplicate(true)
	return true

func clear_authoritative_snapshot() -> void:
	revision = -1
	authoritative_snapshot = {}

func snapshot() -> Dictionary:
	if authoritative_snapshot.is_empty():
		return {
			"source":"LOCAL_PREVIEW",
			"revision":-1,
			"wanted_state":"unavailable",
			"wanted_label":"KEINE SERVERDATEN",
			"active_bounties":[],
			"hunter_eligibility":"unknown",
			"anti_farm_state":"server_required",
			"settlement_state":"server_required"
		}
	var out := authoritative_snapshot.duplicate(true)
	out["source"] = "SERVER"
	return out

func active_bounties() -> Array:
	var rows = snapshot().get("active_bounties", [])
	return rows if rows is Array else []

func can_client_mutate_wanted() -> bool: return false
func can_client_settle_bounty() -> bool: return false
func can_client_grant_reward() -> bool: return false
func can_client_mutate_honor() -> bool: return false
func can_client_override_anti_farm() -> bool: return false

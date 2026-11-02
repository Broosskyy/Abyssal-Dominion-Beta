class_name M276AuthoritativeLootRollIntegrityRuntime
extends Node
## M276 fail-closed server replica for loot-roll ledger, RNG integrity, duplicate protection and guaranteed/pity state.
signal changed
signal roll_feedback(kind: String, payload: Dictionary)

var session_id := ""
var environment := ""
var instance_id := ""
var encounter_id := ""
var loot_revision := -1
var roll_ledger_revision := -1
var pity_revision := -1
var settlement_sequence := -1
var server_tick := -1
var roll_ledger: Dictionary = {}
var duplicate_guard_state: Dictionary = {}
var guaranteed_state: Dictionary = {}
var pity_state: Dictionary = {}
var rng_integrity_state: Dictionary = {}
var last_server_event: Dictionary = {}

const ROLL_STATES := ["UNKNOWN", "AUTHORIZED", "RESOLVING", "RESOLVED", "DISTRIBUTED", "SETTLEMENT_PENDING", "SETTLED", "REVOKED"]
const SERVER_EVENTS := ["ROLL_AUTHORIZED", "ROLL_RESOLVED", "DUPLICATE_REJECTED", "GUARANTEED_APPLIED", "PITY_UPDATED", "DISTRIBUTED", "SETTLEMENT_AUTHORIZED", "SETTLED", "REVOKED"]
const REQUIRED_ROLL_IDENTITY := ["roll_id", "request_id", "idempotency_key", "loot_table_id", "loot_table_version", "resolver_version"]

func _ready() -> void:
	add_to_group("authoritative_loot_roll_integrity_readiness")

func bind_loot_distribution(loot: M275AuthoritativeLootDistributionRuntime) -> bool:
	if loot == null: return false
	var s := loot.snapshot()
	if str(s.get("source", "")) != "SERVER": return false
	session_id = str(s.get("session_id", "")); environment = str(s.get("environment", "")).to_upper(); instance_id = str(s.get("instance_id", "")); encounter_id = str(s.get("encounter_id", "")); loot_revision = int(s.get("loot_revision", -1)); settlement_sequence = int(s.get("settlement_sequence", -1)); server_tick = int(s.get("server_tick", -1))
	if session_id.is_empty() or environment.is_empty() or instance_id.is_empty() or encounter_id.is_empty() or loot_revision < 0: return false
	changed.emit(); return true

func ingest_server_roll_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if not _same_scope(snapshot): return false
	var lr := int(snapshot.get("loot_revision", -1)); var rr := int(snapshot.get("roll_ledger_revision", -1)); var pr := int(snapshot.get("pity_revision", -1)); var seq := int(snapshot.get("settlement_sequence", -1)); var tick := int(snapshot.get("server_tick", -1))
	if lr < loot_revision or rr <= roll_ledger_revision or pr < pity_revision or seq < settlement_sequence or tick < server_tick: return false
	for key in ["roll_ledger", "duplicate_guard_state", "guaranteed_state", "pity_state", "rng_integrity_state"]:
		if not snapshot.get(key, {}) is Dictionary: return false
	var ledger := snapshot.get("roll_ledger", {}) as Dictionary
	if not _valid_roll_identity(ledger): return false
	var state := str(ledger.get("state", "UNKNOWN")).to_upper()
	if state not in ROLL_STATES: return false
	if not _valid_integrity_state(snapshot.get("rng_integrity_state", {}) as Dictionary): return false
	loot_revision = lr; roll_ledger_revision = rr; pity_revision = pr; settlement_sequence = seq; server_tick = tick
	roll_ledger = ledger.duplicate(true)
	duplicate_guard_state = (snapshot.get("duplicate_guard_state", {}) as Dictionary).duplicate(true)
	guaranteed_state = (snapshot.get("guaranteed_state", {}) as Dictionary).duplicate(true)
	pity_state = (snapshot.get("pity_state", {}) as Dictionary).duplicate(true)
	rng_integrity_state = (snapshot.get("rng_integrity_state", {}) as Dictionary).duplicate(true)
	last_server_event = {"kind":"ROLL_LEDGER_SNAPSHOT", "server_verified":true, "roll_ledger_revision":rr, "pity_revision":pr, "server_tick":tick}
	roll_feedback.emit("ROLL_LEDGER_CONFIRMED", last_server_event.duplicate(true)); changed.emit(); return true

func ingest_server_roll_event(event: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if not _same_scope(event): return false
	var lr := int(event.get("loot_revision", -1)); var rr := int(event.get("roll_ledger_revision", -1)); var pr := int(event.get("pity_revision", -1)); var seq := int(event.get("settlement_sequence", -1)); var tick := int(event.get("server_tick", -1))
	if lr < loot_revision or rr <= roll_ledger_revision or pr < pity_revision or seq < settlement_sequence or tick < server_tick: return false
	var kind := str(event.get("event", "")).to_upper(); if kind not in SERVER_EVENTS: return false
	if event.has("roll_ledger"):
		if not event.get("roll_ledger") is Dictionary: return false
		var ledger := event.get("roll_ledger") as Dictionary
		if not _valid_roll_identity(ledger): return false
		if str(ledger.get("state", "UNKNOWN")).to_upper() not in ROLL_STATES: return false
	if event.has("rng_integrity_state"):
		if not event.get("rng_integrity_state") is Dictionary or not _valid_integrity_state(event.get("rng_integrity_state") as Dictionary): return false
	loot_revision = lr; roll_ledger_revision = rr; pity_revision = pr; settlement_sequence = seq; server_tick = tick
	if event.has("roll_ledger"): roll_ledger = (event.get("roll_ledger") as Dictionary).duplicate(true)
	if event.has("duplicate_guard_state") and event.get("duplicate_guard_state") is Dictionary: duplicate_guard_state = (event.get("duplicate_guard_state") as Dictionary).duplicate(true)
	if event.has("guaranteed_state") and event.get("guaranteed_state") is Dictionary: guaranteed_state = (event.get("guaranteed_state") as Dictionary).duplicate(true)
	if event.has("pity_state") and event.get("pity_state") is Dictionary: pity_state = (event.get("pity_state") as Dictionary).duplicate(true)
	if event.has("rng_integrity_state") and event.get("rng_integrity_state") is Dictionary: rng_integrity_state = (event.get("rng_integrity_state") as Dictionary).duplicate(true)
	last_server_event = event.duplicate(true); last_server_event["server_verified"] = true
	roll_feedback.emit(kind, last_server_event.duplicate(true)); changed.emit(); return true

func _same_scope(payload: Dictionary) -> bool:
	return str(payload.get("session_id", "")) == session_id and str(payload.get("environment", "")).to_upper() == environment and str(payload.get("instance_id", "")) == instance_id and str(payload.get("encounter_id", "")) == encounter_id

func _valid_roll_identity(ledger: Dictionary) -> bool:
	for key in REQUIRED_ROLL_IDENTITY:
		if str(ledger.get(key, "")).is_empty(): return false
	return true

func _valid_integrity_state(state: Dictionary) -> bool:
	if state.is_empty(): return true
	if str(state.get("authority", "SERVER")).to_upper() != "SERVER": return false
	# Commitments/digests are opaque server evidence. The client never receives or chooses secret entropy/seed material.
	if state.has("client_seed") or state.has("raw_seed") or state.has("secret_entropy"): return false
	return true

func local_roll_presentation_hint() -> Dictionary:
	return {"encounter_id":encounter_id, "roll_state_hint":str(roll_ledger.get("state", "UNKNOWN")), "guaranteed_hint":guaranteed_state.duplicate(true), "pity_hint":pity_state.duplicate(true), "authority":"LOCAL_PRESENTATION_ONLY", "can_roll":false, "can_reroll":false, "can_seed_rng":false, "can_advance_pity":false, "can_settle":false}

func invalidate_from_world_resync() -> void:
	roll_ledger.clear(); duplicate_guard_state.clear(); guaranteed_state.clear(); pity_state.clear(); rng_integrity_state.clear(); last_server_event = {"kind":"WORLD_RESYNC", "server_verified":false}; changed.emit()

func snapshot() -> Dictionary:
	return {"source":"SERVER" if roll_ledger_revision >= 0 else "LOCAL_PREVIEW", "session_id":session_id, "environment":environment, "instance_id":instance_id, "encounter_id":encounter_id, "loot_revision":loot_revision, "roll_ledger_revision":roll_ledger_revision, "pity_revision":pity_revision, "settlement_sequence":settlement_sequence, "server_tick":server_tick, "roll_ledger":roll_ledger.duplicate(true), "duplicate_guard_state":duplicate_guard_state.duplicate(true), "guaranteed_state":guaranteed_state.duplicate(true), "pity_state":pity_state.duplicate(true), "rng_integrity_state":rng_integrity_state.duplicate(true), "last_server_event":last_server_event.duplicate(true)}

func can_client_generate_roll_id() -> bool: return false
func can_client_choose_rng_seed() -> bool: return false
func can_client_roll_drop() -> bool: return false
func can_client_reroll_drop() -> bool: return false
func can_client_bypass_duplicate_guard() -> bool: return false
func can_client_advance_pity() -> bool: return false
func can_client_trigger_guaranteed_drop() -> bool: return false
func can_client_override_result_digest() -> bool: return false
func can_client_authorize_settlement() -> bool: return false
func can_client_transfer_test_roll_to_global() -> bool: return false

class_name M269AuthoritativeCombatRuntime
extends Node
## M269 authoritative combat resolution / fire command boundary.
## Inspired by the readable target-and-volley cadence expected from naval MMOs
## such as Seafight and Battle of Sea, but implemented clean-room for Abyssal Dominion.
## Client targeting, aim previews and fire feedback are responsiveness/UI only.
## The server owns target legality, range/line-of-fire, reload/cooldown, ammo use,
## hit/miss/block/crit, damage/heal, death, combat revisions and settlement linkage.
signal changed
signal combat_feedback(kind: String, payload: Dictionary)

var session_id := ""
var environment := ""
var instance_id := ""
var attacker_entity_id := ""
var attacker_spawn_generation := -1
var combat_revision := -1
var server_tick := -1
var last_acked_fire_sequence := -1
var selected_target_entity_id := ""
var selected_target_spawn_generation := -1
var pending_fire_intents: Array = []
var last_server_verdict: Dictionary = {}

func _ready() -> void:
	add_to_group("authoritative_combat_readiness")

func bind_world_replica(world: M267AuthoritativeWorldTransportRuntime, attacker_id: String) -> bool:
	if world == null: return false
	var snap := world.snapshot()
	if str(snap.get("source", "")) != "SERVER": return false
	var entity := world.entity_state(attacker_id)
	if entity.is_empty(): return false
	session_id = str(snap.get("session_id", ""))
	environment = str(snap.get("environment", "")).to_upper()
	instance_id = str(snap.get("instance_id", ""))
	attacker_entity_id = attacker_id
	attacker_spawn_generation = int(entity.get("spawn_generation", -1))
	server_tick = int(snap.get("server_tick", -1))
	combat_revision = int(entity.get("combat_revision", combat_revision))
	if session_id.is_empty() or instance_id.is_empty() or attacker_entity_id.is_empty() or attacker_spawn_generation < 0: return false
	changed.emit()
	return true

func select_target_preview(world: M267AuthoritativeWorldTransportRuntime, target_id: String) -> bool:
	# Selection improves clarity and target cycling, but is not server target legality.
	if world == null or target_id.is_empty() or target_id == attacker_entity_id: return false
	var target := world.entity_state(target_id)
	if target.is_empty(): return false
	selected_target_entity_id = target_id
	selected_target_spawn_generation = int(target.get("spawn_generation", -1))
	changed.emit()
	return selected_target_spawn_generation >= 0

func clear_target_preview() -> void:
	selected_target_entity_id = ""
	selected_target_spawn_generation = -1
	changed.emit()

func prepare_fire_intent(weapon_instance_id: String, ammo_instance_id: String, weapon_family: String, fire_sequence: int, request_id: String) -> Dictionary:
	if session_id.is_empty() or attacker_entity_id.is_empty() or selected_target_entity_id.is_empty(): return {}
	if weapon_instance_id.is_empty() or request_id.is_empty() or fire_sequence < 0: return {}
	var family := weapon_family.to_upper()
	if family not in ["CANNON", "HARPOON", "SUPPORT", "SPECIAL"]: return {}
	return {
		"operation":"FIRE_WEAPON",
		"session_id":session_id,"environment":environment,"instance_id":instance_id,
		"attacker_entity_id":attacker_entity_id,"attacker_spawn_generation":attacker_spawn_generation,
		"target_entity_id":selected_target_entity_id,"target_spawn_generation":selected_target_spawn_generation,
		"weapon_instance_id":weapon_instance_id,"ammo_instance_id":ammo_instance_id,"weapon_family":family,
		"fire_sequence":fire_sequence,"request_id":request_id,"known_combat_revision":combat_revision,
		"known_server_tick":server_tick,"authority":"CLIENT_REQUEST_ONLY","server_verified":false
	}

func stage_local_fire_feedback(intent: Dictionary) -> bool:
	# Muzzle flash/pressed-state/target pulse may react immediately; never show a confirmed hit/reward here.
	if str(intent.get("authority", "")) != "CLIENT_REQUEST_ONLY" or str(intent.get("operation", "")) != "FIRE_WEAPON": return false
	if str(intent.get("session_id", "")) != session_id or str(intent.get("instance_id", "")) != instance_id: return false
	if str(intent.get("environment", "")).to_upper() != environment: return false
	if str(intent.get("attacker_entity_id", "")) != attacker_entity_id or int(intent.get("attacker_spawn_generation", -1)) != attacker_spawn_generation: return false
	var seq := int(intent.get("fire_sequence", -1))
	if seq <= last_acked_fire_sequence: return false
	for raw in pending_fire_intents:
		if int((raw as Dictionary).get("fire_sequence", -2)) == seq: return false
	pending_fire_intents.append(intent.duplicate(true))
	combat_feedback.emit("FIRE_REQUESTED", {"fire_sequence":seq,"target_entity_id":str(intent.get("target_entity_id","")),"confirmed_hit":false})
	changed.emit()
	return true

func ingest_server_combat_verdict(verdict: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if str(verdict.get("session_id", "")) != session_id or str(verdict.get("environment", "")).to_upper() != environment: return false
	if str(verdict.get("instance_id", "")) != instance_id: return false
	if str(verdict.get("attacker_entity_id", "")) != attacker_entity_id or int(verdict.get("attacker_spawn_generation", -1)) != attacker_spawn_generation: return false
	var incoming_revision := int(verdict.get("combat_revision", -1))
	var incoming_tick := int(verdict.get("server_tick", -1))
	var ack_sequence := int(verdict.get("ack_fire_sequence", -1))
	if incoming_revision <= combat_revision or incoming_tick < server_tick or ack_sequence < last_acked_fire_sequence: return false
	var outcome := str(verdict.get("outcome", "")).to_upper()
	if outcome not in ["HIT", "MISS", "BLOCKED", "CRITICAL", "HEAL", "REJECTED"]: return false
	var reason := str(verdict.get("reason", ""))
	var target_state = verdict.get("authoritative_target_state", {})
	if not (target_state is Dictionary): return false
	combat_revision = incoming_revision
	server_tick = incoming_tick
	last_acked_fire_sequence = ack_sequence
	var remaining: Array = []
	for raw in pending_fire_intents:
		var row := raw as Dictionary
		if int(row.get("fire_sequence", -1)) > ack_sequence: remaining.append(row)
	pending_fire_intents = remaining
	last_server_verdict = verdict.duplicate(true)
	last_server_verdict["server_verified"] = true
	combat_feedback.emit(outcome, {
		"target_entity_id":str(verdict.get("target_entity_id", "")),
		"amount":verdict.get("resolved_amount", 0),
		"reason":reason,"combat_revision":incoming_revision,"server_tick":incoming_tick,
		"confirmed_hit":outcome in ["HIT", "CRITICAL", "HEAL"]
	})
	changed.emit()
	return true

func invalidate_from_world_resync() -> void:
	pending_fire_intents.clear()
	selected_target_entity_id = ""
	selected_target_spawn_generation = -1
	last_server_verdict = {"outcome":"WORLD_RESYNC","reason":"fresh_world_baseline_required","server_verified":false}
	changed.emit()

func snapshot() -> Dictionary:
	return {
		"source":"SERVER" if combat_revision >= 0 else "LOCAL_PREVIEW",
		"session_id":session_id,"environment":environment,"instance_id":instance_id,
		"attacker_entity_id":attacker_entity_id,"attacker_spawn_generation":attacker_spawn_generation,
		"selected_target_entity_id":selected_target_entity_id,"selected_target_spawn_generation":selected_target_spawn_generation,
		"combat_revision":combat_revision,"server_tick":server_tick,"last_acked_fire_sequence":last_acked_fire_sequence,
		"pending_fire_count":pending_fire_intents.size(),"last_verdict":last_server_verdict.duplicate(true)
	}

func can_client_confirm_target_legality() -> bool: return false
func can_client_confirm_range() -> bool: return false
func can_client_confirm_line_of_fire() -> bool: return false
func can_client_confirm_reload_cooldown() -> bool: return false
func can_client_consume_ammo() -> bool: return false
func can_client_resolve_hit() -> bool: return false
func can_client_apply_damage_or_heal() -> bool: return false
func can_client_confirm_death() -> bool: return false
func can_client_settle_combat_reward() -> bool: return false
func can_client_advance_combat_revision() -> bool: return false
func can_client_transfer_test_combat_to_global() -> bool: return false

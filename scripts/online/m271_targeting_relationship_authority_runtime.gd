class_name M271TargetingRelationshipAuthorityRuntime
extends Node
## M271 authoritative targeting / relationship / aggro / safe-zone boundary.
## M271 decides whether a relationship/target is legal before M269 may resolve fire.
## Local hover, cycling, outlines and threat hints are presentation only.
signal changed
signal targeting_feedback(kind: String, payload: Dictionary)

var session_id := ""
var environment := ""
var instance_id := ""
var actor_entity_id := ""
var actor_spawn_generation := -1
var targeting_revision := -1
var server_tick := -1
var selected_target: Dictionary = {}
var relationship_state: Dictionary = {}
var aggro_state: Dictionary = {}
var zone_state: Dictionary = {}
var pvp_state: Dictionary = {}
var protection_state: Dictionary = {}
var last_verdict: Dictionary = {}

func _ready() -> void:
	add_to_group("targeting_relationship_authority_readiness")

func bind_combat(combat: M269AuthoritativeCombatRuntime) -> bool:
	if combat == null: return false
	var s:=combat.snapshot()
	if str(s.get("source","")) != "SERVER": return false
	session_id=str(s.get("session_id","")); environment=str(s.get("environment","")).to_upper(); instance_id=str(s.get("instance_id",""))
	actor_entity_id=str(s.get("attacker_entity_id","")); actor_spawn_generation=int(s.get("attacker_spawn_generation",-1)); server_tick=int(s.get("server_tick",-1))
	if session_id.is_empty() or instance_id.is_empty() or actor_entity_id.is_empty() or actor_spawn_generation < 0: return false
	changed.emit(); return true

func ingest_server_targeting_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if str(snapshot.get("session_id",""))!=session_id or str(snapshot.get("environment","")).to_upper()!=environment or str(snapshot.get("instance_id",""))!=instance_id: return false
	if str(snapshot.get("actor_entity_id",""))!=actor_entity_id or int(snapshot.get("actor_spawn_generation",-1))!=actor_spawn_generation: return false
	var rev:=int(snapshot.get("targeting_revision",-1)); var tick:=int(snapshot.get("server_tick",-1))
	if rev<=targeting_revision or tick<server_tick: return false
	for key in ["selected_target","relationship_state","aggro_state","zone_state","pvp_state","protection_state"]:
		if not snapshot.get(key,{}) is Dictionary: return false
	targeting_revision=rev; server_tick=tick
	selected_target=(snapshot.get("selected_target",{}) as Dictionary).duplicate(true)
	relationship_state=(snapshot.get("relationship_state",{}) as Dictionary).duplicate(true)
	aggro_state=(snapshot.get("aggro_state",{}) as Dictionary).duplicate(true)
	zone_state=(snapshot.get("zone_state",{}) as Dictionary).duplicate(true)
	pvp_state=(snapshot.get("pvp_state",{}) as Dictionary).duplicate(true)
	protection_state=(snapshot.get("protection_state",{}) as Dictionary).duplicate(true)
	last_verdict={"kind":"TARGETING_SNAPSHOT","server_verified":true,"targeting_revision":rev,"server_tick":tick}
	targeting_feedback.emit("TARGETING_CONFIRMED",last_verdict.duplicate(true)); changed.emit(); return true

func ingest_server_target_verdict(verdict: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if str(verdict.get("session_id",""))!=session_id or str(verdict.get("environment","")).to_upper()!=environment or str(verdict.get("instance_id",""))!=instance_id: return false
	if str(verdict.get("actor_entity_id",""))!=actor_entity_id or int(verdict.get("actor_spawn_generation",-1))!=actor_spawn_generation: return false
	var rev:=int(verdict.get("targeting_revision",-1)); var tick:=int(verdict.get("server_tick",-1))
	if rev<=targeting_revision or tick<server_tick: return false
	var result:=str(verdict.get("result","")).to_upper()
	if result not in ["ALLOWED","REJECTED","TARGET_LOST","PROTECTED","SAFE_ZONE_BLOCKED","FRIENDLY_BLOCKED","PVP_RULE_BLOCKED","INVALID_RELATIONSHIP"]: return false
	targeting_revision=rev; server_tick=tick
	if verdict.has("selected_target") and verdict.get("selected_target") is Dictionary: selected_target=(verdict.get("selected_target") as Dictionary).duplicate(true)
	if result in ["TARGET_LOST","REJECTED","PROTECTED","SAFE_ZONE_BLOCKED","FRIENDLY_BLOCKED","PVP_RULE_BLOCKED","INVALID_RELATIONSHIP"] and bool(verdict.get("clear_target",false)): selected_target.clear()
	last_verdict=verdict.duplicate(true); last_verdict["server_verified"]=true
	targeting_feedback.emit(result,last_verdict.duplicate(true)); changed.emit(); return true

func stage_target_intent(target_entity_id:String, target_spawn_generation:int, intent_kind:String="SELECT") -> Dictionary:
	if target_entity_id.is_empty() or target_spawn_generation < 0: return {}
	var kind:=intent_kind.to_upper()
	if kind not in ["SELECT","CYCLE_NEXT","CYCLE_PREVIOUS","CLEAR","ASSIST"]: return {}
	return {"kind":"TARGET_INTENT","intent_kind":kind,"target_entity_id":target_entity_id,"target_spawn_generation":target_spawn_generation,"expected_targeting_revision":targeting_revision,"environment":environment,"instance_id":instance_id,"authority":"CLIENT_INTENT_ONLY","can_authorize_attack":false}

func local_target_hint(candidate:Dictionary)->Dictionary:
	# Presentation helper only; server verdict remains required for attack legality.
	return {"target_entity_id":str(candidate.get("entity_id","")),"relationship_hint":str(candidate.get("relationship_hint","UNKNOWN")),"threat_hint":str(candidate.get("threat_hint","UNKNOWN")),"authority":"LOCAL_PRESENTATION_ONLY","attack_legal":false}

func invalidate_from_world_resync()->void:
	selected_target.clear(); relationship_state.clear(); aggro_state.clear(); zone_state.clear(); pvp_state.clear(); protection_state.clear(); last_verdict={"kind":"WORLD_RESYNC","server_verified":false}; changed.emit()

func snapshot()->Dictionary:
	return {"source":"SERVER" if targeting_revision>=0 else "LOCAL_PREVIEW","session_id":session_id,"environment":environment,"instance_id":instance_id,"actor_entity_id":actor_entity_id,"actor_spawn_generation":actor_spawn_generation,"targeting_revision":targeting_revision,"server_tick":server_tick,"selected_target":selected_target.duplicate(true),"relationship_state":relationship_state.duplicate(true),"aggro_state":aggro_state.duplicate(true),"zone_state":zone_state.duplicate(true),"pvp_state":pvp_state.duplicate(true),"protection_state":protection_state.duplicate(true),"last_verdict":last_verdict.duplicate(true)}

func can_client_authorize_target()->bool: return false
func can_client_override_safe_zone()->bool: return false
func can_client_set_relationship()->bool: return false
func can_client_set_aggro()->bool: return false
func can_client_remove_pvp_protection()->bool: return false
func can_client_grant_kill_legality()->bool: return false
func can_client_override_friendly_fire()->bool: return false
func can_client_transfer_test_relationships_to_global()->bool: return false

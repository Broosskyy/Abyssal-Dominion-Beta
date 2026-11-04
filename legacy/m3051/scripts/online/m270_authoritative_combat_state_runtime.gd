class_name M270AuthoritativeCombatStateRuntime
extends Node
## M270 authoritative combat state / reload / status effect / projectile boundary.
## M269 decides fire legality/outcome. M270 maintains the server-confirmed temporal combat state.
## Local timers, VFX and projectile interpolation are presentation only and never apply damage/healing.
signal changed
signal state_feedback(kind: String, payload: Dictionary)

var session_id := ""
var environment := ""
var instance_id := ""
var entity_id := ""
var spawn_generation := -1
var combat_state_revision := -1
var server_tick := -1
var combat_phase := "IDLE"
var weapon_states: Dictionary = {}
var active_status_effects: Dictionary = {}
var active_projectiles: Dictionary = {}
var authoritative_resources: Dictionary = {"health":0,"shield":0,"repair_state":"NONE"}
var last_state_event: Dictionary = {}

func _ready() -> void:
	add_to_group("authoritative_combat_state_readiness")

func bind_combat(combat: M269AuthoritativeCombatRuntime) -> bool:
	if combat == null: return false
	var s:=combat.snapshot()
	if str(s.get("source","")) != "SERVER": return false
	session_id=str(s.get("session_id","")); environment=str(s.get("environment","")).to_upper(); instance_id=str(s.get("instance_id",""))
	entity_id=str(s.get("attacker_entity_id","")); spawn_generation=int(s.get("attacker_spawn_generation",-1)); server_tick=int(s.get("server_tick",-1))
	if session_id.is_empty() or instance_id.is_empty() or entity_id.is_empty() or spawn_generation < 0: return false
	changed.emit(); return true

func ingest_server_combat_state(state: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if str(state.get("session_id",""))!=session_id or str(state.get("environment","")).to_upper()!=environment or str(state.get("instance_id",""))!=instance_id: return false
	if str(state.get("entity_id",""))!=entity_id or int(state.get("spawn_generation",-1))!=spawn_generation: return false
	var rev:=int(state.get("combat_state_revision",-1)); var tick:=int(state.get("server_tick",-1))
	if rev<=combat_state_revision or tick<server_tick: return false
	var phase:=str(state.get("combat_phase","IDLE")).to_upper()
	if phase not in ["IDLE","ENGAGED","RELOADING","DISABLED","DEFEATED"]: return false
	var weapons=state.get("weapon_states",{}); var effects=state.get("status_effects",{}); var projectiles=state.get("projectiles",{}); var resources=state.get("resources",{})
	if not (weapons is Dictionary) or not (effects is Dictionary) or not (projectiles is Dictionary) or not (resources is Dictionary): return false
	combat_state_revision=rev; server_tick=tick; combat_phase=phase
	weapon_states=(weapons as Dictionary).duplicate(true); active_status_effects=(effects as Dictionary).duplicate(true); active_projectiles=(projectiles as Dictionary).duplicate(true); authoritative_resources=(resources as Dictionary).duplicate(true)
	last_state_event={"kind":"STATE_SNAPSHOT","server_verified":true,"combat_state_revision":rev,"server_tick":tick}
	state_feedback.emit("STATE_CONFIRMED", last_state_event.duplicate(true)); changed.emit(); return true

func ingest_server_state_event(event: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if str(event.get("session_id",""))!=session_id or str(event.get("environment","")).to_upper()!=environment or str(event.get("instance_id",""))!=instance_id: return false
	if str(event.get("entity_id",""))!=entity_id or int(event.get("spawn_generation",-1))!=spawn_generation: return false
	var rev:=int(event.get("combat_state_revision",-1)); var tick:=int(event.get("server_tick",-1))
	if rev<=combat_state_revision or tick<server_tick: return false
	var kind:=str(event.get("kind","")).to_upper()
	if kind not in ["RELOAD_STARTED","RELOAD_COMPLETED","STATUS_APPLIED","STATUS_REFRESHED","STATUS_REMOVED","DOT_TICK","HOT_TICK","REPAIR_APPLIED","SHIELD_APPLIED","PROJECTILE_SPAWNED","PROJECTILE_IMPACT","PROJECTILE_EXPIRED","COMBAT_ENTERED","COMBAT_EXITED","DEFEATED"]: return false
	combat_state_revision=rev; server_tick=tick
	_apply_server_event(kind,event)
	last_state_event=event.duplicate(true); last_state_event["server_verified"]=true
	state_feedback.emit(kind,last_state_event.duplicate(true)); changed.emit(); return true

func _apply_server_event(kind:String,event:Dictionary)->void:
	var weapon_id:=str(event.get("weapon_instance_id","")); var effect_id:=str(event.get("effect_instance_id","")); var projectile_id:=str(event.get("projectile_id",""))
	match kind:
		"RELOAD_STARTED", "RELOAD_COMPLETED":
			if not weapon_id.is_empty(): weapon_states[weapon_id]=(event.get("weapon_state",{}) as Dictionary).duplicate(true)
		"STATUS_APPLIED", "STATUS_REFRESHED":
			if not effect_id.is_empty(): active_status_effects[effect_id]=(event.get("status_effect",{}) as Dictionary).duplicate(true)
		"STATUS_REMOVED":
			active_status_effects.erase(effect_id)
		"PROJECTILE_SPAWNED":
			if not projectile_id.is_empty(): active_projectiles[projectile_id]=(event.get("projectile_state",{}) as Dictionary).duplicate(true)
		"PROJECTILE_IMPACT", "PROJECTILE_EXPIRED":
			active_projectiles.erase(projectile_id)
		"COMBAT_ENTERED": combat_phase="ENGAGED"
		"COMBAT_EXITED": combat_phase="IDLE"
		"DEFEATED": combat_phase="DEFEATED"
	if event.has("resources") and event.get("resources") is Dictionary: authoritative_resources=(event.get("resources") as Dictionary).duplicate(true)

func stage_local_projectile_visual(projectile_id:String, weapon_family:String, target_entity_id:String)->Dictionary:
	# Rendering helper only: never used as an authoritative projectile or impact record.
	if projectile_id.is_empty() or target_entity_id.is_empty(): return {}
	return {"projectile_id":projectile_id,"weapon_family":weapon_family.to_upper(),"target_entity_id":target_entity_id,"authority":"LOCAL_PRESENTATION_ONLY","can_apply_impact":false}

func local_reload_display(weapon_instance_id:String)->Dictionary:
	var w:=weapon_states.get(weapon_instance_id,{}) as Dictionary
	return {"weapon_instance_id":weapon_instance_id,"state":str(w.get("state","UNKNOWN")),"server_tick":server_tick,"authority":"SERVER_REPLICA" if not w.is_empty() else "UNKNOWN"}

func invalidate_from_world_resync()->void:
	weapon_states.clear(); active_status_effects.clear(); active_projectiles.clear(); combat_phase="IDLE"; last_state_event={"kind":"WORLD_RESYNC","server_verified":false}; changed.emit()

func snapshot()->Dictionary:
	return {"source":"SERVER" if combat_state_revision>=0 else "LOCAL_PREVIEW","session_id":session_id,"environment":environment,"instance_id":instance_id,"entity_id":entity_id,"spawn_generation":spawn_generation,"combat_state_revision":combat_state_revision,"server_tick":server_tick,"combat_phase":combat_phase,"weapon_states":weapon_states.duplicate(true),"status_effects":active_status_effects.duplicate(true),"projectiles":active_projectiles.duplicate(true),"resources":authoritative_resources.duplicate(true),"last_state_event":last_state_event.duplicate(true)}

func can_client_complete_reload()->bool: return false
func can_client_apply_status_effect()->bool: return false
func can_client_tick_dot_or_hot()->bool: return false
func can_client_apply_repair_or_shield()->bool: return false
func can_client_spawn_authoritative_projectile()->bool: return false
func can_client_confirm_projectile_impact()->bool: return false
func can_client_apply_projectile_damage()->bool: return false
func can_client_advance_combat_state_revision()->bool: return false
func can_client_transfer_test_combat_state_to_global()->bool: return false

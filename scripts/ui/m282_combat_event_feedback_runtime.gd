class_name M282CombatEventFeedbackRuntime
extends Node
## M282 server-confirmed combat event presentation, coalescing and impact-feedback layer.
## Presentation-only over M269/M270/M281. It never authors damage, healing, crits, blocks or projectile impact.
signal changed
signal feedback_presented(kind: String, payload: Dictionary)

var combat: M269AuthoritativeCombatRuntime
var combat_state: M270AuthoritativeCombatStateRuntime
var combat_hud: M281CombatHudConvergenceRuntime
var environment := ""
var entity_id := ""
var feedback_revision := -1
var last_server_tick := -1
var last_event_sequence := -1
var seen_event_ids: Dictionary = {}
var coalesced_entries: Array = []
var last_confirmed_event: Dictionary = {}

const SERVER_KINDS := ["HIT","CRITICAL","BLOCKED","MISS","HEAL","DOT_TICK","HOT_TICK","REPAIR_APPLIED","SHIELD_APPLIED","PROJECTILE_IMPACT"]
const OUTCOME_KINDS := ["HIT","CRITICAL","BLOCKED","MISS","HEAL"]

func _ready() -> void:
	add_to_group("combat_event_feedback_readiness")

func bind_authority_layers(c:M269AuthoritativeCombatRuntime, s:M270AuthoritativeCombatStateRuntime, h:M281CombatHudConvergenceRuntime) -> bool:
	if c==null or s==null or h==null: return false
	var cs:=c.snapshot(); var ss:=s.snapshot(); var hs:=h.snapshot()
	if str(cs.get("source",""))!="SERVER" or str(ss.get("source",""))!="SERVER" or str(hs.get("source",""))!="SERVER": return false
	var ce:=str(cs.get("environment","")).to_upper(); var se:=str(ss.get("environment","")).to_upper(); var he:=str(hs.get("environment","")).to_upper()
	if ce.is_empty() or ce!=se or ce!=he: return false
	combat=c; combat_state=s; combat_hud=h; environment=ce; entity_id=str(cs.get("attacker_entity_id","")); last_server_tick=maxi(int(cs.get("server_tick",-1)),int(ss.get("server_tick",-1)))
	if entity_id.is_empty(): return false
	changed.emit(); return true

func ingest_server_feedback_event(event:Dictionary, server_verified:bool) -> bool:
	if not server_verified or combat==null or combat_state==null or combat_hud==null: return false
	if str(event.get("environment","")).to_upper()!=environment: return false
	var event_id:=str(event.get("event_id","")); var kind:=str(event.get("kind","")).to_upper()
	if event_id.is_empty() or kind not in SERVER_KINDS or seen_event_ids.has(event_id): return false
	var revision:=int(event.get("feedback_revision",-1)); var tick:=int(event.get("server_tick",-1)); var sequence:=int(event.get("event_sequence",-1))
	if revision<=feedback_revision or tick<last_server_tick or sequence<=last_event_sequence: return false
	if str(event.get("source_entity_id",entity_id))!=entity_id: return false
	var amount:=float(event.get("resolved_amount",0.0))
	if amount<0.0: return false
	feedback_revision=revision; last_server_tick=tick; last_event_sequence=sequence; seen_event_ids[event_id]=true
	last_confirmed_event=event.duplicate(true); last_confirmed_event["server_verified"]=true
	_coalesce(last_confirmed_event)
	feedback_presented.emit(kind,last_confirmed_event.duplicate(true)); changed.emit(); return true

func sync_latest_server_outcome() -> bool:
	# Safe bridge for local prototype wiring: only copies M269's already server-verified verdict.
	if combat==null: return false
	var snap:=combat.snapshot(); var verdict:=snap.get("last_verdict",{}) as Dictionary
	if not bool(verdict.get("server_verified",false)): return false
	var revision:=int(snap.get("combat_revision",-1)); var tick:=int(snap.get("server_tick",-1)); var seq:=int(snap.get("last_acked_fire_sequence",-1))
	var kind:=str(verdict.get("outcome","")).to_upper()
	if kind not in OUTCOME_KINDS or revision<=feedback_revision: return false
	var derived_id:="COMBAT:%s:%d:%d"%[entity_id,revision,seq]
	return ingest_server_feedback_event({"event_id":derived_id,"kind":kind,"environment":environment,"source_entity_id":entity_id,"target_entity_id":str(verdict.get("target_entity_id","")),"resolved_amount":verdict.get("resolved_amount",0),"feedback_revision":revision,"server_tick":tick,"event_sequence":maxi(seq,last_event_sequence+1),"combat_revision":revision,"authority":"SERVER"},true)

func _coalesce(event:Dictionary) -> void:
	var kind:=str(event.get("kind","HIT")).to_upper(); var target:=str(event.get("target_entity_id","")); var family:=str(event.get("weapon_family",event.get("source_family",""))).to_upper()
	var key:="%s|%s|%s"%[target,kind,family]
	for i in range(coalesced_entries.size()-1,-1,-1):
		var row:=coalesced_entries[i] as Dictionary
		if str(row.get("coalesce_key",""))==key and kind in ["HIT","HEAL","DOT_TICK","HOT_TICK"]:
			row["resolved_amount"]=float(row.get("resolved_amount",0.0))+float(event.get("resolved_amount",0.0)); row["event_count"]=int(row.get("event_count",1))+1; row["server_tick"]=int(event.get("server_tick",last_server_tick)); row["feedback_revision"]=feedback_revision; coalesced_entries[i]=row; return
	var entry:={"coalesce_key":key,"kind":kind,"target_entity_id":target,"resolved_amount":event.get("resolved_amount",0),"event_count":1,"server_tick":int(event.get("server_tick",last_server_tick)),"feedback_revision":feedback_revision,"weapon_family":family,"impact_vfx_hook":str(event.get("impact_vfx_hook","")),"icon_asset_id":str(event.get("icon_asset_id","")),"server_verified":true}
	coalesced_entries.append(entry)

func presentation_view(layout:Dictionary) -> Dictionary:
	if feedback_revision<0: return {}
	var compact:=bool(layout.get("compact",false)); var entries:=coalesced_entries.duplicate(true)
	# Presentation budget is a local layout fallback, not a gameplay/balance constant; final density remains measurement-driven.
	var visible_budget:=int(layout.get("combat_feedback_visible_slots",3 if compact else 5)); visible_budget=maxi(1,visible_budget)
	if entries.size()>visible_budget: entries=entries.slice(entries.size()-visible_budget,entries.size())
	var latest:Dictionary=entries[-1] as Dictionary if not entries.is_empty() else {}
	return {"source":"SERVER","feedback_revision":feedback_revision,"server_tick":last_server_tick,"entries":entries,"latest":latest,"compact":compact,"authority":"LOCAL_RENDER_OF_SERVER_CONFIRMED_COMBAT_EVENTS"}

func local_presentation_intent(request_id:String, action:String) -> Dictionary:
	var kind:=action.to_upper()
	if request_id.is_empty() or kind not in ["DISMISS_LATEST","CLEAR_PRESENTED_FEED","OPEN_COMBAT_DETAIL"]: return {}
	return {"intent":"COMBAT_FEEDBACK_"+kind,"request_id":request_id,"expected_feedback_revision":feedback_revision,"environment":environment,"authority":"CLIENT_PRESENTATION_INTENT_ONLY","can_apply_damage":false,"can_apply_heal":false,"can_create_crit":false,"can_confirm_block":false,"can_confirm_projectile_impact":false}

func clear_local_presentation() -> void:
	coalesced_entries.clear(); changed.emit()

func invalidate_from_world_resync() -> void:
	coalesced_entries.clear(); seen_event_ids.clear(); last_confirmed_event={"kind":"WORLD_RESYNC","server_verified":false}; feedback_revision=-1; last_event_sequence=-1; changed.emit()

func snapshot() -> Dictionary:
	return {"source":"SERVER" if feedback_revision>=0 else "LOCAL_PREVIEW","environment":environment,"entity_id":entity_id,"feedback_revision":feedback_revision,"server_tick":last_server_tick,"last_event_sequence":last_event_sequence,"entry_count":coalesced_entries.size(),"last_confirmed_event":last_confirmed_event.duplicate(true)}

func can_client_create_confirmed_damage_number() -> bool: return false
func can_client_apply_damage_or_heal() -> bool: return false
func can_client_confirm_critical_or_block() -> bool: return false
func can_client_confirm_projectile_impact() -> bool: return false
func can_client_advance_feedback_revision() -> bool: return false
func can_client_transfer_test_feedback_to_global() -> bool: return false

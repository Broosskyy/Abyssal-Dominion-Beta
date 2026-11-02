class_name M281CombatHudConvergenceRuntime
extends Node
## M281 presentation-only combat HUD convergence over M269/M270/M271.
## Clean-room naval-MMO readability inspired by genre references such as Seafight and Battle of Sea.
## The client may render confirmed targeting/reload/status/outcome state, but never author combat truth.
signal changed

var combat: M269AuthoritativeCombatRuntime
var combat_state: M270AuthoritativeCombatStateRuntime
var targeting: M271TargetingRelationshipAuthorityRuntime
var visual_revision := -1
var last_server_tick := -1
var environment := ""

func _ready() -> void:
	add_to_group("combat_hud_convergence_readiness")

func bind_authority_layers(c:M269AuthoritativeCombatRuntime, s:M270AuthoritativeCombatStateRuntime, t:M271TargetingRelationshipAuthorityRuntime) -> bool:
	if c==null or s==null or t==null: return false
	var cs:=c.snapshot(); var ss:=s.snapshot(); var ts:=t.snapshot()
	if str(cs.get("source",""))!="SERVER" or str(ss.get("source",""))!="SERVER" or str(ts.get("source",""))!="SERVER": return false
	var ce:=str(cs.get("environment","")).to_upper(); var se:=str(ss.get("environment","")).to_upper(); var te:=str(ts.get("environment","")).to_upper()
	if ce.is_empty() or ce!=se or ce!=te: return false
	combat=c; combat_state=s; targeting=t; environment=ce
	_refresh_revision(); changed.emit(); return true

func _refresh_revision() -> void:
	if combat==null or combat_state==null or targeting==null: return
	var cs:=combat.snapshot(); var ss:=combat_state.snapshot(); var ts:=targeting.snapshot()
	visual_revision=maxi(int(cs.get("combat_revision",-1)),maxi(int(ss.get("combat_state_revision",-1)),int(ts.get("targeting_revision",-1))))
	last_server_tick=maxi(int(cs.get("server_tick",-1)),maxi(int(ss.get("server_tick",-1)),int(ts.get("server_tick",-1))))

func presentation_view(layout:Dictionary) -> Dictionary:
	if combat==null or combat_state==null or targeting==null: return {}
	var cs:=combat.snapshot(); var ss:=combat_state.snapshot(); var ts:=targeting.snapshot()
	if str(cs.get("source",""))!="SERVER" or str(ss.get("source",""))!="SERVER" or str(ts.get("source",""))!="SERVER": return {}
	_refresh_revision()
	var selected:Dictionary=ts.get("selected_target",{}) as Dictionary
	var relation:Dictionary=ts.get("relationship_state",{}) as Dictionary
	var protection:Dictionary=ts.get("protection_state",{}) as Dictionary
	var verdict:Dictionary=cs.get("last_verdict",{}) as Dictionary
	var weapon_states:Dictionary=ss.get("weapon_states",{}) as Dictionary
	var primary_weapon:Dictionary={}
	for key in weapon_states.keys(): primary_weapon=(weapon_states.get(key,{}) as Dictionary).duplicate(true); break
	var effects:Array=[]
	var status:Dictionary=ss.get("status_effects",{}) as Dictionary
	for key in status.keys():
		var row:Dictionary=status.get(key,{}) as Dictionary
		effects.append({"id":str(key),"label":str(row.get("label",row.get("effect_id",key))).replace("_"," ").to_upper(),"kind":str(row.get("kind",row.get("type","STATUS"))).to_upper()})
		if effects.size()>=4: break
	var compact:=bool(layout.get("compact",false))
	return {
		"source":"SERVER",
		"visual_revision":visual_revision,
		"server_tick":last_server_tick,
		"target_entity_id":str(selected.get("entity_id",selected.get("target_entity_id",cs.get("selected_target_entity_id","")))),
		"target_name":str(selected.get("display_name",selected.get("name",""))),
		"relationship":str(relation.get("relationship",relation.get("state","UNKNOWN"))).to_upper(),
		"target_legal":bool(selected.get("attack_legal",false)) or str((ts.get("last_verdict",{}) as Dictionary).get("result",""))=="ALLOWED",
		"protection_state":str(protection.get("state","NONE")).to_upper(),
		"combat_phase":str(ss.get("combat_phase","IDLE")).to_upper(),
		"reload_state":str(primary_weapon.get("state","UNKNOWN")).to_upper(),
		"reload_progress":primary_weapon.get("progress",primary_weapon.get("reload_progress",null)),
		"weapon_family":str(primary_weapon.get("weapon_family",primary_weapon.get("family",""))).to_upper(),
		"ammo_asset_id":str(primary_weapon.get("ammo_asset_id",primary_weapon.get("ammo_id",""))),
		"status_effects":effects,
		"last_outcome":str(verdict.get("outcome","WAITING")).to_upper(),
		"resolved_amount":verdict.get("resolved_amount",0),
		"boss_phase":int(selected.get("boss_phase",selected.get("phase",0))),
		"telegraph":str(selected.get("telegraph",selected.get("phase_telegraph",""))).to_upper(),
		"compact":compact,
		"authority":"LOCAL_RENDER_OF_SERVER_CONFIRMED_COMBAT_STATE"
	}

func local_presentation_intent(request_id:String, action:String) -> Dictionary:
	var kind:=action.to_upper()
	if request_id.is_empty() or kind not in ["CYCLE_TARGET","OPEN_AMMO","OPEN_STATUS_DETAIL","DISMISS_COMBAT_FEEDBACK"]: return {}
	return {"intent":"COMBAT_HUD_"+kind,"request_id":request_id,"expected_visual_revision":visual_revision,"environment":environment,"authority":"CLIENT_PRESENTATION_INTENT_ONLY","can_authorize_target":false,"can_complete_reload":false,"can_consume_ammo":false,"can_apply_damage":false,"can_apply_status":false}

func invalidate_from_world_resync() -> void:
	combat=null; combat_state=null; targeting=null; visual_revision=-1; last_server_tick=-1; changed.emit()

func snapshot() -> Dictionary:
	return {"source":"SERVER" if visual_revision>=0 else "LOCAL_PREVIEW","environment":environment,"visual_revision":visual_revision,"server_tick":last_server_tick}

func can_client_authorize_target() -> bool: return false
func can_client_complete_reload() -> bool: return false
func can_client_consume_ammo() -> bool: return false
func can_client_confirm_hit_or_damage() -> bool: return false
func can_client_apply_status_effect() -> bool: return false
func can_client_advance_boss_phase() -> bool: return false
func can_client_transfer_test_combat_visuals_to_global() -> bool: return false

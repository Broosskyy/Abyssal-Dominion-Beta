class_name M283ProjectileSalvoPresentationRuntime
extends Node
## M283 presentation-only projectile/salvo/harpoon/audio-haptics layer over server-confirmed M270/M282 combat truth.
signal changed
signal presentation_event(kind:String,payload:Dictionary)

var combat_state:M270AuthoritativeCombatStateRuntime
var combat_feedback:M282CombatEventFeedbackRuntime
var environment:=""
var presentation_revision:=-1
var last_server_tick:=-1
var last_event_sequence:=-1
var seen_event_ids:Dictionary={}
var active_projectiles:Array=[]
var recent_impacts:Array=[]

const KINDS=["CANNON_SALVO","PROJECTILE_SPAWN","PROJECTILE_TRAVEL","PROJECTILE_IMPACT","HARPOON_LAUNCH","HARPOON_IMPACT","WATER_IMPACT","HULL_IMPACT","MONSTER_IMPACT"]

func _ready()->void: add_to_group("projectile_salvo_presentation_readiness")

func bind_authority_layers(s:M270AuthoritativeCombatStateRuntime,f:M282CombatEventFeedbackRuntime)->bool:
	if s==null or f==null:return false
	var ss:=s.snapshot(); var fs:=f.snapshot()
	if str(ss.get("source",""))!="SERVER" or str(fs.get("source",""))!="SERVER":return false
	var se:=str(ss.get("environment","")).to_upper(); var fe:=str(fs.get("environment","")).to_upper()
	if se.is_empty() or se!=fe:return false
	combat_state=s; combat_feedback=f; environment=se; last_server_tick=maxi(int(ss.get("server_tick",-1)),int(fs.get("server_tick",-1))); changed.emit(); return true

func ingest_server_presentation_event(event:Dictionary,server_verified:bool)->bool:
	if not server_verified or combat_state==null or combat_feedback==null:return false
	if str(event.get("environment","")).to_upper()!=environment:return false
	var id:=str(event.get("event_id","")); var kind:=str(event.get("kind","")).to_upper()
	if id.is_empty() or kind not in KINDS or seen_event_ids.has(id):return false
	var rev:=int(event.get("presentation_revision",-1)); var tick:=int(event.get("server_tick",-1)); var seq:=int(event.get("event_sequence",-1))
	if rev<=presentation_revision or tick<last_server_tick or seq<=last_event_sequence:return false
	presentation_revision=rev; last_server_tick=tick; last_event_sequence=seq; seen_event_ids[id]=true
	var row:=event.duplicate(true); row["server_verified"]=true
	if kind in ["PROJECTILE_SPAWN","PROJECTILE_TRAVEL","CANNON_SALVO","HARPOON_LAUNCH"]: active_projectiles.append(row)
	if kind in ["PROJECTILE_IMPACT","HARPOON_IMPACT","WATER_IMPACT","HULL_IMPACT","MONSTER_IMPACT"]: recent_impacts.append(row)
	presentation_event.emit(kind,row.duplicate(true)); changed.emit(); return true

func presentation_view(layout:Dictionary)->Dictionary:
	if presentation_revision<0:return {}
	var compact:=bool(layout.get("compact",false)); var projectile_budget:=int(layout.get("projectile_visual_slots",4 if compact else 8)); var impact_budget:=int(layout.get("impact_visual_slots",2 if compact else 4))
	var p:=active_projectiles.duplicate(true); var i:=recent_impacts.duplicate(true)
	if p.size()>projectile_budget:p=p.slice(p.size()-projectile_budget,p.size())
	if i.size()>impact_budget:i=i.slice(i.size()-impact_budget,i.size())
	return {"source":"SERVER","presentation_revision":presentation_revision,"server_tick":last_server_tick,"projectiles":p,"impacts":i,"compact":compact,"audio_haptics_policy":"LOCAL_PLAYBACK_OF_SERVER_CONFIRMED_EVENT","authority":"PRESENTATION_ONLY"}

func local_presentation_intent(request_id:String,action:String)->Dictionary:
	var a:=action.to_upper(); if request_id.is_empty() or a not in ["MUTE_LOCAL_AUDIO","UNMUTE_LOCAL_AUDIO","DISABLE_LOCAL_HAPTICS","ENABLE_LOCAL_HAPTICS"]:return {}
	return {"intent":"M283_"+a,"request_id":request_id,"environment":environment,"authority":"CLIENT_PRESENTATION_PREFERENCE_ONLY","can_confirm_hit":false,"can_apply_damage":false,"can_spawn_authoritative_projectile":false}

func invalidate_from_world_resync()->void:
	active_projectiles.clear(); recent_impacts.clear(); seen_event_ids.clear(); presentation_revision=-1; last_event_sequence=-1; changed.emit()

func snapshot()->Dictionary:return {"source":"SERVER" if presentation_revision>=0 else "LOCAL_PREVIEW","environment":environment,"presentation_revision":presentation_revision,"server_tick":last_server_tick,"last_event_sequence":last_event_sequence,"projectile_count":active_projectiles.size(),"impact_count":recent_impacts.size()}
func can_client_spawn_authoritative_projectile()->bool:return false
func can_client_confirm_projectile_impact()->bool:return false
func can_client_apply_damage_from_vfx()->bool:return false
func can_audio_or_haptics_confirm_hit()->bool:return false
func can_client_transfer_test_presentation_to_global()->bool:return false

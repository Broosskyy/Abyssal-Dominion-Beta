class_name M284NavalCombatIdentityRuntime
extends Node
## M284 presentation-only identity layer for cannon families, ammo/harpoon feel, impact materials and salvo rhythm.
signal changed

var projectile_presentation:M283ProjectileSalvoPresentationRuntime
var environment:=""
var profile_revision:=-1
var last_server_tick:=-1
var profiles:Dictionary={}
var active_profile_id:=""

const PROFILE_KINDS=["CANNON","AMMO","HARPOON","IMPACT_MATERIAL","AUDIO","SALVO_RHYTHM"]

func _ready()->void: add_to_group("naval_combat_identity_readiness")

func bind_projectile_presentation(runtime:M283ProjectileSalvoPresentationRuntime)->bool:
	if runtime==null:return false
	var s:=runtime.snapshot()
	if str(s.get("source",""))!="SERVER":return false
	var env:=str(s.get("environment","")).to_upper()
	if env.is_empty():return false
	projectile_presentation=runtime; environment=env; last_server_tick=int(s.get("server_tick",-1)); changed.emit(); return true

func ingest_server_profile_snapshot(snapshot:Dictionary,server_verified:bool)->bool:
	if not server_verified or projectile_presentation==null:return false
	if str(snapshot.get("environment","")).to_upper()!=environment:return false
	var rev:=int(snapshot.get("profile_revision",-1)); var tick:=int(snapshot.get("server_tick",-1))
	if rev<=profile_revision or tick<last_server_tick:return false
	var rows:Array=snapshot.get("profiles",[]) as Array; var next:Dictionary={}
	for raw in rows:
		var row:Dictionary=raw as Dictionary; var id:=str(row.get("profile_id","")); var kind:=str(row.get("kind","")).to_upper()
		if id.is_empty() or kind not in PROFILE_KINDS:continue
		var safe:=row.duplicate(true); safe["kind"]=kind; safe["server_verified"]=true
		# Profile IDs select authored presentation hooks only; numeric combat authority is never accepted here.
		for forbidden in ["damage","heal","range","reload_seconds","projectile_speed","crit_chance","hit_chance"]: safe.erase(forbidden)
		next[id]=safe
	profiles=next; profile_revision=rev; last_server_tick=tick; active_profile_id=str(snapshot.get("active_profile_id","")); changed.emit(); return true

func presentation_view(layout:Dictionary)->Dictionary:
	if profile_revision<0:return {}
	var compact:=bool(layout.get("compact",false)); var active:Dictionary=profiles.get(active_profile_id,{}) as Dictionary
	return {"source":"SERVER","environment":environment,"profile_revision":profile_revision,"server_tick":last_server_tick,"active_profile_id":active_profile_id,"active_profile":active.duplicate(true),"profile_count":profiles.size(),"compact":compact,"salvo_rhythm":"PRESENTATION_HOOK_ONLY","impact_material":"PRESENTATION_HOOK_ONLY","audio_identity":"LOCAL_PLAYBACK_OF_CONFIRMED_PROFILE","authority":"PRESENTATION_ONLY"}

func local_accessibility_intent(request_id:String,action:String)->Dictionary:
	var a:=action.to_upper(); if request_id.is_empty() or a not in ["REDUCE_COMBAT_MOTION","RESTORE_COMBAT_MOTION","REDUCE_HAPTICS","RESTORE_HAPTICS"]:return {}
	return {"intent":"M284_"+a,"request_id":request_id,"environment":environment,"authority":"CLIENT_PRESENTATION_PREFERENCE_ONLY","changes_damage":false,"changes_reload":false,"changes_projectile_truth":false}

func invalidate_from_world_resync()->void:
	profiles.clear(); active_profile_id=""; profile_revision=-1; changed.emit()

func snapshot()->Dictionary:return {"source":"SERVER" if profile_revision>=0 else "LOCAL_PREVIEW","environment":environment,"profile_revision":profile_revision,"server_tick":last_server_tick,"profile_count":profiles.size(),"active_profile_id":active_profile_id}
func can_client_change_damage_from_profile()->bool:return false
func can_client_change_reload_from_salvo_rhythm()->bool:return false
func can_client_change_projectile_truth_from_visual_profile()->bool:return false
func can_audio_profile_confirm_hit()->bool:return false
func can_client_transfer_test_profile_to_global()->bool:return false

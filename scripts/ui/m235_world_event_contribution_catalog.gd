class_name M235WorldEventContributionCatalog
extends RefCounted

## M235 contribution/ranking/eligibility presentation bridge.
## Never computes authoritative ranks, eligibility or reward grants. Connected play consumes a server/admin replica.
const FEEDBACK_SECONDS := 3.4

static func runtime(tree:SceneTree)->EventRuntime:
	return M234WorldEventObjectiveChainCatalog.runtime(tree)

static func snapshot(runtime_value:EventRuntime)->Dictionary:
	if runtime_value==null:return {"source":"none","eligibility_state":"unknown"}
	var replica:=runtime_value.contribution_replica_snapshot()
	if not replica.is_empty():
		return {
			"source":"authoritative_snapshot",
			"event_id":str(replica.get("event_id",runtime_value.active_event_id)),
			"revision":int(replica.get("revision",0)),
			"personal_contribution":maxf(0.0,float(replica.get("personal_contribution",0.0))),
			"group_contribution":maxf(0.0,float(replica.get("group_contribution",0.0))),
			"contribution_breakdown":replica.get("contribution_breakdown",{}),
			"personal_rank":maxi(0,int(replica.get("personal_rank",0))),
			"group_rank":maxi(0,int(replica.get("group_rank",0))),
			"participants":maxi(0,int(replica.get("participants",0))),
			"group_participants":maxi(0,int(replica.get("group_participants",0))),
			"tier":str(replica.get("tier","")),
			"next_threshold":maxf(0.0,float(replica.get("next_threshold",0.0))),
			"eligible":bool(replica.get("eligible",false)),
			"eligibility_state":str(replica.get("eligibility_state","participating")).to_lower(),
			"qualified_tier":str(replica.get("qualified_tier","")),
			"reward_publication_state":str(replica.get("reward_publication_state","unpublished")),
			"reward_summary":str(replica.get("reward_summary",""))
		}
	if not runtime_value.is_active():return {"source":"runtime_preview","eligibility_state":"unknown"}
	# Local prototype fallback is intentionally preview-only: no rank, eligibility or rewards are inferred.
	return {"source":"runtime_preview","event_id":runtime_value.active_event_id,"revision":0,
		"personal_contribution":float(runtime_value.score),"group_contribution":0.0,"contribution_breakdown":{},
		"personal_rank":0,"group_rank":0,"participants":0,"group_participants":0,"tier":"PREVIEW",
		"next_threshold":0.0,"eligible":false,"eligibility_state":"unknown","qualified_tier":"",
		"reward_publication_state":"preview_only","reward_summary":""}

static func compact_label(snapshot_value:Dictionary)->String:
	if snapshot_value.is_empty():return ""
	var personal:=float(snapshot_value.get("personal_contribution",0.0))
	var rank:=int(snapshot_value.get("personal_rank",0))
	if rank>0:return "BEITRAG %.0f · RANG #%d"%[personal,rank]
	return "BEITRAG %.0f · SERVER-RANG AUSSTEHEND"%personal

static func group_label(snapshot_value:Dictionary)->String:
	var amount:=float(snapshot_value.get("group_contribution",0.0)); var rank:=int(snapshot_value.get("group_rank",0))
	if amount<=0.0 and rank<=0:return ""
	return "GRUPPE %.0f%s"%[amount," · #%d"%rank if rank>0 else ""]

static func eligibility_label(snapshot_value:Dictionary)->String:
	var state:=str(snapshot_value.get("eligibility_state","unknown"))
	match state:
		"eligible": return "EVENT-BELOHNUNG BERECHTIGT"
		"qualified": return "EVENT-SCHWELLE QUALIFIZIERT"
		"settled": return "EVENT-AUSWERTUNG ABGESCHLOSSEN"
		"participating": return "EVENT-BEITRAG REGISTRIERT"
	return ""

static func transition_label(previous:Dictionary,current:Dictionary)->String:
	if current.is_empty() or str(current.get("source",""))!="authoritative_snapshot":return ""
	var prev_state:=str(previous.get("eligibility_state","unknown")); var next_state:=str(current.get("eligibility_state","unknown"))
	if prev_state!=next_state:
		var eligibility:=eligibility_label(current)
		if not eligibility.is_empty():return eligibility
	var prev_rank:=int(previous.get("personal_rank",0)); var next_rank:=int(current.get("personal_rank",0))
	if next_rank>0 and (prev_rank<=0 or next_rank<prev_rank):return "EVENT-RANG VERBESSERT · #%d"%next_rank
	var prev_tier:=str(previous.get("qualified_tier","")); var next_tier:=str(current.get("qualified_tier",""))
	if not next_tier.is_empty() and prev_tier!=next_tier:return "EVENT-STUFE · %s"%next_tier.to_upper()
	return ""

static func detail_lines(snapshot_value:Dictionary)->Array[String]:
	var rows:Array[String]=[]
	var personal:=compact_label(snapshot_value)
	if not personal.is_empty():rows.append(personal)
	var group:=group_label(snapshot_value)
	if not group.is_empty():rows.append(group)
	var tier:=str(snapshot_value.get("qualified_tier",snapshot_value.get("tier","")))
	if not tier.is_empty():rows.append("STUFE · %s"%tier.to_upper())
	return rows

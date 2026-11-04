class_name M236EventRankingViewCatalog
extends RefCounted

## M236 read-only event ranking/contribution view model.
## It formats the M235 authoritative replica for Command Deck UI only.
## It never computes authoritative ranking, qualification or reward claims.

static func runtime(tree:SceneTree)->EventRuntime:
	return M235WorldEventContributionCatalog.runtime(tree)

static func view_snapshot(runtime_value:EventRuntime)->Dictionary:
	var base:=M235WorldEventContributionCatalog.snapshot(runtime_value)
	if runtime_value==null:return base
	var replica:=runtime_value.contribution_replica_snapshot()
	if str(base.get("source",""))=="authoritative_snapshot":
		base["leaderboard_rows"]=replica.get("leaderboard_rows",[])
		base["group_leaderboard_rows"]=replica.get("group_leaderboard_rows",[])
		base["reward_claim_state"]=str(replica.get("reward_claim_state","not_claimable"))
		base["settlement_id"]=str(replica.get("settlement_id",""))
	return base

static func authority_label(snapshot_value:Dictionary)->String:
	return "SERVER-SNAPSHOT · READ ONLY" if str(snapshot_value.get("source",""))=="authoritative_snapshot" else "LOKALE VORSCHAU · KEIN LIVE-RANG"

static func personal_card(snapshot_value:Dictionary)->Dictionary:
	var amount:=float(snapshot_value.get("personal_contribution",0.0))
	var rank:=int(snapshot_value.get("personal_rank",0))
	var participants:=int(snapshot_value.get("participants",0))
	var state:="BEITRAG %.0f"%amount
	if rank>0:state+=" · RANG #%d"%rank
	var detail:="Persönlicher Eventbeitrag"
	if participants>0:detail+=" · %d Teilnehmer"%participants
	return {"title":"PERSÖNLICHE LEISTUNG","state":state,"detail":detail,"tone":"ready" if rank>0 else "info"}

static func group_card(snapshot_value:Dictionary)->Dictionary:
	var amount:=float(snapshot_value.get("group_contribution",0.0))
	var rank:=int(snapshot_value.get("group_rank",0))
	var participants:=int(snapshot_value.get("group_participants",0))
	var state:="GRUPPE %.0f"%amount
	if rank>0:state+=" · RANG #%d"%rank
	var detail:="Gruppenbeitrag"
	if participants>0:detail+=" · %d Gruppen/Teilnehmer im Snapshot"%participants
	return {"title":"GRUPPENBEITRAG","state":state,"detail":detail,"tone":"ready" if rank>0 else "info"}

static func qualification_card(snapshot_value:Dictionary)->Dictionary:
	var state:=str(snapshot_value.get("eligibility_state","unknown")).to_upper()
	var tier:=str(snapshot_value.get("qualified_tier",snapshot_value.get("tier",""))).to_upper()
	var next_threshold:=float(snapshot_value.get("next_threshold",0.0))
	var detail:="Qualifikation wird ausschließlich vom Server bestätigt."
	if not tier.is_empty():detail="Qualifizierte Stufe · %s. "%tier+detail
	if next_threshold>0.0:detail+=" · Nächste Schwelle %.0f"%next_threshold
	return {"title":"QUALIFIKATION","state":state,"detail":detail,"tone":"ready" if state in ["ELIGIBLE","QUALIFIED","SETTLED"] else "info"}

static func reward_card(snapshot_value:Dictionary)->Dictionary:
	var publication:=str(snapshot_value.get("reward_publication_state","unpublished")).to_upper()
	var summary:=str(snapshot_value.get("reward_summary",""))
	var claim_state:=str(snapshot_value.get("reward_claim_state","not_claimable")).to_upper()
	var detail:=summary if not summary.is_empty() else "Abschlussbelohnung noch nicht serverseitig veröffentlicht."
	detail+=" · Claim %s"%claim_state
	return {"title":"ABSCHLUSSBELONUNG","state":publication,"detail":detail,"tone":"ready" if publication in ["PUBLISHED","SETTLED"] else "locked"}

static func contribution_rows(snapshot_value:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var breakdown:Dictionary=snapshot_value.get("contribution_breakdown",{}) if snapshot_value.get("contribution_breakdown",{}) is Dictionary else {}
	var labels:={"damage":"Schaden","sinks":"Versenkt","objectives":"Ziele","support":"Support","exploration":"Exploration"}
	for id in ["damage","sinks","objectives","support","exploration"]:
		if breakdown.has(id):out.append({"id":id,"label":labels[id],"value":float(breakdown.get(id,0.0))})
	return out

static func threshold_progress(snapshot_value:Dictionary)->Dictionary:
	var current:=float(snapshot_value.get("personal_contribution",0.0))
	var next_threshold:=float(snapshot_value.get("next_threshold",0.0))
	if next_threshold<=0.0:return {"available":false,"ratio":0.0,"label":"Keine nächste Schwelle im Server-Snapshot"}
	return {"available":true,"ratio":clampf(current/maxf(1.0,next_threshold),0.0,1.0),"label":"%.0f / %.0f bis nächste Schwelle"%[current,next_threshold]}

static func leaderboard_rows(snapshot_value:Dictionary,group_board:=false)->Array[Dictionary]:
	var key:="group_leaderboard_rows" if group_board else "leaderboard_rows"
	var source:Array=snapshot_value.get(key,[]) if snapshot_value.get(key,[]) is Array else []
	var out:Array[Dictionary]=[]
	for raw in source.slice(0,10):
		if not raw is Dictionary:continue
		var row:Dictionary=raw
		out.append({"rank":maxi(0,int(row.get("rank",0))),"name":str(row.get("name","Unbekannt")),"contribution":maxf(0.0,float(row.get("contribution",0.0))),"is_self":bool(row.get("is_self",false))})
	return out

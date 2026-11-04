class_name M238SeasonProgressionCatalog
extends RefCounted

## M238 read-only season view model.
## Season timing, progression, division, placements and settlement come from server authority only.

static func runtime(tree:SceneTree)->EventRuntime:
	return M237EventHistoryCatalog.runtime(tree)

static func snapshot(runtime_value:EventRuntime)->Dictionary:
	if runtime_value==null:return {"source":"none","revision":0,"season_id":"","state":"inactive","event_results":[],"receipts":[]}
	var replica:=runtime_value.season_snapshot()
	if replica.is_empty():return {"source":"none","revision":0,"season_id":"","state":"inactive","event_results":[],"receipts":[]}
	return {
		"source":"authoritative_snapshot",
		"revision":maxi(0,int(replica.get("revision",0))),
		"season_id":str(replica.get("season_id","")),
		"title":str(replica.get("title","Season")),
		"state":str(replica.get("state","scheduled")).to_lower(),
		"starts_at":str(replica.get("starts_at","")),
		"ends_at":str(replica.get("ends_at","")),
		"remaining_seconds":maxi(0,int(replica.get("remaining_seconds",0))),
		"season_score":maxf(0.0,float(replica.get("season_score",0.0))),
		"division":str(replica.get("division","")),
		"division_rank":maxi(0,int(replica.get("division_rank",0))),
		"global_rank":maxi(0,int(replica.get("global_rank",0))),
		"next_division":str(replica.get("next_division","")),
		"next_threshold":maxf(0.0,float(replica.get("next_threshold",0.0))),
		"qualified_state":str(replica.get("qualified_state","unknown")).to_lower(),
		"event_results":replica.get("event_results",[]) if replica.get("event_results",[]) is Array else [],
		"reward_publication_state":str(replica.get("reward_publication_state","unpublished")).to_lower(),
		"reward_summary":str(replica.get("reward_summary","")),
		"settlement_id":str(replica.get("settlement_id","")),
		"receipt_id":str(replica.get("receipt_id",""))
	}

static func authority_label(snapshot_value:Dictionary)->String:
	return "SERVER-SEASON · READ ONLY" if str(snapshot_value.get("source",""))=="authoritative_snapshot" else "NOCH KEINE SERVER-SEASON"

static func season_card(snapshot_value:Dictionary)->Dictionary:
	if str(snapshot_value.get("source",""))!="authoritative_snapshot":
		return {"title":"SEASON","state":"KEINE SERVERDATEN","detail":"Season-Zeitraum, Fortschritt und Rang werden nicht lokal erfunden.","tone":"locked"}
	var state:=str(snapshot_value.get("state","scheduled")).to_upper()
	var detail:=str(snapshot_value.get("starts_at",""))+" → "+str(snapshot_value.get("ends_at",""))
	return {"title":str(snapshot_value.get("title","Season")),"state":state,"detail":detail.strip_edges(),"tone":"active" if state in ["LIVE","ACTIVE"] else "info"}

static func progression_card(snapshot_value:Dictionary)->Dictionary:
	var score:=float(snapshot_value.get("season_score",0.0))
	var division:=str(snapshot_value.get("division",""))
	var rank:=int(snapshot_value.get("division_rank",0))
	var state:="%.0f PUNKTE"%score
	if not division.is_empty():state+=" · "+division.to_upper()
	if rank>0:state+=" · #%d"%rank
	var next:=str(snapshot_value.get("next_division",""))
	var threshold:=float(snapshot_value.get("next_threshold",0.0))
	var detail:="Fortschritt wird ausschließlich vom Server bestätigt."
	if not next.is_empty():detail+=" · Nächste Division "+next
	if threshold>0.0:detail+=" bei %.0f"%threshold
	return {"title":"SEASON-FORTSCHRITT","state":state,"detail":detail,"tone":"ready" if not division.is_empty() else "info","progress":clampf(score/maxf(1.0,threshold),0.0,1.0) if threshold>0.0 else 0.0}

static func ranking_card(snapshot_value:Dictionary)->Dictionary:
	var division_rank:=int(snapshot_value.get("division_rank",0))
	var global_rank:=int(snapshot_value.get("global_rank",0))
	var state:="NOCH NICHT PLATZIERT"
	if division_rank>0:state="DIVISION #%d"%division_rank
	if global_rank>0:state+=" · GLOBAL #%d"%global_rank
	return {"title":"SEASON-RANG","state":state,"detail":"Division und Rang sind read-only Serverdaten.","tone":"ready" if division_rank>0 or global_rank>0 else "locked"}

static func event_result_rows(snapshot_value:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var source:Array=snapshot_value.get("event_results",[]) if snapshot_value.get("event_results",[]) is Array else []
	for raw in source.slice(0,12):
		if not raw is Dictionary:continue
		var row:Dictionary=raw
		var event_id:=str(row.get("event_id",""))
		if event_id.is_empty():continue
		out.append({"event_id":event_id,"title":str(row.get("title",event_id)),"personal_rank":maxi(0,int(row.get("personal_rank",0))),"contribution":maxf(0.0,float(row.get("contribution",0.0))),"season_points":maxf(0.0,float(row.get("season_points",0.0))),"qualified_tier":str(row.get("qualified_tier",""))})
	return out

static func event_result_card(row:Dictionary)->Dictionary:
	var state:="+%.0f SEASON"%float(row.get("season_points",0.0))
	var rank:=int(row.get("personal_rank",0))
	if rank>0:state+=" · #%d"%rank
	var detail:="Beitrag %.0f"%float(row.get("contribution",0.0))
	var tier:=str(row.get("qualified_tier",""))
	if not tier.is_empty():detail+=" · "+tier.to_upper()
	return {"title":str(row.get("title","Event")),"state":state,"detail":detail,"tone":"ready"}

static func reward_card(snapshot_value:Dictionary)->Dictionary:
	var publication:=str(snapshot_value.get("reward_publication_state","unpublished")).to_upper()
	var summary:=str(snapshot_value.get("reward_summary",""))
	if summary.is_empty():summary="Season-Abschlussbelohnung noch nicht serverseitig veröffentlicht."
	var settlement:=str(snapshot_value.get("settlement_id",""))
	var receipt:=str(snapshot_value.get("receipt_id",""))
	if not settlement.is_empty():summary+=" · Settlement "+settlement
	if not receipt.is_empty():summary+=" · Receipt "+receipt
	return {"title":"SEASON-ABSCHLUSS","state":publication,"detail":summary,"tone":"ready" if publication in ["PUBLISHED","SETTLED","DELIVERED"] else "locked"}

class_name M237EventHistoryCatalog
extends RefCounted

## M237 read-only event history / settlement view model.
## Completed events, placements, qualified tiers and reward receipts come from server authority only.

static func runtime(tree:SceneTree)->EventRuntime:
	return M236EventRankingViewCatalog.runtime(tree)

static func snapshot(runtime_value:EventRuntime)->Dictionary:
	if runtime_value==null:return {"source":"none","revision":0,"events":[],"receipts":[]}
	var replica:=runtime_value.event_history_snapshot()
	if replica.is_empty():
		return {"source":"none","revision":0,"events":[],"receipts":[],"season_id":"","season_label":""}
	return {
		"source":"authoritative_snapshot",
		"revision":maxi(0,int(replica.get("revision",0))),
		"season_id":str(replica.get("season_id","")),
		"season_label":str(replica.get("season_label","")),
		"events":replica.get("events",[]) if replica.get("events",[]) is Array else [],
		"receipts":replica.get("receipts",[]) if replica.get("receipts",[]) is Array else []
	}

static func authority_label(snapshot_value:Dictionary)->String:
	return "SERVER-HISTORIE · READ ONLY" if str(snapshot_value.get("source",""))=="authoritative_snapshot" else "NOCH KEINE SERVER-HISTORIE"

static func history_rows(snapshot_value:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var source:Array=snapshot_value.get("events",[]) if snapshot_value.get("events",[]) is Array else []
	for raw in source.slice(0,30):
		if not raw is Dictionary:continue
		var row:Dictionary=raw
		var state:=str(row.get("state","completed")).to_lower()
		if state not in ["completed","settled","cancelled"]:continue
		out.append({
			"event_id":str(row.get("event_id","")),
			"title":str(row.get("title","Vergangenes Event")),
			"season_label":str(row.get("season_label",snapshot_value.get("season_label",""))),
			"completed_at":str(row.get("completed_at","")),
			"personal_rank":maxi(0,int(row.get("personal_rank",0))),
			"group_rank":maxi(0,int(row.get("group_rank",0))),
			"personal_contribution":maxf(0.0,float(row.get("personal_contribution",0.0))),
			"qualified_tier":str(row.get("qualified_tier","")),
			"reward_state":str(row.get("reward_state","unpublished")).to_lower(),
			"settlement_id":str(row.get("settlement_id","")),
			"state":state
		})
	return out

static func receipt_rows(snapshot_value:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var source:Array=snapshot_value.get("receipts",[]) if snapshot_value.get("receipts",[]) is Array else []
	for raw in source.slice(0,30):
		if not raw is Dictionary:continue
		var row:Dictionary=raw
		var receipt_id:=str(row.get("receipt_id",""))
		if receipt_id.is_empty():continue
		out.append({
			"receipt_id":receipt_id,
			"event_id":str(row.get("event_id","")),
			"settlement_id":str(row.get("settlement_id","")),
			"status":str(row.get("status","confirmed")).to_lower(),
			"reward_summary":str(row.get("reward_summary","")),
			"issued_at":str(row.get("issued_at","")),
			"server_signature_present":bool(row.get("server_signature_present",false))
		})
	return out

static func history_card(row:Dictionary)->Dictionary:
	var rank:=int(row.get("personal_rank",0))
	var tier:=str(row.get("qualified_tier",""))
	var state:="ABGESCHLOSSEN"
	if rank>0:state+=" · #%d"%rank
	if not tier.is_empty():state+=" · %s"%tier.to_upper()
	var detail:="Beitrag %.0f"%float(row.get("personal_contribution",0.0))
	var group_rank:=int(row.get("group_rank",0))
	if group_rank>0:detail+=" · Gruppenrang #%d"%group_rank
	var completed:=str(row.get("completed_at",""))
	if not completed.is_empty():detail+=" · "+completed
	return {"title":str(row.get("title","Vergangenes Event")),"state":state,"detail":detail,"tone":"ready"}

static func receipt_card(row:Dictionary)->Dictionary:
	var status:=str(row.get("status","confirmed")).to_upper()
	var summary:=str(row.get("reward_summary",""))
	if summary.is_empty():summary="Serverbestätigter Reward-Receipt"
	var detail:=summary+" · Receipt "+str(row.get("receipt_id",""))
	if bool(row.get("server_signature_present",false)):detail+=" · SIGNIERT"
	return {"title":"REWARD-RECEIPT","state":status,"detail":detail,"tone":"ready" if status in ["CONFIRMED","SETTLED","DELIVERED"] else "info"}

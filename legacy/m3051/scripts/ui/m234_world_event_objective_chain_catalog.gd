class_name M234WorldEventObjectiveChainCatalog
extends RefCounted

## M234 read-only event objective-chain bridge.
## It never advances phases, grants rewards, spawns actors or resolves completion.
## Connected/live operation may replicate objective/completion/reward publication state from server/admin authority.
const FEEDBACK_SECONDS := 3.6
const COMPLETION_STATES := ["active", "finale", "completed", "settled"]

static func runtime(tree:SceneTree)->EventRuntime:
	return M233WorldEventLifecycleCatalog.runtime(tree)

static func phase_rows(runtime_value:EventRuntime)->Array:
	if runtime_value==null or not runtime_value.is_active():return []
	return runtime_value.active().get("phases",[])

static func objective_snapshot(runtime_value:EventRuntime)->Dictionary:
	if runtime_value==null:return {"source":"none","state":"inactive","phase":0}
	var replica:=runtime_value.objective_publication_snapshot()
	if not replica.is_empty():
		return {
			"source":"authoritative_snapshot",
			"event_id":str(replica.get("event_id",runtime_value.active_event_id)),
			"state":str(replica.get("state","active")).to_lower(),
			"phase":int(replica.get("phase",runtime_value.phase)),
			"objective_id":str(replica.get("objective_id","")),
			"objective_label":str(replica.get("objective_label","")),
			"progress":float(replica.get("progress",0.0)),
			"target":float(replica.get("target",0.0)),
			"finale_ready":bool(replica.get("finale_ready",false)),
			"event_complete":bool(replica.get("event_complete",false)),
			"reward_publication_state":str(replica.get("reward_publication_state","unpublished")),
			"reward_summary":str(replica.get("reward_summary",""))
		}
	if not runtime_value.is_active():return {"source":"runtime","state":"inactive","phase":0}
	var rows:=phase_rows(runtime_value)
	var current:=clampi(runtime_value.phase,1,maxi(1,rows.size()))
	var row:Dictionary=runtime_value.phase_row()
	return {
		"source":"runtime","event_id":runtime_value.active_event_id,
		"state":"finale" if current>=rows.size() and rows.size()>0 else "active",
		"phase":current,"objective_id":"phase_%d"%current,
		"objective_label":str(row.get("label",runtime_value.phase_label())),
		"progress":runtime_value.meter_ratio()*100.0,"target":100.0,
		"finale_ready":current>=rows.size() and rows.size()>0,
		"event_complete":false,"reward_publication_state":"preview_only","reward_summary":""
	}

static func chain(runtime_value:EventRuntime)->Array:
	var result:Array=[]
	if runtime_value==null or not runtime_value.is_active():return result
	var snapshot:=objective_snapshot(runtime_value)
	var current:=int(snapshot.get("phase",runtime_value.phase))
	var rows:=phase_rows(runtime_value)
	for index in rows.size():
		var row:Dictionary=rows[index]
		var id:=int(row.get("id",index+1))
		var state:="complete" if id<current else ("current" if id==current else "locked")
		if bool(snapshot.get("event_complete",false)):state="complete"
		result.append({"id":id,"label":str(row.get("label","Phase %d"%id)),"state":state,"finale":index==rows.size()-1})
	return result

static func active_objective_label(runtime_value:EventRuntime)->String:
	var snapshot:=objective_snapshot(runtime_value)
	if bool(snapshot.get("event_complete",false)):return "EVENT ABGESCHLOSSEN"
	var label:=str(snapshot.get("objective_label",""))
	if label.is_empty() and runtime_value!=null:label=runtime_value.phase_label()
	return label.to_upper()

static func progress_label(runtime_value:EventRuntime)->String:
	var snapshot:=objective_snapshot(runtime_value)
	if bool(snapshot.get("event_complete",false)):
		var reward_state:=str(snapshot.get("reward_publication_state","unpublished"))
		return "BELOHNUNGEN · %s"%reward_state.replace("_"," ").to_upper()
	var progress:=float(snapshot.get("progress",0.0)); var target:=float(snapshot.get("target",0.0))
	if target<=0.0:return ""
	return "FORTSCHRITT · %.0f/%.0f"%[progress,target]

static func transition_label(previous:Dictionary,current:Dictionary,event_title:String)->String:
	if current.is_empty():return ""
	if not bool(previous.get("finale_ready",false)) and bool(current.get("finale_ready",false)):
		return "BOSS-FINALE FREIGESCHALTET · %s"%event_title.to_upper()
	if not bool(previous.get("event_complete",false)) and bool(current.get("event_complete",false)):
		return "EVENT ABGESCHLOSSEN · %s"%event_title.to_upper()
	var prev_phase:=int(previous.get("phase",0)); var next_phase:=int(current.get("phase",0))
	if prev_phase>0 and next_phase>prev_phase:
		return "EVENTZIEL ERREICHT · PHASE %d"%next_phase
	return ""

static func stamp_world_objectives(tree:SceneTree,runtime_value:EventRuntime)->void:
	if tree==null or runtime_value==null:return
	var snapshot:=objective_snapshot(runtime_value)
	for row in M233WorldEventLifecycleCatalog.objective_nodes(tree,runtime_value):
		var n:=row.get("node") as Node3D
		if n==null:continue
		n.set_meta("m234_event_objective_chain",true)
		n.set_meta("m234_event_phase",int(snapshot.get("phase",runtime_value.phase)))
		n.set_meta("m234_event_finale",bool(snapshot.get("finale_ready",false)))
		n.set_meta("m234_event_complete",bool(snapshot.get("event_complete",false)))
		n.set_meta("marker_priority",maxi(int(n.get_meta("marker_priority",0)),int(row.get("priority",82))))

static func chart_status(node:Node3D,runtime_value:EventRuntime)->String:
	if node==null or runtime_value==null or str(node.get_meta("event_id",""))!=runtime_value.active_event_id:return ""
	var snapshot:=objective_snapshot(runtime_value)
	if bool(snapshot.get("event_complete",false)):return "EVENT ABGESCHLOSSEN"
	var rank:=M232WorldEventAwarenessCatalog.node_rank(node)
	if bool(snapshot.get("finale_ready",false)) and rank in ["boss","admiral"]:return "FINALE · %s"%runtime_value.phase_label().to_upper()
	return M233WorldEventLifecycleCatalog.marker_status(node,runtime_value)

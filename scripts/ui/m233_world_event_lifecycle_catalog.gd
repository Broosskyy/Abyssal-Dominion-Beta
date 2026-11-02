class_name M233WorldEventLifecycleCatalog
extends RefCounted

## Read-only presentation bridge for event lifecycle continuity.
## Authoritative schedule/timestamps may be replicated into EventRuntime; this catalog never starts,
## ends, advances, rewards, spawns or resolves an event. No local wall-clock scheduling fallback.
const FEEDBACK_SECONDS := 3.4
const WARNING_SECONDS := 4.0
const STATES := ["inactive","scheduled","warning","live","finale","ended"]

static func runtime(tree:SceneTree)->EventRuntime:
	return M232WorldEventAwarenessCatalog.event_runtime(tree)

static func lifecycle(runtime_value:EventRuntime)->Dictionary:
	if runtime_value==null:return {"state":"inactive","source":"none"}
	var replica:=runtime_value.lifecycle_snapshot()
	if not replica.is_empty():
		var state:=str(replica.get("state","inactive")).to_lower()
		if state not in STATES:state="inactive"
		return {
			"state":state,"source":"authoritative_snapshot",
			"event_id":str(replica.get("event_id",runtime_value.active_event_id)),
			"starts_at":str(replica.get("starts_at","")),"ends_at":str(replica.get("ends_at","")),
			"seconds_to_start":float(replica.get("seconds_to_start",-1.0)),
			"seconds_to_end":float(replica.get("seconds_to_end",-1.0))
		}
	if not runtime_value.is_active():return {"state":"inactive","source":"runtime"}
	var phases:Array=runtime_value.active().get("phases",[])
	var last_phase:=maxi(1,phases.size())
	return {"state":"finale" if runtime_value.phase>=last_phase else "live","source":"runtime","event_id":runtime_value.active_event_id,"seconds_to_start":-1.0,"seconds_to_end":-1.0}

static func state_label(state:String)->String:
	match state:
		"scheduled":return "EVENT ANGEKÜNDIGT"
		"warning":return "EVENT STARTET BALD"
		"live":return "WORLD-EVENT AKTIV"
		"finale":return "EVENT-FINALE"
		"ended":return "WORLD-EVENT BEENDET"
		_:return ""

static func transition_label(previous:String,current:String,event_title:String)->String:
	var title:=event_title.to_upper()
	if previous in ["inactive","scheduled","warning"] and current in ["live","finale"]:return "WORLD-EVENT GESTARTET · %s"%title
	if previous in ["live","finale"] and current in ["inactive","ended"]:return "WORLD-EVENT BEENDET · %s"%title
	if current=="warning":return "EVENT STARTET BALD · %s"%title
	if current=="finale" and previous!="finale":return "FINALE ERREICHT · %s"%title
	return ""

static func timing_hint(snapshot:Dictionary)->String:
	var state:=str(snapshot.get("state",""))
	var seconds:=float(snapshot.get("seconds_to_start",-1.0)) if state in ["scheduled","warning"] else float(snapshot.get("seconds_to_end",-1.0))
	if seconds<0.0:return "SERVER-ZEIT · SYNCHRONISIERT" if str(snapshot.get("source",""))=="authoritative_snapshot" else ""
	var minutes:=ceili(seconds/60.0)
	return ("START IN %d MIN" if state in ["scheduled","warning"] else "ENDE IN %d MIN")%minutes

static func objective_nodes(tree:SceneTree,runtime_value:EventRuntime)->Array:
	if tree==null or runtime_value==null or not runtime_value.is_active():return []
	var event_id:=runtime_value.active_event_id
	var phase_row:=runtime_value.phase_row()
	var allowed:Array=[]
	for id in phase_row.get("world_slots",[]):allowed.append(str(id))
	for id in phase_row.get("fleet",[]):allowed.append(str(id))
	var rows:Array=[]
	for node in M232WorldEventAwarenessCatalog.event_nodes(tree,event_id):
		var n:=node as Node3D
		if n==null:continue
		var slot:=str(n.get_meta("production_slot",n.name))
		var rank:=M232WorldEventAwarenessCatalog.node_rank(n)
		var active_for_phase:=allowed.is_empty() or slot in allowed or rank in ["boss","admiral"]
		if not active_for_phase:continue
		var priority:=96 if rank=="boss" else (92 if rank=="admiral" else 82)
		rows.append({"node":n,"kind":"event","priority":priority,"rank":rank,"slot":slot})
	rows.sort_custom(func(a,b):return int(a.get("priority",0))>int(b.get("priority",0)))
	return rows

static func stamp_objectives(tree:SceneTree,runtime_value:EventRuntime,state:String)->void:
	# Presentation metadata only, used by existing world-marker/full-chart renderers.
	for row in objective_nodes(tree,runtime_value):
		var n:=row.get("node") as Node3D
		if n==null:continue
		n.set_meta("m233_event_objective",true)
		n.set_meta("m233_event_lifecycle",state)
		n.set_meta("marker_priority",maxi(int(n.get_meta("marker_priority",0)),int(row.get("priority",82))))

static func marker_status(node:Node3D,runtime_value:EventRuntime)->String:
	if node==null or runtime_value==null:return ""
	if str(node.get_meta("event_id",""))!=runtime_value.active_event_id:return ""
	var rank:=M232WorldEventAwarenessCatalog.node_rank(node)
	var base:="EVENT-ZIEL"
	if rank=="boss":base="EVENT-BOSS"
	elif rank=="admiral":base="EVENT-ADMIRAL"
	return "%s · %s"%[base,runtime_value.phase_label().to_upper()]

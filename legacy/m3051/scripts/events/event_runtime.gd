class_name EventRuntime
extends Node
## M94 seasonal event runtime. Local prototype/test state only; never live authority.

signal event_changed
const DATA_PATH := "res://data/event_framework.json"
var data: Dictionary = {}
var active_event_id := ""
var currency := 40
var score := 24
var phase := 1
var claimed: Array[String] = []
var quest_progress: Dictionary = {}
var quest_claimed: Array[String] = []
var reward_track_claimed: Array[String] = []
# M233: optional server-replicated lifecycle snapshot. Client never schedules or advances events from local wall clock.
var authoritative_lifecycle_snapshot: Dictionary = {}
# M234: optional server/admin-published objective/completion/reward presentation snapshot.
var authoritative_objective_publication_snapshot: Dictionary = {}
# M235: optional server-replicated contribution/rank/eligibility snapshot; never authoritative on client.
var authoritative_contribution_replica_snapshot: Dictionary = {}
# M237: optional server-replicated event history/settlement receipt snapshot.
# The client may display it, but may never manufacture completed events, placements or receipts.
var authoritative_event_history_snapshot: Dictionary = {}
# M238: optional server-replicated season identity/progression/settlement snapshot.
# The client may render season state but never determines division, placement, qualification or rewards.
var authoritative_season_snapshot: Dictionary = {}

func _ready() -> void:
	add_to_group("event_runtime")
	data = _read_json()
	active_event_id = str(data.get("active_event", "")) if _local_preview_allowed() else ""
	var current:=active()
	phase=int(current.get("phase",1)) if not current.is_empty() else 1

func _read_json() -> Dictionary:
	if not FileAccess.file_exists(DATA_PATH): return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return parsed if parsed is Dictionary else {}

func _local_preview_allowed()->bool:
	var tree:=get_tree()
	return tree!=null and EnvironmentContract.current_id(tree)=="LOCAL_DEVELOPMENT" and not bool(tree.root.get_meta("server_authority_verified",false))

func ingest_authoritative_lifecycle_snapshot(snapshot:Dictionary)->void:
	# Client-replica intake only. The server/admin authority decides timestamps and lifecycle state.
	authoritative_lifecycle_snapshot=snapshot.duplicate(true)
	event_changed.emit()

func clear_authoritative_lifecycle_snapshot()->void:
	authoritative_lifecycle_snapshot={}
	event_changed.emit()

func lifecycle_snapshot()->Dictionary:
	return authoritative_lifecycle_snapshot.duplicate(true)


func ingest_authoritative_objective_publication_snapshot(snapshot:Dictionary)->void:
	# Client-replica intake only. Server/admin authority owns phase, completion and reward publication.
	authoritative_objective_publication_snapshot=snapshot.duplicate(true)
	event_changed.emit()

func clear_authoritative_objective_publication_snapshot()->void:
	authoritative_objective_publication_snapshot={}
	event_changed.emit()

func objective_publication_snapshot()->Dictionary:
	return authoritative_objective_publication_snapshot.duplicate(true)

func ingest_authoritative_contribution_replica_snapshot(snapshot:Dictionary)->void:
	# Client replica only. Server validates contribution, ranks, eligibility and reward settlement.
	var incoming_revision:=int(snapshot.get("revision",0))
	var current_revision:=int(authoritative_contribution_replica_snapshot.get("revision",-1))
	if incoming_revision<current_revision:return
	authoritative_contribution_replica_snapshot=snapshot.duplicate(true)
	event_changed.emit()

func clear_authoritative_contribution_replica_snapshot()->void:
	authoritative_contribution_replica_snapshot={}
	event_changed.emit()

func contribution_replica_snapshot()->Dictionary:
	return authoritative_contribution_replica_snapshot.duplicate(true)

func active() -> Dictionary:
	return data.get("events", {}).get(active_event_id, {}) if _local_preview_allowed() and not active_event_id.is_empty() else {}

func is_active() -> bool:
	return _local_preview_allowed() and not active().is_empty()

func title() -> String:return str(active().get("title", "Kein Event"))
func subtitle()->String:return str(active().get("subtitle",""))
func currency_label() -> String:return str(active().get("currency", {}).get("label", "Eventwährung"))
func currency_icon()->String:return str(active().get("currency",{}).get("icon","m94_halloween_currency"))

func meter_ratio() -> float:
	var target := maxi(1, int(active().get("world_meter", {}).get("target", 100)))
	return clampf(float(score) / float(target), 0.0, 1.0)

func milestone_rows() -> Array:return active().get("milestones", [])
func quest_rows()->Array:return active().get("quests",[])

func phase_row()->Dictionary:
	for row in active().get("phases",[]):
		if int(row.get("id",0))==phase:return row
	return {}

func phase_label()->String:return str(phase_row().get("label","Phase %d"%phase))

func set_phase(value:int)->void:
	if not _local_preview_allowed():return
	phase=clampi(value,1,maxi(1,active().get("phases",[]).size()))
	event_changed.emit()

func cycle_phase()->void:
	var count:=maxi(1,active().get("phases",[]).size())
	set_phase(1+posmod(phase,count))

func set_active_event(id:String)->bool:
	if not _local_preview_allowed():return false
	if id.is_empty():
		active_event_id=""
		event_changed.emit()
		return true
	if not data.get("events",{}).has(id):return false
	active_event_id=id
	phase=int(active().get("phase",1))
	event_changed.emit()
	return true

func admin_toggle_halloween()->bool:
	return set_active_event("" if active_event_id=="halloween_abyss_01" else "halloween_abyss_01")

func admin_add_score(amount:int)->void:
	if not _local_preview_allowed():return
	score=clampi(score+amount,0,999999)
	event_changed.emit()

func admin_add_currency(amount:int)->void:
	if not _local_preview_allowed():return
	currency=clampi(currency+amount,0,999999)
	event_changed.emit()

func record(kind:String,amount:int=1)->void:
	if not is_active():return
	for q in quest_rows():
		if str(q.get("kind",""))!=kind:continue
		var id:=str(q.get("id",""))
		if id.is_empty() or id in quest_claimed:continue
		var target:=maxi(1,int(q.get("target",1)))
		quest_progress[id]=clampi(int(quest_progress.get(id,0))+amount,0,target)
		if int(quest_progress[id])>=target:
			quest_claimed.append(id)
			currency+=int(q.get("reward_currency",0))
			score+=maxi(1,int(q.get("reward_currency",0))/2)
	event_changed.emit()

func relevant_quests(limit:int=2)->Array:
	var rows:Array=[]
	for q in quest_rows():
		var id:=str(q.get("id",""))
		if id in quest_claimed:continue
		rows.append(q)
		if rows.size()>=limit:break
	if rows.is_empty():
		for q in quest_rows().slice(0,mini(limit,quest_rows().size())):rows.append(q)
	return rows

func quest_complete(id:String)->bool:
	return id in quest_claimed

func quest_progress_text(id:String)->String:
	for q in quest_rows():
		if str(q.get("id",""))==id:
			return "%d/%d"%[int(quest_progress.get(id,0)),int(q.get("target",1))]
	return "0/0"

func record_event_sink(ship:Node3D)->void:
	if ship!=null and bool(ship.get_meta("event_participant",false)):record("event_sink",1)

func record_event_monster_hit(target:Node3D)->void:
	if target!=null and bool(target.get_meta("event_participant",false)) and str(target.get_meta("encounter_kind",""))=="monster":
		record("event_monster_hit",1)

func record_event_explore(id:String)->void:
	if id=="event_halloween_wreck_01":record("event_explore",1)

func claim_preview(id: String) -> bool:
	if not _local_preview_allowed():return false
	if id in claimed:return false
	for row in milestone_rows():
		if str(row.get("id",""))==id and score>=int(row.get("score",0)):
			claimed.append(id)
			return true
	return false

func shop_preview(item_id:String)->bool:
	if not _local_preview_allowed():return false
	for row in active().get("shop",[]):
		if str(row.get("id",""))==item_id:
			var cost:=int(row.get("cost",0))
			if currency<cost:return false
			currency-=cost
			event_changed.emit()
			return true
	return false

func combat_hook_ids(kind:String)->Array[String]:
	var result:Array[String]=[]
	for row in active().get("combat_hooks",{}).get(kind,[]):result.append(str(row.get("id","")))
	return result
func reward_track_rows()->Array:
	var path:="res://data/m155_halloween_reward_track.json"
	if not FileAccess.file_exists(path):return []
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:return []
	if str((parsed as Dictionary).get("event_id",""))!=active_event_id:return []
	return (parsed as Dictionary).get("track",[])

func reward_track_preview_claim(score_target:int)->bool:
	if not _local_preview_allowed():return false
	if not is_active() or score<score_target:return false
	var key:=str(score_target)
	if key in reward_track_claimed:return false
	for row in reward_track_rows():
		if int(row.get("score",-1))==score_target:
			reward_track_claimed.append(key)
			event_changed.emit()
			return true
	return false

func reward_track_preview_status(score_target:int)->String:
	if str(score_target) in reward_track_claimed:return "PREVIEW MARKIERT"
	return "BEREIT" if score>=score_target else "%d/%d"%[score,score_target]


func ingest_authoritative_event_history_snapshot(snapshot:Dictionary)->void:
	# Monotonic replica intake. Server owns completion, placement, qualified tier and reward receipts.
	var incoming_revision:=int(snapshot.get("revision",0))
	var current_revision:=int(authoritative_event_history_snapshot.get("revision",-1))
	if incoming_revision<current_revision:return
	authoritative_event_history_snapshot=snapshot.duplicate(true)
	event_changed.emit()

func clear_authoritative_event_history_snapshot()->void:
	authoritative_event_history_snapshot={}
	event_changed.emit()

func event_history_snapshot()->Dictionary:
	return authoritative_event_history_snapshot.duplicate(true)


func ingest_authoritative_season_snapshot(snapshot:Dictionary)->void:
	# Monotonic client-replica intake. Server owns season timing, score, division, placement and settlement.
	var incoming_revision:=int(snapshot.get("revision",0))
	var current_revision:=int(authoritative_season_snapshot.get("revision",-1))
	if incoming_revision<current_revision:return
	authoritative_season_snapshot=snapshot.duplicate(true)
	event_changed.emit()

func clear_authoritative_season_snapshot()->void:
	authoritative_season_snapshot={}
	event_changed.emit()

func season_snapshot()->Dictionary:
	return authoritative_season_snapshot.duplicate(true)

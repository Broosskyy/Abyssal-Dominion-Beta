class_name MissionSystem
extends Node

signal mission_changed
signal mission_completed(result: Dictionary)

const MISSIONS := [
	{"id": "sink_hostiles", "title": "Corsair Hunt", "kind": "sink", "target": 3, "coins": 180, "xp": 90},
	{"id": "collect_salvage", "title": "Sea Salvage", "kind": "loot", "target": 4, "coins": 220, "xp": 110},
	{"id": "harbor_route", "title": "Harbor Route", "kind": "dock", "target": 2, "coins": 160, "xp": 80},
]

var mission_index := 0
var progress := 0
var completed_count := 0
var day_index := -1
var week_index := -1
var _calendar_elapsed := 0.0
var last_completed: Dictionary = {}

const DAILY_GOALS := {"sink": 5, "loot": 6, "dock": 3}
const WEEKLY_GOALS := {"sink": 24, "loot": 20, "dock": 10}
var daily_progress := {"sink": 0, "loot": 0, "dock": 0}
var weekly_progress := {"sink": 0, "loot": 0, "dock": 0}
var event_points := 0
var daily_claimed := false
var weekly_claimed := false

const EVENT_MILESTONES := [100, 250, 500]
const EVENT_REWARDS := [
	{"coins": 250, "xp": 100, "label": "Corsair Cache"},
	{"coins": 650, "xp": 260, "label": "Admiral Cache"},
	{"coins": 1400, "xp": 550, "label": "Legendary Fleet Cache"},
]
var event_claimed := [false, false, false]
const CHAIN_STAGES := [
	{"title": "First Blood", "goal": 60, "text": "Sink corsairs and prove your broadside."},
	{"title": "Reaver Trail", "goal": 180, "text": "Hunt elite raiders across the sector."},
	{"title": "Admiral's Wake", "goal": 360, "text": "Break the fleet and force out its admiral."},
	{"title": "Sea Legend", "goal": 500, "text": "Complete the legendary fleet campaign."},
]
var chain_stage := 0

@onready var progression: PlayerProgression = get_parent().get_node("Progression") as PlayerProgression


func _missions()->Array:
	var rows:=GameplayRuleset.array(get_tree(),"missions.rotation",MISSIONS)
	return rows if not rows.is_empty() else MISSIONS
func _daily_goals()->Dictionary:return GameplayRuleset.dictionary(get_tree(),"missions.daily_goals",DAILY_GOALS)
func _weekly_goals()->Dictionary:return GameplayRuleset.dictionary(get_tree(),"missions.weekly_goals",WEEKLY_GOALS)
func _event_milestones()->Array:return GameplayRuleset.array(get_tree(),"missions.event_milestones",EVENT_MILESTONES)
func _event_rewards()->Array:return GameplayRuleset.array(get_tree(),"missions.event_rewards",EVENT_REWARDS)
func _chain_stages()->Array:return GameplayRuleset.array(get_tree(),"missions.chain_stages",CHAIN_STAGES)
func current_mission() -> Dictionary:
	var rows:=_missions();return rows[posmod(mission_index,rows.size())]


func description() -> String:
	var mission := current_mission()
	return "%s  %d/%d" % [mission.title, progress, mission.target]

func presentation_slot() -> String:
	var kind:=str(current_mission().get("kind",""))
	return {"sink":"m70_tutorial_attack","loot":"m72_poi_salvage","dock":"m70_tutorial_harbor"}.get(kind,"m72_poi_objective_frame")

func presentation_hint() -> String:
	var kind:=str(current_mission().get("kind",""))
	return {"sink":"Feindliche Ziele versenken","loot":"Salvage einsammeln","dock":"Im Hafen anlegen"}.get(kind,"Auftragsziel verfolgen")


func record_sink() -> void:
	_record("sink")


func record_loot() -> void:
	_record("loot")


func record_dock() -> void:
	_record("dock")


func export_state() -> Dictionary:
	sync_calendar()
	return {
		"day_index": day_index, "week_index": week_index,
		"mission_index": mission_index, "progress": progress, "completed_count": completed_count,
		"daily_progress": daily_progress.duplicate(true), "weekly_progress": weekly_progress.duplicate(true),
		"event_points": event_points, "daily_claimed": daily_claimed, "weekly_claimed": weekly_claimed,
		"event_claimed": event_claimed.duplicate(), "chain_stage": chain_stage,
	}


func daily_ratio(kind: String) -> float:
	return float(daily_progress.get(kind, 0)) / float(maxi(1, int(_daily_goals().get(kind, 1))))


func weekly_ratio(kind: String) -> float:
	return float(weekly_progress.get(kind, 0)) / float(maxi(1, int(_weekly_goals().get(kind, 1))))


func daily_complete() -> bool:
	for kind in _daily_goals():
		if int(daily_progress.get(kind, 0)) < int(_daily_goals()[kind]):
			return false
	return true


func weekly_complete() -> bool:
	for kind in _weekly_goals():
		if int(weekly_progress.get(kind, 0)) < int(_weekly_goals()[kind]):
			return false
	return true




func _apply_reward_bundle(reward_id:String,reason:String,coins:int,xp:int)->Dictionary:
	var now:=TrustedTimeService.now(get_tree())
	coins=roundi(float(coins)*DynamicEventResolver.multiplier(get_tree(),"gold",now))
	xp=roundi(float(xp)*DynamicEventResolver.multiplier(get_tree(),"xp",now))
	var services:=ServiceLocator.from(get_tree())
	if services!=null and services.rewards!=null:
		return services.rewards.apply(RewardBundleService.bundle(reward_id,reason,coins,xp))
	progression.add_coins(coins)
	progression.add_xp(xp)
	return {"ok":true,"authority":"legacy_local_fallback"}

func claim_daily() -> Dictionary:
	sync_calendar()
	if daily_claimed or not daily_complete():
		return {}
	daily_claimed = true
	var reward:=GameplayRuleset.dictionary(get_tree(),"missions.daily_reward",{"coins":450,"xp":180})
	_apply_reward_bundle("daily:"+str(day_index),"daily_mission",int(reward.get("coins",450)),int(reward.get("xp",180)))
	mission_changed.emit()
	return reward.duplicate(true)


func claim_weekly() -> Dictionary:
	sync_calendar()
	if weekly_claimed or not weekly_complete():
		return {}
	weekly_claimed = true
	var reward:=GameplayRuleset.dictionary(get_tree(),"missions.weekly_reward",{"coins":1800,"xp":700})
	_apply_reward_bundle("weekly:"+str(week_index),"weekly_mission",int(reward.get("coins",1800)),int(reward.get("xp",700)))
	mission_changed.emit()
	return reward.duplicate(true)


func event_ratio(index: int) -> float:
	if index < 0 or index >= _event_milestones().size():
		return 0.0
	return clampf(float(event_points) / float(_event_milestones()[index]), 0.0, 1.0)


func event_claimable(index: int) -> bool:
	return index >= 0 and index < _event_milestones().size() and event_points >= _event_milestones()[index] and not bool(event_claimed[index])


func claim_event(index: int) -> Dictionary:
	if not event_claimable(index):
		return {}
	event_claimed[index] = true
	var reward: Dictionary = _event_rewards()[index]
	_apply_reward_bundle("event:"+str(index)+":"+str(day_index),"event_milestone",int(reward.coins),int(reward.xp))
	mission_changed.emit()
	return reward.duplicate(true)


func chain_title() -> String:
	return str(_chain_stages()[mini(chain_stage, _chain_stages().size() - 1)].title)


func chain_description() -> String:
	return str(_chain_stages()[mini(chain_stage, _chain_stages().size() - 1)].text)


func chain_goal() -> int:
	return int(_chain_stages()[mini(chain_stage, _chain_stages().size() - 1)].goal)


func chain_ratio() -> float:
	return clampf(float(event_points) / float(maxi(1, chain_goal())), 0.0, 1.0)


func import_state(data: Dictionary) -> void:
	day_index = VoyageProgress.safe_int(data.get("day_index", -1), -1, 10000000)
	week_index = VoyageProgress.safe_int(data.get("week_index", -1), -1, 10000000)
	last_completed.clear()
	mission_index = posmod(int(data.get("mission_index", 0)), _missions().size())
	progress = clamp(int(data.get("progress", 0)), 0, int(current_mission().target) - 1)
	completed_count = max(0, int(data.get("completed_count", 0)))
	for kind in _daily_goals():
		daily_progress[kind] = clamp(int((data.get("daily_progress", {}) as Dictionary).get(kind, 0)), 0, int(_daily_goals()[kind]))
	for kind in _weekly_goals():
		weekly_progress[kind] = clamp(int((data.get("weekly_progress", {}) as Dictionary).get(kind, 0)), 0, int(_weekly_goals()[kind]))
	event_points = max(0, int(data.get("event_points", 0)))
	daily_claimed = bool(data.get("daily_claimed", false))
	weekly_claimed = bool(data.get("weekly_claimed", false))
	var saved_event = data.get("event_claimed", [false, false, false])
	if saved_event is Array:
		for i in mini(saved_event.size(), event_claimed.size()): event_claimed[i] = bool(saved_event[i])
	chain_stage = clampi(int(data.get("chain_stage", 0)), 0, 3)
	sync_calendar()
	mission_changed.emit()


func _record(kind: String) -> void:
	sync_calendar()
	var dynamic_quests:=get_parent().get_node_or_null("DynamicQuestRuntime") as DynamicQuestRuntime
	if dynamic_quests!=null:dynamic_quests.record(kind,{"amount":1})
	var voyage := get_parent().get_node_or_null("Voyage") as VoyageProgress
	if voyage != null: voyage.record(kind)
	if daily_progress.has(kind):
		daily_progress[kind] = mini(int(_daily_goals()[kind]), int(daily_progress[kind]) + 1)
	if weekly_progress.has(kind):
		weekly_progress[kind] = mini(int(_weekly_goals()[kind]), int(weekly_progress[kind]) + 1)
	event_points += 12 if kind == "sink" else (8 if kind == "loot" else 5)
	if kind == "sink" and chain_stage < 3 and event_points >= [60, 180, 360][chain_stage]:
		chain_stage += 1
	var mission := current_mission()
	if mission.kind != kind:
		mission_changed.emit()
		return
	progress += 1
	var result: Dictionary = {}
	if progress >= int(mission.target):
		_apply_reward_bundle("mission:"+str(mission_index)+":"+str(completed_count),"mission_completion",int(mission.coins),int(mission.xp))
		completed_count += 1
		mission_index = (mission_index + 1) % _missions().size()
		progress = 0
		result = mission.duplicate(true)
		last_completed = result.duplicate(true)
	mission_changed.emit()
	if not result.is_empty():
		mission_completed.emit(result)

func _process(delta: float) -> void:
	_calendar_elapsed += delta
	if _calendar_elapsed >= 1.0:
		_calendar_elapsed = 0.0
		sync_calendar()

func sync_calendar(unix_seconds: int = -1) -> void:
	var now := int(TrustedTimeService.now(get_tree())) if unix_seconds < 0 else unix_seconds
	var day := int(floor(float(now) / 86400.0))
	var week := int(floor(float(day + 3) / 7.0)) # Monday 00:00 UTC.
	var updated := false
	if day_index < 0: day_index = day # Legacy counters retained in current period.
	if week_index < 0: week_index = week
	if day > day_index:
		day_index = day
		daily_progress = {"sink": 0, "loot": 0, "dock": 0}
		daily_claimed = false
		updated = true
	if week > week_index:
		week_index = week
		weekly_progress = {"sink": 0, "loot": 0, "dock": 0}
		weekly_claimed = false
		updated = true
	if updated: mission_changed.emit()

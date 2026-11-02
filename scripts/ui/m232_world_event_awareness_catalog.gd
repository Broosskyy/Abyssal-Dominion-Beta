class_name M232WorldEventAwarenessCatalog
extends RefCounted

## Presentation-only bridge for active EventRuntime state and event-owned world nodes.
## Never mutates event phase, rewards, combat, aggro, spawn, collision or navigation authority.
const EVENT_ENTER_RADIUS := 31.0
const EVENT_EXIT_HYSTERESIS := 6.0
const FEEDBACK_SECONDS := 2.8
const PHASE_FEEDBACK_SECONDS := 3.2
const BOSS_ANNOUNCE_RADIUS := 42.0
const BOSS_COOLDOWN := 8.0

static func event_runtime(tree:SceneTree)->EventRuntime:
	if tree==null:return null
	return tree.get_first_node_in_group("event_runtime") as EventRuntime

static func event_state(runtime:EventRuntime)->Dictionary:
	if runtime==null or not runtime.is_active():return {}
	return {
		"id":runtime.active_event_id,
		"title":runtime.title(),
		"phase":runtime.phase,
		"phase_label":runtime.phase_label(),
		"meter":runtime.meter_ratio(),
		"score":runtime.score,
		"currency":runtime.currency,
		"currency_label":runtime.currency_label()
	}

static func event_nodes(tree:SceneTree,event_id:String)->Array:
	var rows:Array=[]
	if tree==null or event_id.is_empty():return rows
	for group_name in ["event_interactables","enemies","world_poi_markers"]:
		for value in tree.get_nodes_in_group(group_name):
			var node:=value as Node3D
			if node==null or node in rows:continue
			if str(node.get_meta("event_id",""))!=event_id:continue
			# event_participant is accepted for combat actors; POIs are identified by the same event_id.
			if group_name=="enemies" and not bool(node.get_meta("event_participant",false)):continue
			var health:=node.get_node_or_null("Health")
			if health!=null and bool(health.get("is_sunk")):continue
			rows.append(node)
	return rows

static func nearest_anchor(player:Node3D,tree:SceneTree,event_id:String)->Dictionary:
	if player==null:return {}
	var best:Node3D=null
	var best_distance:=INF
	for node in event_nodes(tree,event_id):
		var d:=player.global_position.distance_to((node as Node3D).global_position)
		if d<best_distance:best=node;best_distance=d
	if best==null:return {}
	return {"node":best,"distance":best_distance,"key":"%s:%s"%[event_id,str(best.get_instance_id())]}

static func node_rank(node:Node3D)->String:
	if node==null:return ""
	var rank:=str(node.get_meta("encounter_rank",node.get_meta("rarity",""))).to_lower()
	var kind:=str(node.get_meta("encounter_kind","")).to_lower()
	if rank=="boss":return "boss"
	if kind=="admiral":return "admiral"
	if rank=="elite" or kind=="monster":return "elite"
	return "event"

static func boss_presence(node:Node3D)->bool:
	return node_rank(node) in ["boss","admiral"]

static func enter_label(runtime:EventRuntime)->String:
	return "WORLD-EVENT BETRETEN · %s"%runtime.title().to_upper() if runtime!=null else "WORLD-EVENT BETRETEN"

static func leave_label(runtime:EventRuntime)->String:
	return "WORLD-EVENT VERLASSEN · %s"%runtime.title().to_upper() if runtime!=null else "WORLD-EVENT VERLASSEN"

static func phase_label(runtime:EventRuntime)->String:
	if runtime==null:return ""
	return "EVENTPHASE %d · %s"%[runtime.phase,runtime.phase_label().to_upper()]

static func boss_label(node:Node3D)->String:
	if node==null:return ""
	var title:=str(node.get_meta("poi_label",node.get_meta("display_name",node.name))).replace("_"," ").to_upper()
	return ("EVENT-BOSS · " if node_rank(node)=="boss" else "EVENT-ADMIRAL · ")+title

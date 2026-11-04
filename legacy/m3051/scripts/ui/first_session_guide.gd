class_name FirstSessionGuide
extends RefCounted
const PATH:="res://data/m76_first_session_guidance.json"
static var _data:Dictionary={}

static func data()->Dictionary:
	if _data.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=parsed if parsed is Dictionary else {"steps":{}}
	return _data

static func state(player:ShipMotor)->Dictionary:
	if player==null:return {}
	var voyage:=player.get_node_or_null("Voyage") as VoyageProgress
	if voyage==null or voyage.beginner_complete() or not voyage.trial_active:return {}
	var primary:=voyage.presentation_primary()
	var kind:=str(primary.get("kind",""))
	var step:Dictionary=((data().get("steps",{}) as Dictionary).get(kind,{}) as Dictionary).duplicate(true)
	step["kind"]=kind
	step["current"]=int(primary.get("current",0))
	step["target"]=int(primary.get("target",1))
	return step

static func nearest_port(player:ShipMotor)->Node3D:
	if player==null:return null
	var best:Node3D=null
	var best_distance:=INF
	for node in player.get_tree().get_nodes_in_group("ports"):
		var port:=node as Node3D
		if port==null:continue
		var distance:=player.global_position.distance_to(port.global_position)
		var score:=distance-float(port.get_meta("guidance_priority",20))*0.02
		if score<best_distance:
			best=port
			best_distance=score
	return best

static func nearest_loot(player:ShipMotor)->Node3D:
	if player==null:return null
	var best:Node3D=null
	var best_distance:=INF
	for node in player.get_tree().get_nodes_in_group("loot"):
		var loot:=node as Node3D
		if loot==null:continue
		var distance:=player.global_position.distance_to(loot.global_position)
		if distance<best_distance:
			best=loot
			best_distance=distance
	return best

class_name WorldMarkerPriorityCatalog
extends RefCounted
const PATH:="res://data/m79_marker_priority.json"
static var _data:Dictionary={}

static func data()->Dictionary:
	if _data.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=parsed if parsed is Dictionary else {"priority":{}}
	return _data

static func priority(kind:String)->int:
	return int((data().get("priority",{}) as Dictionary).get(kind,20))



static func priority_for(node:Node,kind:String)->int:
	if node!=null and node.has_meta("marker_priority"):
		return int(node.get_meta("marker_priority",priority(kind)))
	return priority(kind)
static func sort_rows(rows:Array)->void:
	rows.sort_custom(func(a,b):
		var pa:=int(a.get("priority",0))
		var pb:=int(b.get("priority",0))
		if pa!=pb:return pa>pb
		return float(a.get("distance",INF))<float(b.get("distance",INF))
	)

static func color_hint(kind:String)->String:
	if kind in ["monster_nest","monster_warning","admiral","elite","event_boss"]:return "danger"
	if kind in ["salvage","supply","wreck_beacon","event_wreck"]:return "reward"
	if kind in ["port","objective","event_portal"]:return "primary"
	return "secondary"

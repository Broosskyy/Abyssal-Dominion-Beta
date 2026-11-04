class_name BeginnerQuestPresentation
extends RefCounted
const PATH := "res://data/m73_beginner_quest_presentation.json"
static var _data:Dictionary={}

static func data()->Dictionary:
	if _data.is_empty():
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=parsed if parsed is Dictionary else {"levels":{},"objective_copy":{},"objective_order":["sink","loot","dock"]}
	return _data

static func level_card(voyage:VoyageProgress)->Dictionary:
	if voyage==null:return {}
	var level:=clampi(voyage.map_level(),1,5)
	var base:Dictionary=(data().get("levels",{}) as Dictionary).get(str(level),{})
	var result:=base.duplicate(true)
	result["level"]=level
	result["active"]=voyage.trial_active
	result["complete"]=voyage.beginner_complete()
	result["progress"]=voyage.trial_counts.duplicate()
	return result

static func objectives(voyage:VoyageProgress)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if voyage==null:return result
	var copy:Dictionary=data().get("objective_copy",{})
	for kind in data().get("objective_order",["sink","loot","dock"]):
		var row:Dictionary=(copy.get(kind,{}) as Dictionary).duplicate(true)
		row["kind"]=str(kind)
		row["current"]=int(voyage.trial_counts.get(kind,0))
		row["target"]=int(VoyageProgress.TRIAL_GOALS.get(kind,1))
		row["done"]=int(row.get("current",0))>=int(row.get("target",1))
		result.append(row)
	return result

static func primary(voyage:VoyageProgress)->Dictionary:
	for row in objectives(voyage):
		if not bool(row.done):return row
	return objectives(voyage)[-1] if not objectives(voyage).is_empty() else {}

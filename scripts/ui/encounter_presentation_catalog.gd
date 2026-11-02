class_name EncounterPresentationCatalog
extends RefCounted
const PATH := "res://data/m74_encounter_presentation.json"
static var _data:Dictionary={}

static func data()->Dictionary:
	if _data.is_empty():
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=parsed if parsed is Dictionary else {"profiles":{}}
	return _data

static func profile(ship:Node3D)->Dictionary:
	if ship==null:return {}
	var key:=""
	if str(ship.get_meta("encounter_kind",""))=="monster":
		key="monster"
	elif bool(ship.get_meta("is_admiral",false)) or str(ship.get_meta("encounter_rank",""))=="boss":
		key="admiral"
	elif str(ship.get_meta("encounter_rank",""))=="elite":
		key="elite"
	elif _provocation_flash(ship):
		key="provoked"
	else:
		key="neutral" if EncounterRelation.status(ship)==EncounterRelation.NEUTRAL else "hostile"
	return ((data().get("profiles",{}) as Dictionary).get(key,{}) as Dictionary).duplicate(true)

static func _provocation_flash(ship:Node3D)->bool:
	var until:=float(ship.get_meta("provoked_feedback_until",0.0))
	return until>Time.get_ticks_msec()/1000.0

static func label(ship:Node3D)->String:
	return str(profile(ship).get("label",EncounterRelation.label(ship)))

static func icon_slot(ship:Node3D)->String:
	return str(profile(ship).get("icon","world_interact"))

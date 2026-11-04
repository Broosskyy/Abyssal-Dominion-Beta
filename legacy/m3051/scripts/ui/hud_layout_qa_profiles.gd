class_name HudLayoutQaProfiles
extends RefCounted
const PATH:="res://data/m86_hud_device_preview_profiles.json"
static var _data:Dictionary={}

static func data()->Dictionary:
	if _data.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=parsed if parsed is Dictionary else {"profiles":[]}
	return _data

static func profiles()->Array:
	var rows:Variant=data().get("profiles",[])
	return rows if rows is Array else []

static func profile(index:int)->Dictionary:
	var rows:=profiles()
	if rows.is_empty():return {}
	return (rows[posmod(index,rows.size())] as Dictionary).duplicate(true)

static func safe_rect(row:Dictionary)->Rect2:
	var a:Array=row.get("safe",[0,0,1280,720])
	return Rect2(float(a[0]),float(a[1]),float(a[2]),float(a[3]))

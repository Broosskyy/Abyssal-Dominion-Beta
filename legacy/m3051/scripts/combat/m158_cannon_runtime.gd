class_name M158CannonRuntime
extends RefCounted

const DATA_PATH := "res://data/m158_cannon_runtime_progression.json"

static func _data()->Dictionary:
	if not FileAccess.file_exists(DATA_PATH): return {}
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	return parsed if parsed is Dictionary else {}

static func modifiers(cannon_row:Dictionary,upgrade_level:int,ammo_id:String="")->Dictionary:
	var result:Dictionary={"damage_mult":1.0,"reload_mult":1.0,"range_mult":1.0,"ammo_mult":1.0,"tier":1}
	var selected:Dictionary={}
	for row in _data().get("tiers",[]):
		if upgrade_level>=int(row.get("min_upgrade",0)):
			selected=row
	if not selected.is_empty():
		result.damage_mult=float(selected.get("damage_mult",1.0))
		result.reload_mult=float(selected.get("reload_mult",1.0))
		result.range_mult=float(selected.get("range_mult",1.0))
		result.tier=int(selected.get("tier",1))
	var role:=str(cannon_row.get("role","balanced"))
	var mastery:Dictionary=_data().get("role_masteries",{}).get(role,{})
	for key in ["tier3","tier5"]:
		var required:=3 if key=="tier3" else 5
		if int(result.tier)<required: continue
		var row:Dictionary=mastery.get(key,{})
		result.damage_mult*=float(row.get("damage_mult",1.0))
		result.reload_mult*=float(row.get("reload_mult",1.0))
		result.range_mult*=float(row.get("range_mult",1.0))
		if not ammo_id.is_empty() and ammo_id in preferred_ammo(role):
			result.ammo_mult*=float(row.get("preferred_ammo_bonus",1.0))
	return result

static func preferred_ammo(role:String)->Array[String]:
	var result:Array[String]=[]
	for id in _data().get("preferred_ammo_by_role",{}).get(role,[]): result.append(str(id))
	return result

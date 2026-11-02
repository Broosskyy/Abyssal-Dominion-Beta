class_name AccountProfileDto
extends RefCounted
const PATH:="res://data/m103_account_profile_dto.json"
static func contract()->Dictionary:
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return v if v is Dictionary else {}
static func local_preview(profile:Dictionary,guest:bool)->Dictionary:
	var local_id:=str(profile.get("id","guest"))
	return {
		"dto_version":1,
		"account_id":"local:"+local_id,
		"captain":{"dto_version":1,"captain_id":"local:"+local_id,"account_id":"local:"+local_id,
			"captain_name":"Gastkapitän" if guest else str(profile.get("name","Kapitän")),"revision":0},
		"revision":0,"status":"local_preview","server_verified":false
	}
static func valid_server_shape(value:Dictionary)->bool:
	return int(value.get("dto_version",0))==1 and not str(value.get("account_id","")).is_empty() and int(value.get("revision",-1))>=0

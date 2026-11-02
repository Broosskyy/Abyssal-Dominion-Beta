class_name BuildIdentity
extends RefCounted
const PATH:="res://data/release_identity.json"
static var _data:Dictionary={}
static func data()->Dictionary:
	if _data.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=parsed if parsed is Dictionary else {}
	return _data
static func compact()->String:
	var d:Dictionary=data()
	return "%s · B%s · %s · %s"%[str(d.get("client_version","?")),str(d.get("build_number","?")),str(d.get("content_config_version","?")),str(d.get("environment","LOCAL_DEVELOPMENT"))]

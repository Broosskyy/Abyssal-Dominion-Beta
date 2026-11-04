class_name EnvironmentContract
extends RefCounted
const PATH:="res://data/environment_contract.json"
static var _data:Dictionary={}
static func data()->Dictionary:
	if _data.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=parsed if parsed is Dictionary else {}
	return _data
static func current_id(tree:SceneTree)->String:
	if tree==null:return "LOCAL_DEVELOPMENT"
	return str(tree.root.get_meta("environment_id","LOCAL_DEVELOPMENT"))
static func is_live_authority(tree:SceneTree)->bool:
	return current_id(tree)=="GLOBAL_PRODUCTION" and bool(tree.root.get_meta("server_authority_verified",false))
static func is_test_like(tree:SceneTree)->bool:
	return current_id(tree) in ["LOCAL_DEVELOPMENT","INTERNAL_STAGING","TESTSERVER"]

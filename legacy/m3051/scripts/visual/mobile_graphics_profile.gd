class_name MobileGraphicsProfile
extends RefCounted
const PATH:="res://data/m101_mobile_graphics_profiles.json"
static var _data:Dictionary={}
static func data()->Dictionary:
	if _data.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=parsed if parsed is Dictionary else {}
	return _data
static func profile(id:String)->Dictionary:
	return (data().get("profiles",{}) as Dictionary).get(id,{}).duplicate(true)
static func current(tree:SceneTree)->Dictionary:
	if tree==null:return profile("balanced")
	var id:=str(tree.root.get_meta("quality_tier","balanced"))
	return profile(id if id in ["low","balanced","high"] else "balanced")

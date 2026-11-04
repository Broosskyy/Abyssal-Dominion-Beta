class_name LiveConfigRegistry
extends Node
signal config_changed(version:String)
const DEFAULT_PATH:="res://data/live_balance_defaults.json"
var defaults:Dictionary={}
var active:Dictionary={}
var version:=""
var source:="local_fallback"
func _ready()->void:
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(DEFAULT_PATH))
	defaults=parsed if parsed is Dictionary else {}
	active=defaults.duplicate(true);version=str(active.get("config_version","missing"))
	get_tree().root.set_meta("active_balance_config_version",version)
	get_tree().root.set_meta("balance_config_source",source)
func value_at(path:String,fallback:Variant=null)->Variant:
	var node:Variant=active
	for key in path.split("."):
		if not node is Dictionary or not (node as Dictionary).has(key):return fallback
		node=(node as Dictionary)[key]
	return node
func dictionary(path:String,fallback:Dictionary={})->Dictionary:
	var v:Variant=value_at(path,fallback);return (v as Dictionary).duplicate(true) if v is Dictionary else fallback.duplicate(true)
func array(path:String,fallback:Array=[])->Array:
	var v:Variant=value_at(path,fallback);return (v as Array).duplicate(true) if v is Array else fallback.duplicate(true)
func apply_verified_snapshot(snapshot:Dictionary,verified:bool)->bool:
	# Transport/server verification is intentionally outside this local prototype.
	if not verified or int(snapshot.get("schema_version",0))!=1:return false
	active=snapshot.duplicate(true);version=str(active.get("config_version","unknown"));source="verified_snapshot"
	get_tree().root.set_meta("active_balance_config_version",version);get_tree().root.set_meta("balance_config_source",source)
	config_changed.emit(version);return true
func reset_local()->void:
	active=defaults.duplicate(true);version=str(active.get("config_version","missing"));source="local_fallback";config_changed.emit(version)
static func current(tree:SceneTree)->LiveConfigRegistry:
	return tree.get_first_node_in_group("live_config") as LiveConfigRegistry

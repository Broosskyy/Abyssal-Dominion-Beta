class_name M167UxContentCatalog
extends Node
const UI_PATH := "res://data/m167_mobile_interaction_contract.json"
const SOURCE_PATH := "res://data/m167_source_binding_station_progression.json"
var ui:Dictionary={}
var sources:Dictionary={}
func _ready()->void:
	add_to_group("m167_ux_content_catalog")
	ui=_load(UI_PATH);sources=_load(SOURCE_PATH)
func _load(path:String)->Dictionary:
	if not FileAccess.file_exists(path):return {}
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
func mobile_profile(viewport_size:Vector2,dpi:float)->Dictionary:
	var compact:=viewport_size.x<390.0 or viewport_size.y<720.0
	var key:="compact_phone" if compact else ("phone" if dpi>180.0 or viewport_size.x<700.0 else "tablet_desktop")
	return ((ui.get("profiles",{}) as Dictionary).get(key,{}) as Dictionary).duplicate(true)
func short_tab_label(id:String)->String:
	return str(((ui.get("navigation",{}) as Dictionary).get("short_labels",{}) as Dictionary).get(id,id.to_upper()))
func interactions()->Array:return ui.get("interaction_contracts",[]) as Array
func qa_matrix()->Array:return ui.get("qa_matrix",[]) as Array
func item_families()->Array:return sources.get("item_families",[]) as Array
func binding_rules()->Array:return sources.get("binding_rules",[]) as Array
func stations()->Array:return sources.get("station_progression",[]) as Array

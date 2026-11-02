class_name M174MenuPanelCatalog
extends Node
const PATH="res://data/m174_menu_panel_hardening.json"
var data:Dictionary={}
func _ready()->void:
	add_to_group("m174_menu_panel_catalog")
	if FileAccess.file_exists(PATH):
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(PATH));data=parsed if parsed is Dictionary else {}
func contracts()->Array:return data.get("menu_panel_contracts",[]) as Array
func mobile_rules()->Dictionary:return data.get("mobile_panel_rules",{}) as Dictionary

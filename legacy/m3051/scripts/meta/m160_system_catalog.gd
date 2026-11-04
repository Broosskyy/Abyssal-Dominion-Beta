class_name M160SystemCatalog
extends Node
const PATH := "res://data/m160_system_depth.json"
var data:Dictionary={}
func _ready()->void:
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else {}
	data=parsed if parsed is Dictionary else {}
	add_to_group("m160_system_catalog")
func rows(key:String)->Array:return data.get(key,[]) as Array
func special_deck(id:String)->Dictionary:
	for row in rows("special_decks"):
		if row is Dictionary and str(row.get("id",""))==id:return (row as Dictionary).duplicate(true)
	return {}
func admin_capabilities()->Dictionary:return (data.get("admin",{}) as Dictionary).duplicate(true)

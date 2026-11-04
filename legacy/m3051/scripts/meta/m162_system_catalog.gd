class_name M162SystemCatalog
extends Node
const PATH := "res://data/m162_system_runtime.json"
var data:Dictionary={}
func _ready()->void:
	add_to_group("m162_system_catalog")
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else {}
	data=v if v is Dictionary else {}
func rows(key:String)->Array:return data.get(key,[]) as Array
func definition(key:String,id:String)->Dictionary:
	for row in rows(key):
		if row is Dictionary and str(row.get("id",""))==id:return (row as Dictionary).duplicate(true)
	return {}
func special_decks()->Array:return rows("special_decks")
func talent_nodes(tree_id:String="")->Array:
	var out:Array=[]
	for row in rows("talent_nodes"):
		if row is Dictionary and (tree_id.is_empty() or str(row.get("tree",""))==tree_id):out.append((row as Dictionary).duplicate(true))
	return out
func citadel_branches()->Array:return rows("citadel_branches")
func cannon_tracks()->Array:return rows("cannon_upgrade_tracks")
func new_items()->Array:return rows("new_items")
func summary()->Dictionary:return {"special_decks":special_decks().size(),"talent_nodes":rows("talent_nodes").size(),"citadel":citadel_branches().size(),"cannon_tracks":cannon_tracks().size(),"items":new_items().size()}

class_name M165RuntimeDepthCatalog
extends Node
const PATH := "res://data/m165_runtime_effects_crafting_guild.json"
var data:Dictionary={}
func _ready()->void:
	add_to_group("m165_runtime_depth_catalog")
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else {}
	data=parsed if parsed is Dictionary else {}
func rows(key:String)->Array:return data.get(key,[]) as Array
func harpoons()->Array:return rows("harpoon_runtime_profiles")
func recipes()->Array:return rows("crafting_recipes")
func stations()->Array:return rows("crafting_stations")
func tower_specializations()->Array:return rows("guild_tower_specializations")
func cannon_visual_stages()->Array:return rows("cannon_visual_stage_rules")
func recipe(id:String)->Dictionary:
	for row in recipes():
		if row is Dictionary and str(row.get("id",""))==id:return (row as Dictionary).duplicate(true)
	return {}

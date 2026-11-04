class_name M164NoCodeCatalog
extends Node
const PATH := "res://data/m164_no_code_combat_guild_ui.json"
var data:Dictionary={}
func _ready()->void:
	add_to_group("m164_no_code_catalog")
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else {}
	data=parsed if parsed is Dictionary else {}
func rows(key:String)->Array:return data.get(key,[]) as Array
func ammo_extensions()->Array:return rows("ammo_extensions")
func harpoon_extensions()->Array:return rows("harpoon_extensions")
func cannon_evolution()->Array:return rows("cannon_evolution")
func guild_modules()->Array:return rows("guild_island_modules")
func new_items()->Array:return rows("new_items")
func admin_runtime_editors()->Array:return rows("admin_runtime_editors")
func guild_curves()->Dictionary:return (data.get("guild_upgrade_curves",{}) as Dictionary).duplicate(true)
func summary()->Dictionary:return {"ammo_extensions":ammo_extensions().size(),"harpoon_extensions":harpoon_extensions().size(),"guild_modules":guild_modules().size(),"items":new_items().size(),"admin_runtime_editors":admin_runtime_editors().size()}

class_name M163SystemDepthCatalog
extends Node
const PATH := "res://data/m163_system_depth_and_guild.json"
var data:Dictionary={}
func _ready()->void:
	add_to_group("m163_system_depth_catalog")
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else {}
	data=parsed if parsed is Dictionary else {}
func rows(key:String)->Array:return data.get(key,[]) as Array
func special_deck_depth()->Array:return rows("special_deck_depth")
func ammo_profiles()->Array:return rows("ammo_profiles")
func harpoon_profiles()->Array:return rows("harpoon_profiles")
func consumables()->Array:return rows("consumables_and_materials")
func cannon_visual_stages()->Array:return rows("cannon_visual_stages")
func guild_data()->Dictionary:return (data.get("guild",{}) as Dictionary).duplicate(true)
func admin_editors()->Array:return rows("admin_editors")
func definition(key:String,id:String)->Dictionary:
	for row in rows(key):
		if row is Dictionary and str(row.get("id",""))==id:return (row as Dictionary).duplicate(true)
	return {}
func guild_rows(key:String)->Array:
	var g:=data.get("guild",{}) as Dictionary
	return g.get(key,[]) as Array
func summary()->Dictionary:return {"ammo":ammo_profiles().size(),"harpoons":harpoon_profiles().size(),"items":consumables().size(),"guild_ranks":guild_rows("ranks").size(),"guild_buildings":guild_rows("buildings").size(),"guild_towers":guild_rows("towers").size(),"admin_editors":admin_editors().size()}

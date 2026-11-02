class_name VisualQualityResolver
extends RefCounted
const PATH:="res://data/m137_visual_budget_profiles.json"
static var _profiles:Dictionary={}
static func profiles()->Dictionary:
	if _profiles.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_profiles=parsed if parsed is Dictionary else {}
	return _profiles
static func platform_key()->String:
	if OS.has_feature("web"):return "web"
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):return "mobile"
	return "desktop"
static func profile()->Dictionary:return profiles().get(platform_key(),profiles().get("desktop",{}))
static func desired_lod(hero:bool)->String:
	var p:=profile();return str(p.get("hero_lod" if hero else "standard_ship_lod","LOD1"))
static func select_path(entry:Dictionary,replacement:Dictionary,hero:bool)->Dictionary:
	var lod:=desired_lod(hero);var key:=lod.to_lower()+"_path"
	var path:=str(replacement.get(key,replacement.get("path",entry.get(key,entry.get("path","")))))
	if path.is_empty():path=str(replacement.get("path",entry.get("path","")))
	return {"path":path,"lod":lod,"vfx":str(profile().get("vfx","desktop"))}
static func island_budget()->int:return maxi(1,int(profiles().get("desktop",{}).get("islands_per_sector",8)))
static func decorator_budget()->int:return maxi(1,int(profiles().get("desktop",{}).get("decorators_per_island",8)))

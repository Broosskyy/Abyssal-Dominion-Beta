class_name WorldRegionRegistry
extends RefCounted
const PATH:="res://data/world_region_registry_v37.json"
static var _data:Dictionary={}
static func data()->Dictionary:
	if _data.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=parsed if parsed is Dictionary else {"regions":[]}
	return _data
static func all()->Array:return data().get("regions",[])
static func by_id(id:String)->Dictionary:
	for row in all():
		if str(row.get("id",""))==id:return (row as Dictionary).duplicate(true)
	return {}
static func for_level(level:int)->Dictionary:
	for row in all():
		var band:Array=row.get("levels",[])
		if band.size()>=2 and level>=int(band[0]) and level<=int(band[1]):return (row as Dictionary).duplicate(true)
	return {}
static func effective(tree:SceneTree,id:String)->Dictionary:
	var base:=by_id(id)
	var dynamic:=DynamicContentResolver.by_id(tree,"region","REGION-"+id.to_upper().replace("_","-"))
	if dynamic.is_empty():return base
	var out:=base.duplicate(true)
	for key in ["biome_profile","npc_pool","monster_pool","admiral_pool","island_pool","poi_pool","visual_profile","music_profile"]:
		if dynamic.has(key):out[key]=dynamic[key]
	return out
static func validate()->PackedStringArray:
	var errors:=PackedStringArray();var expected:=1
	for row in all():
		var band:Array=row.get("levels",[])
		if band.size()!=2:errors.append(str(row.get("id",""))+":band");continue
		if int(band[0])!=expected:errors.append(str(row.get("id",""))+":gap")
		expected=int(band[1])+1
	if expected!=61:errors.append("must_end_at_60")
	return errors

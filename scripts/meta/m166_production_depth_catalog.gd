class_name M166ProductionDepthCatalog
extends Node
const PATH := "res://data/m166_production_depth_sources_effects.json"
var data:Dictionary={}
func _ready()->void:
	add_to_group("m166_production_depth_catalog")
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else {}
	data=parsed if parsed is Dictionary else {}
func rows(key:String)->Array:return data.get(key,[]) as Array
func effects()->Array:return rows("effect_runtime")
func recipes()->Array:return rows("crafting_recipes")
func sources()->Array:return rows("source_graph")
func effect(id:String)->Dictionary:
	for row in effects():
		if row is Dictionary and str(row.get("id",""))==id:return (row as Dictionary).duplicate(true)
	return {}
func recipe(id:String)->Dictionary:
	for row in recipes():
		if row is Dictionary and str(row.get("id",""))==id:return (row as Dictionary).duplicate(true)
	return {}
func sources_for(content_id:String)->Array[String]:
	var out:Array[String]=[]
	for row in sources():
		if row is Dictionary and str(row.get("content_id",""))==content_id:
			for value in row.get("sources",[]):out.append(str(value))
	return out
func combined_recipes(m165:M165RuntimeDepthCatalog)->Array:
	var out:Array=[];var known:Dictionary={}
	if m165!=null:
		for row in m165.recipes():
			if row is Dictionary:out.append((row as Dictionary).duplicate(true));known[str(row.get("id",""))]=true
	for row in recipes():
		if row is Dictionary and not known.has(str(row.get("id",""))):out.append((row as Dictionary).duplicate(true))
	return out

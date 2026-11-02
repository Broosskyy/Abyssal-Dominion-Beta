class_name SupportPayloadCatalog
extends RefCounted
const PATH := "res://data/support_payloads.json"
static var _data: Dictionary = {}
static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {}
	return _data
static func _m165_harpoons() -> Array:
	var path := "res://data/m165_runtime_effects_crafting_guild.json"
	if not FileAccess.file_exists(path): return []
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return (parsed as Dictionary).get("harpoon_runtime_profiles",[]) as Array if parsed is Dictionary else []
static func harpoon_payloads() -> Array:
	var base:Array=data().get("harpoon_payloads",[]).duplicate(true)
	var known:Dictionary={}
	for row in base:
		if row is Dictionary: known[str(row.get("id",""))]=true
	for row in _m165_harpoons():
		if row is Dictionary and not known.has(str(row.get("id",""))): base.append((row as Dictionary).duplicate(true))
	var tree:=Engine.get_main_loop() as SceneTree
	return DynamicContentResolver.merged(tree,"harpoon",base) if tree!=null else base
static func support_ammo() -> Array:
	var base:Array=data().get("support_ammo",[])
	var tree:=Engine.get_main_loop() as SceneTree
	return DynamicContentResolver.merged(tree,"support",base) if tree!=null else base

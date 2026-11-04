class_name ActionItemCatalog
extends RefCounted

const PATH := "res://data/action_items.json"
static var _cache: Dictionary = {}

static func read() -> Dictionary:
	if not _cache.is_empty(): return _cache
	if not FileAccess.file_exists(PATH): return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(PATH)) != OK or not json.data is Dictionary: return {}
	_cache = json.data
	return _cache

static func item(id: String) -> Dictionary:
	var tree:=Engine.get_main_loop() as SceneTree
	if tree!=null:
		var dynamic:=DynamicContentResolver.by_id(tree,"item",id)
		if not dynamic.is_empty():return dynamic
	for value in read().get("items", []):
		if str(value.get("id", "")) == id: return (value as Dictionary).duplicate(true)
	return {}

static func item_ids() -> Array[String]:
	var out: Array[String] = []
	for value in read().get("items", []): out.append(str(value.get("id", "")))
	var tree:=Engine.get_main_loop() as SceneTree
	if tree!=null:
		for value in DynamicContentResolver.active_records(tree,"item"):
			var id:=str(value.get("id",""))
			if id not in out:out.append(id)
	return out

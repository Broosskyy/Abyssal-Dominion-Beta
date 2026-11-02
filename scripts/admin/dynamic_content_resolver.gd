class_name DynamicContentResolver
extends RefCounted
static func active_records(tree:SceneTree,type_id:String)->Array:
	var registry:=LiveConfigRegistry.current(tree)
	if registry==null:return []
	var rows:=registry.array("content.records",[])
	var out:Array=[]
	for row in rows:
		if row is Dictionary and str(row.get("type",""))==type_id and bool(row.get("enabled",false)):out.append((row as Dictionary).duplicate(true))
	return out
static func by_id(tree:SceneTree,type_id:String,id:String)->Dictionary:
	for row in active_records(tree,type_id):
		if str(row.get("id",""))==id:return row
	return {}
static func merged(tree:SceneTree,type_id:String,builtin:Array)->Array:
	var out:=builtin.duplicate(true);var ids:Dictionary={}
	for row in out:
		if row is Dictionary:ids[str(row.get("id",row.get("name","")))]=true
	for row in active_records(tree,type_id):
		var id:=str(row.get("id",""))
		if not ids.has(id):out.append(row);ids[id]=true
	return out

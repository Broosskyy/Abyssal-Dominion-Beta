class_name DynamicQuestResolver
extends RefCounted
static func active(tree:SceneTree,context:Dictionary={})->Array:
	var out:Array=[]
	for row in DynamicContentResolver.active_records(tree,"quest"):
		var requirements:Dictionary=row.get("requirements",{})
		var min_level:=int(requirements.get("min_level",1));var max_level:=int(requirements.get("max_level",60))
		var level:=int(context.get("pirate_level",1))
		if level>=min_level and level<=max_level:out.append(row)
	return out
static func objectives(tree:SceneTree,id:String)->Array:
	var row:=DynamicContentResolver.by_id(tree,"quest",id);return row.get("objectives",[]) if not row.is_empty() else []

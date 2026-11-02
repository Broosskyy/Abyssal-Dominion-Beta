class_name DynamicItemDefinition
extends RefCounted
static func definition(tree:SceneTree,id:String)->Dictionary:
	var row:=DynamicContentResolver.by_id(tree,"item",id)
	if not row.is_empty():return row
	for type_id in ["ammo","harpoon","support"]:
		row=DynamicContentResolver.by_id(tree,type_id,id)
		if not row.is_empty():return row
	return {}
static func exists(tree:SceneTree,id:String)->bool:return not definition(tree,id).is_empty()
static func stack_limit(tree:SceneTree,id:String,fallback:int)->int:
	var row:=definition(tree,id);return maxi(1,int(row.get("stack_limit",fallback))) if not row.is_empty() else fallback

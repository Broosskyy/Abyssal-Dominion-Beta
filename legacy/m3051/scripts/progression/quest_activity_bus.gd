class_name QuestActivityBus
extends RefCounted
static func emit(tree:SceneTree,kind:String,context:Dictionary={})->void:
	if tree==null:return
	var runtime:=tree.get_first_node_in_group("dynamic_quest_runtime") as DynamicQuestRuntime
	if runtime==null:return
	var payload:=context.duplicate(true);payload["amount"]=maxi(1,int(payload.get("amount",1)))
	if not payload.has("tags"):payload["tags"]=[]
	runtime.record(kind,payload)
static func combat_tags(target:ShipMotor)->Array:
	var tags:Array=[]
	if target==null:return tags
	for value in [str(target.get_meta("encounter_kind","ship")),str(target.get_meta("rarity","common")),
		str(target.get_meta("regional_combat_role","")),str(target.get_meta("archetype",""))]:
		if not value.is_empty() and value not in tags:tags.append(value)
	if bool(target.get_meta("hunter_objective_target",false)) and "hunter" not in tags:tags.append("hunter")
	if bool(target.get_meta("is_admiral",false)) and "admiral" not in tags:tags.append("admiral")
	return tags

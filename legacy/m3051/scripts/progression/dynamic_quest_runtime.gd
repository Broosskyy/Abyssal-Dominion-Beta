class_name DynamicQuestRuntime
extends Node
signal changed
signal quest_completed(quest_id:String)
var progress:Dictionary={}
var completed:Dictionary={}
func _ready()->void:add_to_group("dynamic_quest_runtime")
func active_quests()->Array:
	var voyage:=get_parent().get_node_or_null("Voyage") as VoyageProgress
	var level:=voyage.map_level() if voyage!=null else 1
	return DynamicQuestResolver.active(get_tree(),{"pirate_level":level})
func record(kind:String,context:Dictionary={})->void:
	for quest in active_quests():
		var quest_id:=str(quest.get("id",""))
		if quest_id.is_empty() or bool(completed.get(quest_id,false)):continue
		var objectives:Array=quest.get("objectives",[])
		var state:Dictionary=(progress.get(quest_id,{}) as Dictionary).duplicate(true)
		for i in range(objectives.size()):
			var objective:Dictionary=objectives[i] if objectives[i] is Dictionary else {}
			if str(objective.get("kind",""))!=kind:continue
			var required_ids:Array=objective.get("content_ids",[])
			if not required_ids.is_empty() and str(context.get("content_id","")) not in required_ids:continue
			var tags:Array=objective.get("content_tags",[])
			var context_tags:Array=context.get("tags",[])
			if not tags.is_empty():
				var matched:=false
				for tag in tags:
					if tag in context_tags:matched=true
				if not matched:continue
			var key:=str(i);state[key]=mini(int(objective.get("target",1)),int(state.get(key,0))+maxi(1,int(context.get("amount",1))))
		progress[quest_id]=state
		if _ready_to_complete(quest):
			completed[quest_id]=true
			_apply_rewards(quest)
			quest_completed.emit(quest_id)
	changed.emit()
func _ready_to_complete(quest:Dictionary)->bool:
	var quest_id:=str(quest.get("id",""));var state:Dictionary=progress.get(quest_id,{})
	var objectives:Array=quest.get("objectives",[])
	if objectives.is_empty():return false
	for i in range(objectives.size()):
		var objective:Dictionary=objectives[i] if objectives[i] is Dictionary else {}
		if int(state.get(str(i),0))<int(objective.get("target",1)):return false
	return true
func _apply_rewards(quest:Dictionary)->void:
	var services:=ServiceLocator.from(get_tree())
	if services==null or services.rewards==null:return
	var reward:Dictionary=quest.get("rewards",{})
	var items:Array=[]
	if not str(reward.get("item_id","")).is_empty():
		items.append({"id":str(reward.get("item_id","")),"quantity":int(reward.get("amount",1))})
	for row in reward.get("items",[]):
		if row is Dictionary:items.append(row)
	services.rewards.apply(RewardBundleService.bundle("quest:"+str(quest.get("id","")),"dynamic_quest",int(reward.get("gold",reward.get("coins",0))),int(reward.get("xp",0)),items))
func summary()->Array:
	var out:Array=[]
	for quest in active_quests():
		var id:=str(quest.get("id",""));out.append({"id":id,"name":str(quest.get("name",id)),"completed":bool(completed.get(id,false)),"progress":(progress.get(id,{}) as Dictionary).duplicate(true)})
	return out
func export_state()->Dictionary:return {"progress":progress.duplicate(true),"completed":completed.duplicate(true)}
func import_state(v:Dictionary)->void:
	progress=(v.get("progress",{}) as Dictionary).duplicate(true);completed=(v.get("completed",{}) as Dictionary).duplicate(true);changed.emit()

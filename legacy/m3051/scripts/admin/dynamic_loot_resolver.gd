class_name DynamicLootResolver
extends RefCounted
static func table(tree:SceneTree,id:String,builtin:Dictionary={})->Dictionary:
	var dynamic:=DynamicContentResolver.by_id(tree,"loot_table",id)
	return dynamic if not dynamic.is_empty() else builtin.duplicate(true)
static func roll(tree:SceneTree,id:String,seed:int,builtin:Dictionary={})->Array[Dictionary]:
	var definition:=table(tree,id,builtin);var out:Array[Dictionary]=[];var rng:=RandomNumberGenerator.new();rng.seed=seed
	for entry in definition.get("entries",[]):
		if not entry is Dictionary:continue
		var chance:=clampf(float(entry.get("chance",1.0)),0.0,1.0)
		if rng.randf()<=chance:
			out.append({"item_id":str(entry.get("item_id","")),"currency":str(entry.get("currency","")),"amount":maxi(0,int(entry.get("amount",1)))})
	return out

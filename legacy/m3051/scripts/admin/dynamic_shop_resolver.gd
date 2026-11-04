class_name DynamicShopResolver
extends RefCounted
static func shop(tree:SceneTree,id:String)->Dictionary:return DynamicContentResolver.by_id(tree,"shop",id)
static func offers(tree:SceneTree,id:String)->Array:
	var row:=shop(tree,id);return row.get("offers",[]) if not row.is_empty() else []
static func validate_offer(offer:Dictionary)->bool:
	return not str(offer.get("content_id","")).is_empty() and int(offer.get("amount",1))>0 and float(offer.get("price",0.0))>=0.0

class_name DynamicShopPurchase
extends RefCounted
static func purchase(tree:SceneTree,shop_id:String,offer_index:int,player:ShipMotor)->Dictionary:
	if player==null:return {"ok":false,"reason":"player_missing"}
	var shop:=DynamicShopResolver.shop(tree,shop_id);var offers:Array=shop.get("offers",[])
	if offer_index<0 or offer_index>=offers.size():return {"ok":false,"reason":"offer_missing"}
	var offer:Dictionary=offers[offer_index]
	if not DynamicShopResolver.validate_offer(offer):return {"ok":false,"reason":"invalid_offer"}
	var currency:=str(shop.get("currency","gold"));var price:=int(offer.get("price",0));var amount:=int(offer.get("amount",1));var content_id:=str(offer.get("content_id",""))
	var inventory:=player.get_node_or_null("Inventory") as PlayerInventory
	var progression:=player.get_node_or_null("Progression") as PlayerProgression
	if inventory==null or progression==null or not inventory.at_port():return {"ok":false,"reason":"not_at_port"}
	if currency!="gold":return {"ok":false,"reason":"currency_requires_server_wallet"}
	if progression.coins<price:return {"ok":false,"reason":"insufficient_funds"}
	if not inventory.item_exists(content_id):return {"ok":false,"reason":"unknown_item"}
	if inventory.count(content_id)+amount>inventory.max_stock_for(content_id):return {"ok":false,"reason":"stack_limit"}
	progression.add_coins(-price);inventory.set_count(content_id,inventory.count(content_id)+amount)
	return {"ok":true,"shop_id":shop_id,"content_id":content_id,"amount":amount,"price":price,"authority":"local_fallback"}

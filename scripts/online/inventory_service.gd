class_name InventoryService
extends GameServiceFacade
func _inventory()->PlayerInventory:
	return player.get_node_or_null("Inventory") as PlayerInventory if player!=null else null
func count(id:String)->int:
	var inv:=_inventory();return inv.count(id) if inv!=null else 0
func snapshot()->Dictionary:
	var inv:=_inventory();return inv.export_state() if inv!=null else {}
func set_count(id:String,amount:int)->Dictionary:
	if not local_only():return {"ok":false,"error":"server_inventory_repository_required"}
	var inv:=_inventory()
	if inv==null:return {"ok":false,"error":"inventory_unavailable"}
	inv.set_count(id,amount);return {"ok":true,"authority":"local_only","count":inv.count(id)}
func consume(id:String,amount:int=1)->Dictionary:
	if not local_only():return {"ok":false,"error":"server_inventory_repository_required"}
	var inv:=_inventory()
	return {"ok":inv!=null and inv.consume(id,amount),"authority":"local_only"}

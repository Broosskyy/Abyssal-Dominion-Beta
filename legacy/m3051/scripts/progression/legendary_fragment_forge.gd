class_name LegendaryFragmentForge
extends Node
signal changed
const FRAGMENT_COST:=5
var crafted_cores:=0
func can_craft(inventory:PlayerInventory)->bool:return inventory!=null and inventory.at_port() and inventory.count("legendary_fragment")>=FRAGMENT_COST
func craft(inventory:PlayerInventory)->bool:
	if not can_craft(inventory) or not inventory.consume("legendary_fragment",FRAGMENT_COST):return false
	inventory.set_count("ancient_relic_core",inventory.count("ancient_relic_core")+1);crafted_cores+=1;changed.emit();return true
func export_state()->Dictionary:return {"crafted_cores":crafted_cores}
func import_state(v:Dictionary)->void:crafted_cores=maxi(0,int(v.get("crafted_cores",0)));changed.emit()

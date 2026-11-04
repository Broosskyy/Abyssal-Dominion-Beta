class_name AncientEquipment
extends Node
signal changed
const PATH:="res://data/m119_ancient_equipment.json"
var owned:Array[String]=[]
var equipped:=""
func data()->Dictionary:
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH));return v if v is Dictionary else {}
func item(id:String)->Dictionary:
	for row in data().get("items",[]):
		if str(row.get("id",""))==id:return row
	return {}
func craft(id:String,inv:PlayerInventory)->bool:
	if id in owned or inv==null or not inv.at_port():return false
	var d:=item(id);if d.is_empty():return false
	if not inv.consume("ancient_relic_core",int(d.get("cost_core",1))):return false
	owned.append(id);changed.emit();return true
func equip(id:String)->bool:
	if not id.is_empty() and not id in owned:return false
	equipped=id;_apply();changed.emit();return true
func _apply()->void:
	var ship:=get_parent() as ShipMotor
	for k in ["ancient_armor_add","ancient_cannon_damage_mult","ancient_harpoon_damage_mult","ancient_speed_mult"]:ship.remove_meta(k)
	var mods:=item(equipped).get("modifiers",{}) as Dictionary
	for k in mods.keys():ship.set_meta("ancient_"+str(k),mods[k])
func export_state()->Dictionary:return {"owned":owned.duplicate(),"equipped":equipped}
func import_state(v:Dictionary)->void:
	owned.clear()
	for x in v.get("owned",[]):owned.append(str(x))
	equipped=str(v.get("equipped",""));_apply();changed.emit()

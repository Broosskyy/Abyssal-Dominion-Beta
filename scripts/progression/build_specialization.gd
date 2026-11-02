class_name BuildSpecialization
extends Node
signal changed
const PATH:="res://data/m114_build_specializations.json"
var selected:=""
func data()->Dictionary:
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH));return v if v is Dictionary else {}
func ids()->Array[String]:
	var out:Array[String]=[]
	for id in (data().get("profiles",{}) as Dictionary):out.append(str(id))
	return out
func profile(id:String)->Dictionary:return ((data().get("profiles",{}) as Dictionary).get(id,{}) as Dictionary).duplicate(true)
func can_select(map_level:int,inventory:PlayerInventory)->bool:return map_level>=int(data().get("unlock_level",21)) and inventory!=null and inventory.at_port()
func select(id:String,map_level:int,inventory:PlayerInventory)->bool:
	if not ids().has(id) or not can_select(map_level,inventory):return false
	selected=id;_apply_to_ship();changed.emit();return true
func _apply_to_ship()->void:
	var ship:=get_parent() as ShipMotor
	if ship==null:return
	for key in ["build_cannon_damage_mult","build_support_mult","build_damage_taken_mult","build_speed_mult","build_harpoon_damage_mult"]:ship.set_meta(key,1.0)
	var meta:=profile(selected).get("meta",{}) as Dictionary
	for key in meta:ship.set_meta("build_"+str(key),float(meta[key]))
	ship.set_meta("build_specialization",selected)
func summary()->String:
	if selected.is_empty():return "Keine Spezialisierung"
	var p:=profile(selected);return "%s · %s"%[str(p.get("label",selected)),str(p.get("focus",""))]
func export_state()->Dictionary:return {"selected":selected}
func import_state(v:Dictionary)->void:selected=str(v.get("selected",""));_apply_to_ship();changed.emit()

class_name AbyssCorruption
extends Node
signal changed
const PATH:="res://data/m115_corruption.json"
var value:=0.0
var retained:=false
func data()->Dictionary:
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH));return v if v is Dictionary else {}
func enabled(map_level:int)->bool:return map_level>=int(data().get("unlock_level",26))
func band()->Dictionary:
	for row in data().get("bands",[]):
		if value>=float(row.get("min",0)) and value<=float(row.get("max",100)):return row
	return {}
func gain(kind:String,map_level:int)->bool:
	if not enabled(map_level) or not retained:return false
	var g:=data().get("gain",{}) as Dictionary
	var amount:=float(g.get(kind,0.0))
	if amount<=0:return false
	value=clampf(value+amount,0.0,100.0);_apply();changed.emit();return true
func set_retained(on:bool,map_level:int)->bool:
	if not enabled(map_level):return false
	retained=on;_apply();changed.emit();return true
func cleanse(inventory:PlayerInventory)->bool:
	if inventory==null or not inventory.at_port():return false
	value=0.0;retained=false;_apply();changed.emit();return true
func reward_multiplier()->float:return float(band().get("reward_mult",1.0))
func _apply()->void:
	var ship:=get_parent() as ShipMotor
	if ship==null:return
	ship.set_meta("abyss_corruption",value);ship.set_meta("corruption_retained",retained)
	ship.set_meta("corruption_damage_taken_mult",float(band().get("damage_taken_mult",1.0)))
	ship.set_meta("corruption_reward_mult",reward_multiplier())
func summary()->String:return "Corruption %.0f%% · %s · Reward ×%.2f"%[value,"RETAIN" if retained else "CLEAN",reward_multiplier()]
func export_state()->Dictionary:return {"value":value,"retained":retained}
func import_state(v:Dictionary)->void:value=clampf(float(v.get("value",0)),0,100);retained=bool(v.get("retained",false));_apply();changed.emit()

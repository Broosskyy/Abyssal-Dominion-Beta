class_name ExtendedBonusMapProgress
extends Node
signal changed
@export var kind := "silver"
var active := false
var wave := 0
var wave_kills := 0
var completions := 0
var entry_receipt: Dictionary = {}

func config() -> Dictionary:
	var all: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/m154_bonusmap_expansion.json"))
	return ((all.get("maps", {}) as Dictionary).get(kind, {}) as Dictionary) if all is Dictionary else {}
func can_enter(map_level:int, inventory:PlayerInventory)->bool:
	var d:=config(); return not active and inventory!=null and inventory.at_port() and map_level>=int(d.get("eligibility_level",99)) and inventory.count(str(d.get("entry_item","")))>=int(d.get("entry_cost",999))
func enter(map_level:int, inventory:PlayerInventory)->bool:
	if not can_enter(map_level,inventory): return false
	var d:=config(); var item:=str(d.get("entry_item","")); var cost:=int(d.get("entry_cost",0))
	if not inventory.consume(item,cost): return false
	entry_receipt={"item":item,"amount":cost,"committed":false}; active=true; wave=1; wave_kills=0; changed.emit(); return true
func required_kills()->int:
	var rows:Array=config().get("kills_per_wave",[]); return int(rows[wave-1]) if active and wave>0 and wave<=rows.size() else 0
func record_sink(player:ShipMotor, encounter_kind:String)->Dictionary:
	if not active:return {}
	var rows:Array=config().get("waves",[]); if wave<1 or wave>rows.size():return {}
	var row:Dictionary=rows[wave-1]; var required:=str(row.get("kind","ship"))
	if required in ["admiral","guardian"] and encounter_kind!=required:return {"boss_required":true}
	wave_kills+=1
	if wave_kills<required_kills():changed.emit();return {"wave":wave,"kills":wave_kills,"required":required_kills()}
	if wave<rows.size():
		var done:=wave; wave+=1; wave_kills=0; _reward(player,done); changed.emit(); return {"wave_completed":done,"next_wave":wave}
	return _complete(player)
func _reward(player:ShipMotor,done:int)->void:
	var reward:=config().get("wave_reward",{}) as Dictionary
	(player.get_node("Progression") as PlayerProgression).add_coins(int(reward.get("coins_base",80))+done*int(reward.get("coins_per_wave",25)))
	(player.get_node("ShipRoster") as PlayerShipRoster).earn_ship_xp(int(reward.get("mastery_base",35))+done*int(reward.get("mastery_per_wave",15)))
func _complete(player:ShipMotor)->Dictionary:
	var d:=config().get("completion",{}) as Dictionary; var inv:=player.get_node("Inventory") as PlayerInventory
	(player.get_node("Progression") as PlayerProgression).add_coins(int(d.get("coins",0)))
	for item in (d.get("items",{}) as Dictionary): inv.set_count(str(item),inv.count(str(item))+int((d.get("items",{}) as Dictionary)[item]))
	completions+=1;active=false;wave=0;wave_kills=0;changed.emit();return {"completed":true,"kind":kind,"completions":completions}
func status_text()->String:
	var d:=config(); if not active:return "%s-BONUSMAP · %d %s · ab PL%d"%[kind.to_upper(),int(d.get("entry_cost",0)),str(d.get("entry_item","")).replace("_"," "),int(d.get("eligibility_level",0))]
	return "%s-BONUSMAP · WELLE %d/%d · %d/%d"%[kind.to_upper(),wave,(d.get("waves",[]) as Array).size(),wave_kills,required_kills()]
func commit_entry()->void:
	if not entry_receipt.is_empty():entry_receipt["committed"]=true
func rollback_entry(inventory:PlayerInventory)->void:
	if inventory!=null and not entry_receipt.is_empty() and not bool(entry_receipt.get("committed",false)):
		inventory.set_count(str(entry_receipt.item),inventory.count(str(entry_receipt.item))+int(entry_receipt.amount))
	entry_receipt={};active=false;wave=0;wave_kills=0;changed.emit()
func export_state()->Dictionary:
	return {
		"kind":kind,
		"active":active,
		"wave":wave,
		"wave_kills":wave_kills,
		"completions":completions
	}

func import_state(data:Dictionary)->void:
	var rows:Array=config().get("waves",[])
	completions=clampi(int(data.get("completions",0)),0,999999)
	active=bool(data.get("active",false)) and not rows.is_empty()
	wave=clampi(int(data.get("wave",1 if active else 0)),1,rows.size()) if active else 0
	var limit:=required_kills() if active else 0
	wave_kills=clampi(int(data.get("wave_kills",0)),0,maxi(0,limit-1)) if active else 0
	# Never restore an uncommitted entry receipt from disk; this prevents refund duplication.
	entry_receipt={}
	changed.emit()


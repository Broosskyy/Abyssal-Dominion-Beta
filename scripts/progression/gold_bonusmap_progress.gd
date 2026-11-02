class_name GoldBonusMapProgress
extends Node
signal changed
const CONTRACT:="res://data/m114_bonusmap_gold.json"
var active:=false
var wave:=0
var wave_kills:=0
var completions:=0
var pity_tokens:=0
var entry_receipt:Dictionary={}
var reentry_credit:=false
func data()->Dictionary:
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
	var fallback:Dictionary=v if v is Dictionary else {}
	var registry:=LiveConfigRegistry.current(get_tree())
	return registry.dictionary("rules.bonusmaps.gold",fallback) if registry!=null else fallback
func can_enter(map_level:int,inventory:PlayerInventory)->bool:
	var d:=data();return not active and map_level>=int(d.get("eligibility_level",18)) and inventory!=null and inventory.at_port() and inventory.count("gold_chart_fragment")>=int((d.get("entry",{}) as Dictionary).get("gold_chart_fragments",12))
func enter(map_level:int,inventory:PlayerInventory)->bool:
	if not can_enter(map_level,inventory):return false
	var cost:=int((data().get("entry",{}) as Dictionary).get("gold_chart_fragments",12))
	if reentry_credit:
		reentry_credit=false;active=true;wave=maxi(1,wave);wave_kills=maxi(0,wave_kills);entry_receipt={};changed.emit();return true
	if not inventory.consume("gold_chart_fragment",cost):return false
	entry_receipt={"item":"gold_chart_fragment","amount":cost,"committed":false}
	active=true;wave=1;wave_kills=0;changed.emit();return true
func required_kills()->int:
	var rows:=runtime_waves()
	return int((rows[wave-1] as Dictionary).get("count",1)) if active and wave>0 and wave<=rows.size() else 0

func runtime_waves()->Array:
	var dynamic:=DynamicContentResolver.by_id(get_tree(),"encounter","gold")
	if not dynamic.is_empty() and dynamic.get("waves",[]) is Array and not (dynamic.get("waves",[]) as Array).is_empty():
		return dynamic.get("waves",[]) as Array
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/m118_bonusmap_waves.json"))
	return parsed.get("gold",[]) as Array if parsed is Dictionary else []
func record_qualified_sink(player:ShipMotor,admiral:bool=false)->Dictionary:
	if not active:return {}
	wave_kills+=1
	if wave_kills<required_kills():changed.emit();return {"wave":wave,"kills":wave_kills,"required":required_kills()}
	var total:=runtime_waves().size()
	if wave>=total and not admiral:
		wave_kills=required_kills()-1;changed.emit();return {"wave":wave,"boss_required":true}
	if wave<total:
		var reward:=_wave_reward(player,wave);wave+=1;wave_kills=0;changed.emit();return reward
	return _complete(player)
func _wave_reward(player:ShipMotor,completed_wave:int)->Dictionary:
	var d:=data().get("wave_rewards",{}) as Dictionary
	var coins:Array=d.get("coins",[]);var mastery:Array=d.get("ship_mastery_xp",[])
	var coin:=int(coins[completed_wave-1]) if completed_wave<=coins.size() else 0
	var mxp:=int(mastery[completed_wave-1]) if completed_wave<=mastery.size() else 0
	(player.get_node("Progression") as PlayerProgression).add_coins(coin)
	var roster:=player.get_node("ShipRoster") as PlayerShipRoster
	roster.earn_ship_xp(mxp)
	return {"wave_completed":completed_wave,"coins":coin,"mastery_xp":mxp}
func _complete(player:ShipMotor)->Dictionary:
	var c:=data().get("completion",{}) as Dictionary
	var inv:=player.get_node("Inventory") as PlayerInventory
	(player.get_node("Progression") as PlayerProgression).add_coins(int(c.get("coins",0)))
	inv.set_count("gold_map_token",inv.count("gold_map_token")+int(c.get("gold_map_token",0)))
	inv.set_count("admiral_component",inv.count("admiral_component")+int(c.get("admiral_component",0)))
	pity_tokens+=int(c.get("pity_token",0));completions+=1
	active=false;wave=0;wave_kills=0;changed.emit()
	return {"completed":true,"coins":int(c.get("coins",0)),"pity_tokens":pity_tokens,"completions":completions}
func status_text()->String:
	if not active:return "GOLD-BONUSMAP · bereit über Fragmente ab PL18"
	return "GOLD-BONUSMAP · WELLE %d/%d · %d/%d"%[wave,runtime_waves().size(),wave_kills,required_kills()]
func export_state()->Dictionary:return {"active":active,"wave":wave,"wave_kills":wave_kills,"completions":completions,"pity_tokens":pity_tokens,"reentry_credit":reentry_credit or active}
func import_state(v:Dictionary)->void:
	var was_active:=bool(v.get("active",false));active=false;wave=clampi(int(v.get("wave",1 if was_active else 0)),0,maxi(1,runtime_waves().size()));wave_kills=maxi(0,int(v.get("wave_kills",0)));completions=maxi(0,int(v.get("completions",0)));pity_tokens=maxi(0,int(v.get("pity_tokens",0)));reentry_credit=bool(v.get("reentry_credit",false)) or was_active;entry_receipt={};changed.emit()

func commit_entry()->void:
	if not entry_receipt.is_empty():entry_receipt["committed"]=true
func rollback_entry(inventory:PlayerInventory)->void:
	if inventory!=null and not entry_receipt.is_empty() and not bool(entry_receipt.get("committed",false)):
		var item:=str(entry_receipt.get("item",""));var amount:=int(entry_receipt.get("amount",0))
		if not item.is_empty() and amount>0:inventory.set_count(item,inventory.count(item)+amount)
	entry_receipt={};active=false;wave=0;wave_kills=0;changed.emit()

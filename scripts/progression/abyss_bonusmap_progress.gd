class_name AbyssBonusMapProgress
extends Node
signal changed
const CONTRACT:="res://data/m115_bonusmap_abyss.json"
var active:=false
var wave:=0
var wave_kills:=0
var completions:=0
var guardian_clears:=0
var entry_receipt:Dictionary={}
var reentry_credit:=false
const KILLS:=[3,4,1,5,5,1] # compatibility fallback
func cfg(path:String,fallback:Variant)->Variant:return GameplayRuleset.rule_value(get_tree(),"bonusmaps.abyss."+path,fallback)
func runtime_waves()->Array:
	var dynamic:=DynamicContentResolver.by_id(get_tree(),"encounter","abyss")
	if not dynamic.is_empty() and dynamic.get("waves",[]) is Array and not (dynamic.get("waves",[]) as Array).is_empty():return dynamic.get("waves",[]) as Array
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/m118_bonusmap_waves.json"))
	return parsed.get("abyss",[]) as Array if parsed is Dictionary else []
func kills()->Array:
	var result:Array=[]
	for row in runtime_waves():result.append(int((row as Dictionary).get("count",1)))
	return result if not result.is_empty() else GameplayRuleset.array(get_tree(),"bonusmaps.abyss.kills_per_wave",KILLS)
func entry_item()->String:return str(cfg("entry_item","abyss_chart_fragment"))
func entry_cost()->int:return int(cfg("entry_cost",15))
func can_enter(map_level:int,inventory:PlayerInventory)->bool:
	return not active and map_level>=int(cfg("eligibility_level",26)) and inventory!=null and inventory.at_port() and inventory.count(entry_item())>=entry_cost()
func enter(map_level:int,inventory:PlayerInventory)->bool:
	if not can_enter(map_level,inventory):return false
	if reentry_credit:
		reentry_credit=false;active=true;wave=maxi(1,wave);wave_kills=maxi(0,wave_kills);entry_receipt={}
	elif inventory.consume(entry_item(),entry_cost()):
		entry_receipt={"item":entry_item(),"amount":entry_cost(),"committed":false};active=true;wave=1;wave_kills=0
	else:return false
	var ship:=get_parent() as ShipMotor;ship.set_meta("abyss_bonusmap_active",true);ship.set_meta("bonusmap_instance_id","abyss_local_"+str(Time.get_ticks_msec()))
	changed.emit();return true
func required_kind()->String:
	var rows:=runtime_waves()
	if wave>0 and wave<=rows.size():return "monster" if str((rows[wave-1] as Dictionary).get("kind","ship")) in ["monster","guardian"] else "ship"
	return "monster" if wave in GameplayRuleset.array(get_tree(),"bonusmaps.abyss.guardian_waves",[3,6]) else "ship"
func record_sink(player:ShipMotor,kind:String,guardian:bool=false)->Dictionary:
	if not active or kind!=required_kind():return {}
	var total:=kills().size()
	if wave==total and not guardian:return {"guardian_required":true}
	wave_kills+=1
	if wave_kills<kills()[wave-1]:changed.emit();return {"wave":wave,"kills":wave_kills,"required":kills()[wave-1]}
	if wave<total:
		var done:=wave;_reward_wave(player,done);wave+=1;wave_kills=0;changed.emit();return {"wave_completed":done,"next_wave":wave}
	return _complete(player)
func _reward_wave(player:ShipMotor,w:int)->void:
	var gold_formula:=GameplayRuleset.dictionary(get_tree(),"bonusmaps.abyss.wave_rewards.gold_formula",{"base":160,"per_wave":55})
	(player.get_node("Progression") as PlayerProgression).add_coins(int(gold_formula.get("base",160))+w*int(gold_formula.get("per_wave",55)))
	var mastery_formula:=GameplayRuleset.dictionary(get_tree(),"bonusmaps.abyss.wave_rewards.mastery_formula",{"base":90,"per_wave":25})
	(player.get_node("ShipRoster") as PlayerShipRoster).earn_ship_xp(int(mastery_formula.get("base",90))+w*int(mastery_formula.get("per_wave",25)))
func _complete(player:ShipMotor)->Dictionary:
	var inv:=player.get_node("Inventory") as PlayerInventory
	var completion:=GameplayRuleset.dictionary(get_tree(),"bonusmaps.abyss.completion",{"gold":1250,"items":{"abyss_scale":8,"corrupted_pearl":2}})
	var completion_gold:=int(completion.get("gold",1250))
	(player.get_node("Progression") as PlayerProgression).add_coins(completion_gold)
	for item_id in (completion.get("items",{}) as Dictionary):
		inv.set_count(str(item_id),inv.count(str(item_id))+int((completion.get("items",{}) as Dictionary)[item_id]))
	guardian_clears+=1;completions+=1;active=false;wave=0;wave_kills=0
	player.set_meta("abyss_bonusmap_active",false);player.set_meta("bonusmap_instance_id","")
	changed.emit();return {"completed":true,"coins":completion_gold,"items":completion.get("items",{}).duplicate(true)}
func status_text()->String:
	if not active:return "ABYSS-BONUSMAP · %d %s · ab PL%d"%[entry_cost(),entry_item(),int(cfg("eligibility_level",26))]
	return "ABYSS-BONUSMAP · WELLE %d/%d · %s · %d/%d"%[wave,kills().size(),required_kind().to_upper(),wave_kills,kills()[wave-1]]
func export_state()->Dictionary:return {"active":active,"wave":wave,"wave_kills":wave_kills,"completions":completions,"guardian_clears":guardian_clears,"reentry_credit":reentry_credit or active}
func import_state(v:Dictionary)->void:
	var was_active:=bool(v.get("active",false));active=false;wave=clampi(int(v.get("wave",1 if was_active else 0)),0,maxi(1,kills().size()));wave_kills=maxi(0,int(v.get("wave_kills",0)));completions=maxi(0,int(v.get("completions",0)));guardian_clears=maxi(0,int(v.get("guardian_clears",0)));reentry_credit=bool(v.get("reentry_credit",false)) or was_active;entry_receipt={}
	var ship:=get_parent() as ShipMotor;ship.set_meta("abyss_bonusmap_active",false);changed.emit()

func commit_entry()->void:
	if not entry_receipt.is_empty():entry_receipt["committed"]=true
func rollback_entry(inventory:PlayerInventory)->void:
	if inventory!=null and not entry_receipt.is_empty() and not bool(entry_receipt.get("committed",false)):
		var item:=str(entry_receipt.get("item",""));var amount:=int(entry_receipt.get("amount",0))
		if not item.is_empty() and amount>0:inventory.set_count(item,inventory.count(item)+amount)
	entry_receipt={};active=false;wave=0;wave_kills=0
	var ship:=get_parent() as ShipMotor;if ship!=null:ship.set_meta("abyss_bonusmap_active",false)
	changed.emit()

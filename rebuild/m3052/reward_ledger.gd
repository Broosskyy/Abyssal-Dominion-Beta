extends RefCounted
## Local beta ledger. Online rewards must use server time and transactions.
const MAX_AFK := 28800
const DAY := 86400
var last_seen := 0
var pending_seconds := 0
var last_claim_day := -1
var streak := 0
var high_water := 0
func restore(value: Variant,now: int=-1) -> void:
	if now<0:now=int(Time.get_unix_time_from_system())
	if not value is Dictionary:value={}
	last_seen=maxi(0,int(value.get("last_seen",0)))
	high_water=maxi(last_seen,int(value.get("high_water",0)))
	pending_seconds=clampi(int(value.get("pending_seconds",0)),0,MAX_AFK)
	if last_seen>0 and now>=high_water:pending_seconds=mini(MAX_AFK,pending_seconds+mini(MAX_AFK,now-last_seen))
	last_claim_day=int(value.get("last_claim_day",-1));streak=clampi(int(value.get("streak",0)),0,7)
	high_water=maxi(high_water,now);last_seen=high_water
func snapshot(now: int=-1) -> Dictionary:
	if now<0:now=int(Time.get_unix_time_from_system())
	high_water=maxi(high_water,now);last_seen=high_water
	return {"last_seen":last_seen,"high_water":high_water,"pending_seconds":pending_seconds,"last_claim_day":last_claim_day,"streak":streak}
func daily_available(now: int=-1) -> bool:
	if now<0:now=int(Time.get_unix_time_from_system())
	return now>=high_water and floori(float(now)/DAY)>last_claim_day
func claim_daily(s,now: int=-1) -> bool:
	if now<0:now=int(Time.get_unix_time_from_system())
	if not daily_available(now):return false
	var today: int=floori(float(now)/DAY)
	streak=(streak%7)+1 if last_claim_day==today-1 else 1
	last_claim_day=today;high_water=maxi(high_water,now)
	s.player.gold+=100+streak*50;s.essence+=1+(1 if streak==7 else 0)
	s.supplies.repair_kit+=1
	s.message="Tagesbonus %d/7 · +%d Gold · Essenz · Notreparatur" % [streak,100+streak*50]
	return true
func afk_gold() -> int:return floori(float(pending_seconds)/60.0)*3
func claim_afk(s) -> bool:
	var gold: int=afk_gold()
	if gold<=0:return false
	s.player.gold+=gold;s.player.ammo[0]+=floori(float(pending_seconds)/300.0)*10
	pending_seconds=0;s.message="AFK-Beute geborgen · +%d Gold" % gold
	return true

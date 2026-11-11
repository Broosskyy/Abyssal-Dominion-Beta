extends RefCounted
## Local beta events and data-driven creatures. Sprites can later be replaced by GLBs.
const MONSTERS := [
	{"key":"kraken","name":"Kraken · Tentakelwächter","hp":1250,"reward":180,"speed":23.0,"width":220.0},
	{"key":"serpent","name":"Nerissa · Panzerschlange","hp":980,"reward":145,"speed":32.0,"width":225.0},
	{"key":"crab","name":"Karapax · Tiefenpanzer","hp":1500,"reward":210,"speed":17.0,"width":195.0}
]
const EVENT_NAMES := {"halloween":"Halloween · Kürbisflut","columbus":"Columbus · Entdeckerfahrt","off":"Keine Veranstaltung"}
const EVENT_HUNTS := {"halloween":"Laternen-Korsar","columbus":"Nebel-Navigator"}
const EVENT_TRADES := {
	"pumpkin_ammo":{"event":"halloween","name":"10 Kürbiskugeln","cost":4,"ammo":4,"amount":10},
	"voyage_ammo":{"event":"columbus","name":"25 Vollkugeln","cost":4,"ammo":0,"amount":25}
}

# Reuse one existing patrol hull; event toggles never spawn, heal or resurrect it.
static func configure_event_hunt(s) -> void:
	for actor: Dictionary in s.npcs:
		if actor.has("event_base_name"):actor.name=actor.event_base_name
		actor.erase("event_key")
	if s.in_bonus_map() or not EVENT_HUNTS.has(s.event_mode):return
	var chosen: Dictionary={}
	for actor: Dictionary in s.npcs:
		if str(actor.kind)!="ship" or bool(actor.get("staff_spawn",false)) or bool(actor.get("wave",false)) or int(actor.id)<1 or int(actor.id)>16:continue
		if chosen.is_empty() or int(actor.id)>int(chosen.id):chosen=actor
	if chosen.is_empty():return
	if not chosen.has("event_base_name"):chosen["event_base_name"]=str(chosen.name)
	chosen["event_key"]=s.event_mode
	chosen.name="EVENT · %s · %s" % [EVENT_HUNTS[s.event_mode],s.CONTENT.MAPS[s.map_id].code]

static func event_target(s) -> Dictionary:
	for actor: Dictionary in s.npcs:
		if str(actor.get("event_key",""))==s.event_mode and EVENT_HUNTS.has(s.event_mode):return actor
	return {}

static func hunt_token_reward(s) -> int:
	return clampi(2+floori(float(s.CONTENT.MAPS[s.map_id].level)/5.0),2,5)

static func award_event_hunt(s,victim: Dictionary) -> void:
	var key: String=str(victim.get("event_key",""))
	if not EVENT_HUNTS.has(key) or key!=s.event_mode:return
	var amount: int=hunt_token_reward(s)
	s.event_tokens[key]=int(s.event_tokens.get(key,0))+amount
	s._event("event_loot",victim.pos,amount,0)
	s.events.back()["label"]="Eventjagd · +%d %s" % [amount,"Kürbiszeichen" if key=="halloween" else "Kompasszeichen"]

static func trade(s,key: String) -> bool:
	if not EVENT_TRADES.has(key) or s.staff.active():return false
	var offer: Dictionary=EVENT_TRADES[key]
	var currency: String=str(offer.event)
	if s.event_mode!=currency or int(s.event_tokens.get(currency,0))<int(offer.cost):return false
	s.event_tokens[currency]-=int(offer.cost)
	s.player.ammo[int(offer.ammo)]+=int(offer.amount)
	s.message="Eventtausch · "+str(offer.name)+" erhalten"
	return true

const EVENT_SKINS := {"halloween":12,"columbus":13}
const QUICK_DEFAULT := [["powder","plates","skyfire"],["repair_kit","healing_amulet","shield_charge"],["wind_draught","smoke_bomb","blessing_flask"]]

static func monster_specs() -> Array[Dictionary]:
	var result: Array[Dictionary]=[{"key":"tiamat","name":"Tiamat · Tiefenwächter"}]
	for spec: Dictionary in MONSTERS:result.append(spec.duplicate())
	return result

## Actual map roster, including the earliest returning creature when none is alive.
static func monster_hunt_info(s,key: String) -> Dictionary:
	if key!="tiamat" and not MONSTERS.any(func(spec):return str(spec.key)==key):return {"present":false,"alive":false,"id":-1}
	var found: Dictionary={}
	for actor: Dictionary in s.npcs:
		if str(actor.get("kind",""))!="monster" or bool(actor.get("staff_spawn",false)):continue
		if not ((key=="tiamat" and int(actor.id)==100) or (key!="tiamat" and str(actor.get("monster_key",""))==key)):continue
		if found.is_empty():found=actor;continue
		var alive: bool=int(actor.hp)>0
		var previous_alive: bool=int(found.hp)>0
		if alive and not previous_alive:found=actor
		elif alive and previous_alive and s.player.pos.distance_squared_to(Vector2(actor.pos))<s.player.pos.distance_squared_to(Vector2(found.pos)):found=actor
		elif not alive and not previous_alive and float(actor.get("respawn",0))<float(found.get("respawn",0)):found=actor
	if found.is_empty():return {"present":false,"alive":false,"id":-1}
	var alive: bool=int(found.hp)>0
	var damage: int=maxi(1,roundi(s.base_projectile_damage(found,2)))
	var required: int=ceili(float(int(found.hp)+int(found.get("shield",0)))/float(damage)) if alive else 0
	return {"present":true,"alive":alive,"id":int(found.id),"name":str(found.name),"hp":int(found.hp),"max_hp":int(found.max_hp),"distance":roundi(s.player.pos.distance_to(Vector2(found.pos))),"respawn":maxf(0,float(found.get("respawn",0))),"damage":damage,"required":required,"gold":0 if s.staff.active() else s.loot_gold(int(found.reward))}

static func spawn_monsters(s) -> void:
	for i in MONSTERS.size():
		var spec: Dictionary=MONSTERS[i]
		var body: Dictionary=s.base_npcs.back().duplicate(true)
		var site: Vector2=s._free_water(s._map_point([Vector2(740,600),Vector2(3000,800),Vector2(3100,2480)][i]))
		body.merge({"id":110+i,"name":spec.name,"kind":"monster","monster_key":spec.key,"pos":site,"home":site,"path":[],"hp":roundi(spec.hp*float(s.CONTENT.MAPS[s.map_id].enemy_scale)),"max_hp":roundi(spec.hp*float(s.CONTENT.MAPS[s.map_id].enemy_scale)),"shield":0,"max_shield":0,"reward":spec.reward,"speed":spec.speed,"aggressive":false},true)
		s.npcs.append(body)

static func spawn_collectibles(s) -> void:
	s.event_pickups.clear()
	if s.in_bonus_map() or s.event_mode=="off":return
	for i in 7:
		s.next_id+=1
		s.event_pickups.append({"id":s.next_id,"pos":s._sparkle_point(),"respawn":0.0,"event":s.event_mode})

static func collect(s,delta: float) -> void:
	for pickup: Dictionary in s.event_pickups:
		pickup.respawn=maxf(0.0,float(pickup.respawn)-delta)
		if float(pickup.respawn)>0 or s.player.pos.distance_to(pickup.pos)>72:continue
		else:
			var key: String=str(pickup.event)
			s.event_tokens[key]=int(s.event_tokens.get(key,0))+1
			s.player.gold+=30
			var item: String="skyfire" if key=="halloween" else "healing_amulet"
			s.supplies[item]+=1
			s._event("event_loot",pickup.pos,1,0)
			s.events.back()["label"]="+1 %s · +30 Gold · +1 %s" % ["Kürbiszeichen" if key=="halloween" else "Kompasszeichen",s.CONTENT.SUPPLIES[item].name]
			s.message=s.events.back().label
			pickup.respawn=120.0

static func set_event(s,key: String) -> bool:
	if not EVENT_NAMES.has(key):return false
	s.event_mode=key
	spawn_collectibles(s)
	configure_event_hunt(s)
	s.message=EVENT_NAMES[key]+" · Beta-Testmodus"
	return true

static func normalize_quick(raw: Variant) -> Array:
	var pages: Array=QUICK_DEFAULT.duplicate(true)
	if raw is Array:
		for page in mini(3,raw.size()):
			if not raw[page] is Array:continue
			for slot in mini(3,raw[page].size()):
				var key: String=str(raw[page][slot])
				if key in preload("res://content.gd").SUPPLY_KEYS:pages[page][slot]=key
	return pages

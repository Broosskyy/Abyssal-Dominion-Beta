extends RefCounted
## Local beta events and data-driven creatures. Sprites can later be replaced by GLBs.
const MONSTERS := [
	{"key":"kraken","name":"Kraken · Tentakelwächter","hp":1250,"reward":180,"speed":23.0,"width":220.0},
	{"key":"serpent","name":"Nerissa · Panzerschlange","hp":980,"reward":145,"speed":32.0,"width":225.0},
	{"key":"crab","name":"Karapax · Tiefenpanzer","hp":1500,"reward":210,"speed":17.0,"width":195.0}
]
const EVENT_NAMES := {"halloween":"Halloween · Kürbisflut","columbus":"Columbus · Entdeckerfahrt","off":"Keine Veranstaltung"}
const EVENT_SKINS := {"halloween":12,"columbus":13}
const QUICK_DEFAULT := [["powder","plates","skyfire"],["repair_kit","healing_amulet","shield_charge"],["wind_draught","smoke_bomb","blessing_flask"]]

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

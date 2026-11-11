extends RefCounted
## M3075 Meshy ship render pack: original textures, four mobile-friendly angles.
const NPC_MESHY_ROSTER := [
	{"key":"old_harbor_trader","name":"Küstenhändler","role":"Küstenhandel","hp":360,"shield":0,"speed":39.0,"power":15,"reward":45,"elite":false},
	{"key":"merchant_brig_3002","name":"Versorgungsbrigg","role":"Nachschub","hp":420,"shield":0,"speed":40.0,"power":20,"reward":55,"elite":false},
	{"key":"merchant_brig_2921","name":"Geleitbrigg","role":"Konvoischutz","hp":480,"shield":80,"speed":38.0,"power":24,"reward":65,"elite":false},
	{"key":"merchant_brig_2912","name":"Schmugglerbrigg","role":"Schmuggler","hp":520,"shield":0,"speed":43.0,"power":26,"reward":70,"elite":false},
	{"key":"weathered_voyager","name":"Fernsegler","role":"Fernhandel","hp":540,"shield":90,"speed":41.0,"power":25,"reward":75,"elite":false},
	{"key":"weathered_junk","name":"Ostwind-Dschunke","role":"Spezialschiff","hp":590,"shield":100,"speed":38.0,"power":28,"reward":80,"elite":false},
	{"key":"emerald_voyager","name":"Smaragdsegler","role":"Elite-Konvoi","hp":700,"shield":170,"speed":43.0,"power":34,"reward":105,"elite":true},
	{"key":"midnight_mariner","name":"Nachtmariner","role":"Elite-Jäger","hp":850,"shield":230,"speed":46.0,"power":43,"reward":135,"elite":true},
	{"key":"crimson_tide_galley","name":"Blutflut-Galeere","role":"Elite-Galeere","hp":1000,"shield":300,"speed":42.0,"power":50,"reward":155,"elite":true},
]
## Reuse existing sixteen fixed spawn IDs and locations.
const NPC_MESHY_ASSIGNMENTS := [0,1,2,3,8,4,5,1,2,7,4,3,6,2,0,5]
const MONSTER_COLUMNS := 4
const MONSTER_ROWS := 10
## Visible hull sizes follow the ship design, independent of combat/elite rank.
## Catalog order: redkorsar, elite2..7, elite9..10, boneship, dutchman,
## blackbeard, elite8, warship, pinnace, flyingdutchman.
const SHIP_LENGTHS := [144.0,136.0,136.0,144.0,156.0,144.0,144.0,156.0,156.0,144.0,156.0,156.0,156.0,156.0,92.0,156.0]
## Authored gameplay data, separate from simulation and presentation.
## Regions 0-2 are linked by portals. Bonus maps are separate instances opened with a scroll.
const MAPS := [
	{"name":"Karibische See", "code":"1/1", "tier":1, "lane":1, "level":1, "art":["tropical","rock","tropical","tropical","rock","tropical","tropical","rock","tropical"], "tint":Color(0.75,1.14,1.12), "npc_hostile":false, "enemy_scale":1.0},
	{"name":"Nordmeer", "code":"2/1", "tier":2, "lane":1, "level":2, "art":["snow2","snow","snow2","snow","rock","snow2","snow","rock","snow2"], "tint":Color(0.78,0.98,1.32), "npc_hostile":false, "enemy_scale":1.5},
	{"name":"Schattengewässer", "code":"3/1", "tier":3, "lane":1, "level":4, "art":["rock","rock","snow2","rock","rock","snow","rock","rock","snow2"], "tint":Color(0.90,0.68,1.02), "npc_hostile":true, "enemy_scale":2.2},
	{"name":"Bronzeriff", "code":"B-1", "level":2, "art":["tropical","rock","tropical","rock","tropical"], "tint":Color(1.08,0.96,0.80), "npc_hostile":true, "enemy_scale":1.2, "bonus":true},
	{"name":"Silberbucht", "code":"B-2", "level":5, "art":["snow2","rock","snow","rock","snow2"], "tint":Color(0.92,1.04,1.18), "npc_hostile":true, "enemy_scale":1.9, "bonus":true},
	{"name":"Goldene Lagune", "code":"B-3", "level":8, "art":["tropical","tropical","rock","tropical","rock"], "tint":Color(1.16,1.02,0.72), "npc_hostile":true, "enemy_scale":2.8, "bonus":true},
	{"name":"Freibeuterküste", "code":"1/2", "level":1, "art":["rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock"], "tint":Color(0.85,0.92,1.20), "npc_hostile":false, "enemy_scale":1.12, "tier":1, "lane":2},
	{"name":"Freibeuterküste", "code":"2/2", "level":2, "art":["rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock"], "tint":Color(0.93,0.79,1.06), "npc_hostile":false, "enemy_scale":1.42, "tier":2, "lane":2},
	{"name":"Freibeuterküste", "code":"3/2", "level":3, "art":["rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock"], "tint":Color(0.75,1.10,1.12), "npc_hostile":false, "enemy_scale":1.72, "tier":3, "lane":2},
	{"name":"Freibeuterküste", "code":"4/1", "level":4, "art":["rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock"], "tint":Color(0.85,0.92,1.20), "npc_hostile":true, "enemy_scale":1.90, "tier":4, "lane":1},
	{"name":"Freibeuterküste", "code":"4/2", "level":4, "art":["rock", "snow2", "snow2", "rock", "snow2", "snow2", "rock", "snow2", "snow2"], "tint":Color(0.85,0.92,1.20), "npc_hostile":true, "enemy_scale":2.02, "tier":4, "lane":2},
	{"name":"Nebelpassage", "code":"5/1", "level":5, "art":["rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock"], "tint":Color(0.93,0.79,1.06), "npc_hostile":true, "enemy_scale":2.20, "tier":5, "lane":1},
	{"name":"Nebelpassage", "code":"5/2", "level":5, "art":["rock", "snow2", "snow2", "rock", "snow2", "snow2", "rock", "snow2", "snow2"], "tint":Color(0.93,0.79,1.06), "npc_hostile":true, "enemy_scale":2.32, "tier":5, "lane":2},
	{"name":"Nebelpassage", "code":"6/1", "level":6, "art":["rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock"], "tint":Color(0.75,1.10,1.12), "npc_hostile":true, "enemy_scale":2.50, "tier":6, "lane":1},
	{"name":"Nebelpassage", "code":"6/2", "level":6, "art":["rock", "snow2", "snow2", "rock", "snow2", "snow2", "rock", "snow2", "snow2"], "tint":Color(0.75,1.10,1.12), "npc_hostile":true, "enemy_scale":2.62, "tier":6, "lane":2},
	{"name":"Nebelpassage", "code":"7/1", "level":7, "art":["rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock"], "tint":Color(0.85,0.92,1.20), "npc_hostile":true, "enemy_scale":2.80, "tier":7, "lane":1},
	{"name":"Nebelpassage", "code":"7/2", "level":7, "art":["rock", "snow2", "snow2", "rock", "snow2", "snow2", "rock", "snow2", "snow2"], "tint":Color(0.85,0.92,1.20), "npc_hostile":true, "enemy_scale":2.92, "tier":7, "lane":2},
	{"name":"Nebelpassage", "code":"8/1", "level":8, "art":["rock", "snow2", "snow2", "rock", "snow2", "snow2", "rock", "snow2", "snow2"], "tint":Color(0.93,0.79,1.06), "npc_hostile":true, "enemy_scale":3.10, "tier":8, "lane":1},
	{"name":"Nebelpassage", "code":"8/2", "level":8, "art":["rock", "snow", "snow", "rock", "snow", "snow", "rock", "snow", "snow"], "tint":Color(0.93,0.79,1.06), "npc_hostile":true, "enemy_scale":3.22, "tier":8, "lane":2},
	{"name":"Korallenmeer", "code":"9/1", "level":9, "art":["rock", "snow2", "snow2", "rock", "snow2", "snow2", "rock", "snow2", "snow2"], "tint":Color(0.75,1.10,1.12), "npc_hostile":true, "enemy_scale":3.40, "tier":9, "lane":1},
	{"name":"Korallenmeer", "code":"9/2", "level":9, "art":["rock", "snow", "snow", "rock", "snow", "snow", "rock", "snow", "snow"], "tint":Color(0.75,1.10,1.12), "npc_hostile":true, "enemy_scale":3.52, "tier":9, "lane":2},
	{"name":"Korallenmeer", "code":"10/1", "level":10, "art":["rock", "snow2", "snow2", "rock", "snow2", "snow2", "rock", "snow2", "snow2"], "tint":Color(0.85,0.92,1.20), "npc_hostile":true, "enemy_scale":3.70, "tier":10, "lane":1},
	{"name":"Korallenmeer", "code":"10/2", "level":10, "art":["rock", "snow", "snow", "rock", "snow", "snow", "rock", "snow", "snow"], "tint":Color(0.85,0.92,1.20), "npc_hostile":true, "enemy_scale":3.82, "tier":10, "lane":2},
	{"name":"Korallenmeer", "code":"11/1", "level":11, "art":["rock", "snow2", "snow2", "rock", "snow2", "snow2", "rock", "snow2", "snow2"], "tint":Color(0.93,0.79,1.06), "npc_hostile":true, "enemy_scale":4.00, "tier":11, "lane":1},
	{"name":"Korallenmeer", "code":"11/2", "level":11, "art":["rock", "snow", "snow", "rock", "snow", "snow", "rock", "snow", "snow"], "tint":Color(0.93,0.79,1.06), "npc_hostile":true, "enemy_scale":4.12, "tier":11, "lane":2},
	{"name":"Korallenmeer", "code":"12/1", "level":12, "art":["rock", "snow", "snow", "rock", "snow", "snow", "rock", "snow", "snow"], "tint":Color(0.75,1.10,1.12), "npc_hostile":true, "enemy_scale":4.30, "tier":12, "lane":1},
	{"name":"Korallenmeer", "code":"12/2", "level":12, "art":["rock", "tropical", "tropical", "rock", "tropical", "tropical", "rock", "tropical", "tropical"], "tint":Color(0.75,1.10,1.12), "npc_hostile":true, "enemy_scale":4.42, "tier":12, "lane":2},
	{"name":"Sturmsee", "code":"13/1", "level":13, "art":["rock", "snow", "snow", "rock", "snow", "snow", "rock", "snow", "snow"], "tint":Color(0.85,0.92,1.20), "npc_hostile":true, "enemy_scale":4.60, "tier":13, "lane":1},
	{"name":"Sturmsee", "code":"13/2", "level":13, "art":["rock", "tropical", "tropical", "rock", "tropical", "tropical", "rock", "tropical", "tropical"], "tint":Color(0.85,0.92,1.20), "npc_hostile":true, "enemy_scale":4.72, "tier":13, "lane":2},
	{"name":"Sturmsee", "code":"14/1", "level":14, "art":["rock", "snow", "snow", "rock", "snow", "snow", "rock", "snow", "snow"], "tint":Color(0.93,0.79,1.06), "npc_hostile":true, "enemy_scale":4.90, "tier":14, "lane":1},
	{"name":"Sturmsee", "code":"14/2", "level":14, "art":["rock", "tropical", "tropical", "rock", "tropical", "tropical", "rock", "tropical", "tropical"], "tint":Color(0.93,0.79,1.06), "npc_hostile":true, "enemy_scale":5.02, "tier":14, "lane":2},
	{"name":"Sturmsee", "code":"15/1", "level":15, "art":["rock", "snow", "snow", "rock", "snow", "snow", "rock", "snow", "snow"], "tint":Color(0.75,1.10,1.12), "npc_hostile":true, "enemy_scale":5.20, "tier":15, "lane":1},
	{"name":"Sturmsee", "code":"15/2", "level":15, "art":["rock", "tropical", "tropical", "rock", "tropical", "tropical", "rock", "tropical", "tropical"], "tint":Color(0.75,1.10,1.12), "npc_hostile":true, "enemy_scale":5.32, "tier":15, "lane":2},
	{"name":"Sturmsee", "code":"16/1", "level":16, "art":["rock", "tropical", "tropical", "rock", "tropical", "tropical", "rock", "tropical", "tropical"], "tint":Color(0.85,0.92,1.20), "npc_hostile":true, "enemy_scale":5.50, "tier":16, "lane":1},
	{"name":"Sturmsee", "code":"16/2", "level":16, "art":["rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock"], "tint":Color(0.85,0.92,1.20), "npc_hostile":true, "enemy_scale":5.62, "tier":16, "lane":2},
	{"name":"Tiefenreich", "code":"17/1", "level":17, "art":["rock", "tropical", "tropical", "rock", "tropical", "tropical", "rock", "tropical", "tropical"], "tint":Color(0.93,0.79,1.06), "npc_hostile":true, "enemy_scale":5.80, "tier":17, "lane":1},
	{"name":"Tiefenreich", "code":"17/2", "level":17, "art":["rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock"], "tint":Color(0.93,0.79,1.06), "npc_hostile":true, "enemy_scale":5.92, "tier":17, "lane":2},
	{"name":"Tiefenreich", "code":"18/1", "level":18, "art":["rock", "tropical", "tropical", "rock", "tropical", "tropical", "rock", "tropical", "tropical"], "tint":Color(0.75,1.10,1.12), "npc_hostile":true, "enemy_scale":6.10, "tier":18, "lane":1},
	{"name":"Tiefenreich", "code":"18/2", "level":18, "art":["rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock"], "tint":Color(0.75,1.10,1.12), "npc_hostile":true, "enemy_scale":6.22, "tier":18, "lane":2},
	{"name":"Tiefenreich", "code":"19/1", "level":19, "art":["rock", "tropical", "tropical", "rock", "tropical", "tropical", "rock", "tropical", "tropical"], "tint":Color(0.85,0.92,1.20), "npc_hostile":true, "enemy_scale":6.40, "tier":19, "lane":1},
	{"name":"Tiefenreich", "code":"19/2", "level":19, "art":["rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock"], "tint":Color(0.85,0.92,1.20), "npc_hostile":true, "enemy_scale":6.52, "tier":19, "lane":2},
	{"name":"Tiefenreich", "code":"20/1", "level":20, "art":["rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock", "rock"], "tint":Color(0.93,0.79,1.06), "npc_hostile":true, "enemy_scale":6.70, "tier":20, "lane":1},
	{"name":"Tiefenreich", "code":"20/2", "level":20, "art":["rock", "snow2", "snow2", "rock", "snow2", "snow2", "rock", "snow2", "snow2"], "tint":Color(0.93,0.79,1.06), "npc_hostile":true, "enemy_scale":6.82, "tier":20, "lane":2}
]
# The original bonus ids 3..5 are deliberately reserved forever.
const REGION_COUNT := 3
const SEA_MAP_IDS := [0, 6, 1, 7, 2, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42]
const SEA_MAP_COUNT := 40

static func sea_index(tier: int,lane: int) -> int:
	if tier<1 or tier>20 or lane<1 or lane>2:return -1
	return int(SEA_MAP_IDS[(tier-1)*2+lane-1])

static func sea_neighbors(index: int) -> Array[int]:
	if not index in SEA_MAP_IDS:return []
	var config: Dictionary=MAPS[index]
	var tier: int=int(config.get("tier",index+1))
	var lane: int=int(config.get("lane",1))
	var result: Array[int]=[]
	# East/west progress through the same lane; north/south crosses to the paired sea.
	if tier<20:result.append(sea_index(tier+1,lane))
	if tier>1:result.append(sea_index(tier-1,lane))
	result.append(sea_index(tier,3-lane))
	return result

# Spatial adjacency shared by the sea, minimap and crossing simulation.
static func sea_edge_neighbor(index: int, edge: String) -> int:
	if not index in SEA_MAP_IDS:return -1
	var region: Dictionary=MAPS[index]
	var tier: int=int(region.tier)
	var lane: int=int(region.lane)
	match edge:
		"east":return sea_index(tier+1,lane)
		"west":return sea_index(tier-1,lane)
		"south":return sea_index(tier,2) if lane==1 else -1
		"north":return sea_index(tier,1) if lane==2 else -1
	return -1

static func next_sea_on_route(origin: int,destination: int) -> int:
	if not origin in SEA_MAP_IDS or not destination in SEA_MAP_IDS:return -1
	var queue: Array[int]=[origin]
	var previous: Dictionary={origin:-1}
	while not queue.is_empty():
		var at: int=queue.pop_front()
		if at==destination:break
		for neighbor in sea_neighbors(at):
			if not previous.has(neighbor):previous[neighbor]=at;queue.append(neighbor)
	if not previous.has(destination) or origin==destination:return -1
	var step: int=destination
	while int(previous[step])!=origin:step=int(previous[step])
	return step

const BONUS_ISLANDS := [0,2,3,6,7]
const BONUS_ISLAND_NAMES := [["Bronzefels","Muschelbank","Kupferklippe","Sandwacht","Rostriff"],["Silberfels","Perlenbank","Nebelklippe","Mondwacht","Eisriff"],["Goldfels","Kronenbank","Sonnenklippe","Schatzwacht","Bernsteinriff"]]
## Kastelle: permanent harbor investments. Levels 1-3 keep the original equipment effects.
const UPGRADE_KEYS := ["cannon","hull","sails","crew","harpoon","war"]
const CASTLE_MAX := 8
const CASTLE_COSTS := [150,400,850,1500,2400,3600,5200,7200]
const UPGRADES := {
	"cannon":{"name":"Bugkastell", "role":"Geschützkunst", "icon":"upgrade_cannon", "effect":"+25 % Kugelschaden je Stufe"},
	"hull":{"name":"Heckkastell", "role":"Schiffbau", "icon":"upgrade_hull", "effect":"+400 Rumpf und +120 Schild je Stufe"},
	"sails":{"name":"Mastkastell", "role":"Navigation", "icon":"upgrade_sails", "effect":"+12 % Fahrt je Stufe"},
	"crew":{"name":"Mannschaftskastell", "role":"Logistik", "icon":"castle_crew", "effect":"−4 % Nachladezeit und +8 % Beutegold je Stufe"},
	"harpoon":{"name":"Jagdkastell", "role":"Monsterjagd", "icon":"upgrade_harpoon", "effect":"+35 % Harpunenschaden je Stufe"},
	"war":{"name":"Kriegskastell", "role":"Kriegsführung", "icon":"castle_war", "effect":"+10 % Schaden gegen Elite, Bosse und Türme je Stufe"}
}
# Free seasonal track is playable offline; the paid track stays locked until
# account-bound entitlements and receipt verification exist server-side.
const BATTLE_PASS_FREE := [
	{"need":0,"name":"Leichte Proviantkiste","gold":100,"essence":0},
	{"need":50,"name":"Küstenschatz","gold":200,"essence":1},
	{"need":150,"name":"Kapitänsreserve","gold":300,"essence":2},
	{"need":350,"name":"Seefahrertruhe","gold":500,"essence":3},
	{"need":700,"name":"Admiralskiste","gold":800,"essence":5}
]
const TALENT_KEYS := ["gunnery","armor","navigation"]
const TALENT_MAX := 5
const TALENTS := {
	"gunnery":{"name":"Schießkunst","effect":"+2 % Kanonenschaden je Punkt","role":"Kampf","icon":"upgrade_cannon"},
	"armor":{"name":"Rumpfkunde","effect":"+2 % maximale Rumpfpunkte je Punkt","role":"Verteidigung","icon":"upgrade_hull"},
	"navigation":{"name":"Seefahrtskunst","effect":"+2 % Fahrt je Punkt","role":"Navigation","icon":"upgrade_sails"}
}
const QUESTS := [
	{"name":"Küstenwache", "description":"Versenke 3 Gegner", "stat":"kills", "goal":3, "gold":180, "xp":120, "essence":2},
	{"name":"Bergung auf See", "description":"Sammle 3 Beutekisten", "stat":"loot", "goal":3, "gold":140, "xp":100, "essence":2},
	{"name":"Jäger der Tiefe", "description":"Besiege ein Seeungeheuer mit Harpunen", "stat":"monsters", "goal":1, "gold":300, "xp":180, "essence":3},
	{"name":"Kurs nach Norden", "description":"Erreiche das Nordmeer durch ein Portal", "stat":"north", "goal":1, "gold":220, "xp":150, "essence":2},
	{"name":"Admiralsjagd", "description":"Versenke 3 Elite-Schiffe", "stat":"elites", "goal":3, "gold":400, "xp":220, "essence":3},
	{"name":"Hinter dem Nebel", "description":"Erreiche die Schattengewässer", "stat":"abyss", "goal":1, "gold":500, "xp":260, "essence":3},
	{"name":"Herr der Meere", "description":"Versenke insgesamt 20 Gegner", "stat":"kills", "goal":20, "gold":800, "xp":400, "essence":5}
]
## Consumable ship supplies. Toggles are spent only by a valid salvo or a received hit.
const SUPPLY_KEYS := ["powder","plates","repair_kit","shield_charge","wind_draught","smoke_bomb","cleansing_rum","salvage_charm","skyfire","healing_amulet","blessing_flask"]
const SUPPLIES := {
	"skyfire":{"name":"Himmelsbrand","short":"RAKETE","icon":"supply_skyfire","toggle":false,"effect":"Extrakapsel gegen Schiffe · 240 Schaden · 650 m · 35 s Abklingzeit","price":160,"pack":1,"cooldown":35.0},
	"healing_amulet":{"name":"Lebensamulett","short":"AMULETT","icon":"supply_healing","toggle":false,"effect":"+25 % Rumpf sofort · 55 s Abklingzeit","price":140,"pack":1,"cooldown":55.0},
	"blessing_flask":{"name":"Segen der Tiefe","short":"SEGEN","icon":"blessing","toggle":false,"effect":"+20 % Rumpf und 2 Minuten Kristallsegen · 120 s Abklingzeit","price":220,"pack":1,"cooldown":120.0},
	"powder":{"name":"Schwarzpulver", "short":"PULVER", "icon":"supply_powder", "toggle":true, "effect":"+40 % Salvenschaden · 1 je gültiger Salve", "price":60, "pack":10},
	"plates":{"name":"Panzerplatten", "short":"PLATTEN", "icon":"supply_plates", "toggle":true, "effect":"−35 % erlittener Schaden · 1 je Treffer", "price":60, "pack":10},
	"repair_kit":{"name":"Notreparatur", "short":"NOTREP", "icon":"supply_repair", "toggle":false, "effect":"+35 % Rumpf sofort · 45 s Abklingzeit", "price":90, "pack":1, "cooldown":45.0},
	"shield_charge":{"name":"Schildladung", "short":"SCHILD", "icon":"supply_shield", "toggle":false, "effect":"+50 % Schild sofort · 40 s Abklingzeit", "price":90, "pack":1, "cooldown":40.0},
	"wind_draught":{"name":"Windtrank","short":"WIND","icon":"supply_wind","toggle":false,"effect":"+25 % Fahrt für 20 s · 60 s Abklingzeit","price":110,"pack":1,"cooldown":60.0},
	"smoke_bomb":{"name":"Nebelbombe","short":"NEBEL","icon":"supply_smoke","toggle":false,"effect":"−30 % erlittener Schaden für 8 s · 60 s Abklingzeit","price":140,"pack":1,"cooldown":60.0},
	"cleansing_rum":{"name":"Befreiungsrum","short":"RUM","icon":"supply_rum","toggle":false,"effect":"Entfernt Verlangsamung · 35 s Abklingzeit","price":80,"pack":1,"cooldown":35.0},
	"salvage_charm":{"name":"Bergungsamulett","short":"BERGUNG","icon":"supply_charm","toggle":false,"effect":"+20 % Beutegold für 60 s · 120 s Abklingzeit","price":150,"pack":1,"cooldown":120.0}
}
## Exactly ten identical, independently upgraded standard decks. Each can
## be Gold, Pearls or Crystal at level I-V. The +cannon balance is PROVISIONAL
## until real ship/cannon values are agreed; never present it as final.
const DECK_SLOT_COUNT := 10
const DECK_INVENTORY_MAX := 30
const DECK_KEYS := ["cannon"]
const DECK_LEGACY_TYPES := ["cannon","armor","hunter","navigation","logistics"]
const DECK_STAGE_MAX := 5
const DECK_TIERS := ["Gold","Perlen","Kristall"]
const DECK_TIER_COLORS := [Color("ffb640"),Color("81d9e4"),Color("bd78f2")]
const DECK_CANNON_BASE := [0,5,15]
## Provisional flat Rumpf-HP per physical standard deck. Each material's
## five stages strictly increase; the next material starts ABOVE rank V.
## Gold: +40–200, Perlen: +250–450, Kristall: +520–800 HP per deck.
const DECK_HP_BASE := [0,200,450]
const DECK_HP_PER_STAGE := [40,50,70]
const DECK_UPGRADE_GOLD := [180,540,1200]
const DECK_UPGRADE_ESSENCE := [0,1,3]
const DECK_UPGRADE_LEVEL := [1,3,8]
const DECKS := {
	"cannon":{"name":"Standarddeck", "effect":"+%d Kanonenplätze", "price":600}
}
## Three independent, temporary side decks. They never replace one of
## the 10 physical deck slots. Persist the historical buff keys so older
## signed mobile saves keep their timers across the upgrade.
const SPECIAL_DECKS := {
	"storm_deck":{"name":"Runendeck","effect":"+12 % Fahrt · Kessel-Fund","price":0,"seconds":1800.0,"level":3,"source":"kessel","icon":"helm_wheel","color":Color("80bdff")},
	"salvage_deck":{"name":"Korsarendeck","effect":"+15 % Beutegold","price":900,"seconds":1800.0,"level":3,"source":"market","icon":"reward_chest","color":Color("edc36a")}
}
## Gezeitenkessel: every essence thrown pays from this public pool (weights total 100).
const KESSEL_POOL := [
	{"id":"fragment", "name":"Schriftrollenfragment", "amount":1, "weight":24, "rarity":0},
	{"id":"ammo0", "name":"Vollkugeln", "amount":150, "weight":15, "rarity":0},
	{"id":"ammo2", "name":"Harpunen", "amount":30, "weight":8, "rarity":0},
	{"id":"powder", "name":"Schwarzpulver", "amount":5, "weight":12, "rarity":0},
	{"id":"plates", "name":"Panzerplatten", "amount":5, "weight":12, "rarity":0},
	{"id":"gold", "name":"Gold", "amount":150, "weight":9, "rarity":0},
	{"id":"repair_kit", "name":"Notreparatur", "amount":1, "weight":6, "rarity":1},
	{"id":"shield_charge", "name":"Schildladung", "amount":1, "weight":6, "rarity":1},
	{"id":"essence", "name":"Gezeitenessenz", "amount":2, "weight":3, "rarity":1},
	{"id":"tide_deck", "name":"Gezeitendeck 30 min", "amount":1800, "weight":2, "rarity":2},
	{"id":"storm_deck", "name":"Runendeck 30 min", "amount":1800, "weight":2, "rarity":2},
	{"id":"deck", "name":"Zufälliges Deck I", "amount":0, "weight":1, "rarity":3}
]
const RARITIES := ["Häufig","Selten","Episch","Legendär"]
const KESSEL_THROWS := [1,5,10,25]
const KESSEL_CYCLE := 100
const KESSEL_MILESTONES := [
	{"at":10, "id":"repair_kit", "name":"2 Notreparaturen", "amount":2},
	{"at":25, "id":"scroll0", "name":"Bronze-Schriftrolle", "amount":1},
	{"at":50, "id":"tide_deck", "name":"Gezeitendeck 60 min", "amount":3600},
	{"at":100, "id":"deck_cannon_1", "name":"Perlendeck Stufe I", "amount":1}
]
const DUPLICATE_DECK_ESSENCE := 3
## Bonus maps: scroll tiers, level gates and the five-wave structure.
const BONUS_TIERS := [
	{"name":"Bronze", "level":2, "fragments":5, "map":3},
	{"name":"Silber", "level":5, "fragments":10, "map":4},
	{"name":"Gold", "level":8, "fragments":16, "map":5}
]
const BONUS_WAVES := [
	{"label":"Eröffnung", "ships":3, "elites":0, "boss":""},
	{"label":"Druck", "ships":5, "elites":0, "boss":""},
	{"label":"Elite", "ships":2, "elites":2, "boss":""},
	{"label":"Admiral", "ships":2, "elites":0, "boss":"admiral"},
	{"label":"Leviathan", "ships":0, "elites":0, "boss":"monster"}
]
## Kristallsegen: one major blessing at a time, counted in sea time.
const BLESSING_SECONDS := 900.0
const TIDE_DECK_CAP := 14400.0
## Twelve physical defenses anchored to the island fortress.
## Indices 0–9 retain the first ten turret upgrade slots; 10–11 are new.
const FORTRESS_MAP := 2
const FORTRESS_ISLAND := 4
const FORTRESS_TAG := "KRF"
const FORTRESS_HOLD := 1800.0
const GUILD_ISLAND_SCALE := 2.65
const GUILD_FORTRESS_ASPECT := 790.0/1024.0
const TOWERS := [
	{"kind":"cannon", "name":"Kanonenturm I", "hp":1500, "range":470.0, "damage":44, "shots":2, "reload":2.6, "offset":Vector2(-0.35,-0.22)},
	{"kind":"mortar", "name":"Mörserturm I", "hp":1250, "range":620.0, "damage":115, "shots":1, "reload":5.5, "offset":Vector2(-0.15,-0.36)},
	{"kind":"chain", "name":"Kettenturm I", "hp":1150, "range":440.0, "damage":22, "shots":2, "reload":3.2, "offset":Vector2(0.1,-0.35)},
	{"kind":"guardian", "name":"Wächterturm I", "hp":1900, "range":390.0, "damage":28, "shots":2, "reload":2.2, "offset":Vector2(0.33,-0.25)},
	{"kind":"cannon", "name":"Kanonenturm II", "hp":1500, "range":470.0, "damage":44, "shots":2, "reload":2.6, "offset":Vector2(-0.42,-0.01)},
	{"kind":"mortar", "name":"Mörserturm II", "hp":1250, "range":620.0, "damage":115, "shots":1, "reload":5.5, "offset":Vector2(0.42,-0.01)},
	{"kind":"chain", "name":"Kettenturm II", "hp":1150, "range":440.0, "damage":22, "shots":2, "reload":3.2, "offset":Vector2(-0.4,0.21)},
	{"kind":"cannon", "name":"Kanonenturm III", "hp":1500, "range":470.0, "damage":44, "shots":2, "reload":2.6, "offset":Vector2(0.39,0.21)},
	{"kind":"mortar", "name":"Mörserturm III", "hp":1250, "range":620.0, "damage":115, "shots":1, "reload":5.5, "offset":Vector2(-0.29,0.36)},
	{"kind":"cannon", "name":"Kanonenturm IV", "hp":1500, "range":470.0, "damage":44, "shots":2, "reload":2.6, "offset":Vector2(0.29,0.36)},
	{"kind":"guardian", "name":"Wächterturm II", "hp":1900, "range":390.0, "damage":28, "shots":2, "reload":2.2, "offset":Vector2(-0.19,0.1)},
	{"kind":"cannon", "name":"Kanonenturm V", "hp":1500, "range":470.0, "damage":44, "shots":2, "reload":2.6, "offset":Vector2(0.19,0.1)}
]

static func normalized_tower_levels(raw: Variant=null) -> Array:
	var levels: Array=[]
	for i in TOWERS.size():
		levels.append(clampi(int(raw[i]),1,5) if raw is Array and i<raw.size() else 1)
	return levels

const GUILD_COST := 300
# Masterkonzept V3.8 §378–380: every guild retains a persistent home
# anchorage, independent of conquerable temporary world fortresses.
# Beta economy values are preliminary; online authority belongs server-side.
const GUILD_HOME_TIERS := ["Ankerplatz","Außenposten","Gildenhafen","Festungshafen","Souveräne Festung"]
const GUILD_HOME_UPGRADE_COSTS := [2000,6000,16000,50000]
const GUILD_HOME_TREASURY_CAPS := [10000,25000,60000,150000,500000]
## Staff: roles carry permission lists, never hard-coded powers. Online, the server issues and
## verifies roles; this test build unlocks them with local codes stored only as SHA-256 hashes.
const STAFF_ENVIRONMENT := "TEST · LOKAL"
const STAFF_CODE_SALT := "abyssal-staff:"
const STAFF_PERMISSIONS := {
	"presence":"Sichtbarkeit wechseln", "inspect":"Ziele inspizieren", "moderate":"Moderation",
	"teleport":"Teleport auf der Karte", "map":"Kartenwechsel per Teleport", "summon":"Ziele herbeirufen",
	"ship":"Staff-Schiffswerte", "spawn":"Gegner und Übungsziele erzeugen", "world":"Welt-Werkzeuge",
	"grant":"Gegenstände gewähren", "audit":"Protokoll einsehen"}
const STAFF_ROLE_ORDER := ["ADMIN","GM","MOD","QA"]
const STAFF_ROLES := {
	"ADMIN":{"name":"Administrator", "badge":"ADM", "color":Color("ff6a4d"), "code_sha256":"81bc757120c494c3adf767943b4f0bb80809cf4eed439d37d90bdd0f58da706c",
		"permissions":["presence","inspect","moderate","teleport","map","summon","ship","spawn","world","grant","audit"]},
	"GM":{"name":"Game Master", "badge":"GM", "color":Color("ffc04d"), "code_sha256":"357be708eaa149775a2fe75a035016ead9642b52485a8cb5de1813f0a8ca8489",
		"permissions":["presence","inspect","moderate","teleport","map","summon","ship","spawn","world","audit"]},
	"MOD":{"name":"Moderator", "badge":"MOD", "color":Color("4fc3ff"), "code_sha256":"2d144429d36a979d75571ad273e39d2a08f1c8d86e9954375cb537d0f7e294f5",
		"permissions":["presence","inspect","moderate","audit"]},
	"QA":{"name":"Qualitätssicherung", "badge":"QA", "color":Color("7be07b"), "code_sha256":"ca7877db550cc694a163841018d4b22d4024e3aae9f69429ccc14c7fb9f3ace8",
		"permissions":["presence","inspect","teleport","map","ship","spawn","world","audit"]}
}
const STAFF_PRESENCE_ORDER := ["official","normal","ghost","spectator"]
const STAFF_PRESENCE := {
	"official":{"name":"OFFIZIELL", "effect":"Abzeichen, Aura und Kartenmarker sichtbar"},
	"normal":{"name":"NORMAL", "effect":"Fährt wie ein Kapitän, ohne Abzeichen"},
	"ghost":{"name":"GEIST", "effect":"Unsichtbar für Kapitäne, Gegner greifen nicht an"},
	"spectator":{"name":"ZUSCHAUER", "effect":"Nur beobachten · kein Feuer, kein Ziel für Gegner"}
}
const STAFF_FLAG_ORDER := ["god","no_aggro","speed","instant_reload","unlimited_ammo","no_collision"]
const STAFF_FLAGS := {
	"god":"Unverwundbar", "no_aggro":"Kein Aggro", "speed":"Eilfahrt ×2,5",
	"instant_reload":"Sofort nachladen", "unlimited_ammo":"Munition unbegrenzt", "no_collision":"Kollision aus"
}
const STAFF_SPAWN_ORDER := ["dummy","ship","elite","admiral","monster"]
const STAFF_SPAWNS := {
	"dummy":{"name":"Übungsziel", "hp":6000}, "ship":{"name":"Patrouille", "hp":420},
	"elite":{"name":"Elite-Schiff", "hp":760}, "admiral":{"name":"Admiral", "hp":2660}, "monster":{"name":"Leviathan", "hp":2310}
}
const STAFF_GRANT_ORDER := ["gold","essence","fragments","scrolls","supplies","ammo","decks","blessing","tide_deck","flask","level"]
const STAFF_GRANTS := {
	"gold":"10.000 Gold", "essence":"25 Gezeitenessenz", "fragments":"16 Fragmente", "scrolls":"je 1 Schriftrolle",
	"supplies":"je 10 Vorräte", "ammo":"Munition auffüllen", "decks":"Kristalldeck Stufe I", "blessing":"Kristallsegen 15 min",
	"tide_deck":"Gezeitendeck 30 min", "flask":"Tagesflasche zurücksetzen", "level":"Kapitänsstufe +1"
}
## Guild tags that imitate staff badges are refused, including digit look-alikes such as 4DM or M0D.
const RESERVED_TAGS := ["ADM","ADMN","GM","GMS","MOD","MODS","QA","STAF","DEV","DEVS","TEAM","SYS","SUPP","GOD","OP","OPS","TEST"]
const RESERVED_PREFIXES := ["ADM","MOD","GM"]

static func has_guild_island(index: int) -> bool:
	return index==FORTRESS_MAP or (index in SEA_MAP_IDS and int(MAPS[index].get("lane",1))==2 and int(MAPS[index].get("tier",1))>=3)

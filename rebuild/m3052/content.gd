extends RefCounted
const MONSTER_COLUMNS := 4
const MONSTER_ROWS := 10
## Visible hull sizes follow the ship design, independent of combat/elite rank.
## Catalog order: redkorsar, elite2..7, elite9..10, boneship, dutchman,
## blackbeard, elite8, warship, pinnace, flyingdutchman.
const SHIP_LENGTHS := [144.0,136.0,136.0,144.0,156.0,144.0,144.0,156.0,156.0,144.0,156.0,156.0,156.0,156.0,92.0,156.0]
## Authored gameplay data, separate from simulation and presentation.
## Regions 0-2 are linked by portals. Bonus maps are separate instances opened with a scroll.
const MAPS := [
	{"name":"Karibische See", "code":"1-1", "level":1, "art":["tropical","rock","tropical","tropical","rock","tropical","tropical","rock","tropical"], "tint":Color(0.75,1.14,1.12), "npc_hostile":false, "enemy_scale":1.0},
	{"name":"Nordmeer", "code":"2-1", "level":2, "art":["snow2","snow","snow2","snow","rock","snow2","snow","rock","snow2"], "tint":Color(0.78,0.98,1.32), "npc_hostile":false, "enemy_scale":1.5},
	{"name":"Schattengewässer", "code":"3-1", "level":4, "art":["rock","rock","snow2","rock","rock","snow","rock","rock","snow2"], "tint":Color(0.90,0.68,1.02), "npc_hostile":true, "enemy_scale":2.2},
	{"name":"Bronzeriff", "code":"B-1", "level":2, "art":["tropical","rock","tropical","rock","tropical"], "tint":Color(1.08,0.96,0.80), "npc_hostile":true, "enemy_scale":1.2, "bonus":true},
	{"name":"Silberbucht", "code":"B-2", "level":5, "art":["snow2","rock","snow","rock","snow2"], "tint":Color(0.92,1.04,1.18), "npc_hostile":true, "enemy_scale":1.9, "bonus":true},
	{"name":"Goldene Lagune", "code":"B-3", "level":8, "art":["tropical","tropical","rock","tropical","rock"], "tint":Color(1.16,1.02,0.72), "npc_hostile":true, "enemy_scale":2.8, "bonus":true}
]
const REGION_COUNT := 3
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
const SUPPLY_KEYS := ["powder","plates","repair_kit","shield_charge"]
const SUPPLIES := {
	"powder":{"name":"Schwarzpulver", "short":"PULVER", "icon":"supply_powder", "toggle":true, "effect":"+40 % Salvenschaden · 1 je gültiger Salve", "price":60, "pack":10},
	"plates":{"name":"Panzerplatten", "short":"PLATTEN", "icon":"supply_plates", "toggle":true, "effect":"−35 % erlittener Schaden · 1 je Treffer", "price":60, "pack":10},
	"repair_kit":{"name":"Notreparatur", "short":"NOTREP", "icon":"supply_repair", "toggle":false, "effect":"+35 % Rumpf sofort · 45 s Abklingzeit", "price":90, "pack":1, "cooldown":45.0},
	"shield_charge":{"name":"Schildladung", "short":"SCHILD", "icon":"supply_shield", "toggle":false, "effect":"+50 % Schild sofort · 40 s Abklingzeit", "price":90, "pack":1, "cooldown":40.0}
}
## Decks change cannon capacity and ship roles. Only one deck of each type can be mounted.
const DECK_KEYS := ["cannon","armor","hunter","navigation","logistics"]
const DECK_TIERS := ["I · Holz","II · Beschlagen","III · Krieg"]
const DECKS := {
	"cannon":{"name":"Kanonendeck", "effect":"+%d Kanonenplätze", "values":[4,6,8], "price":600},
	"armor":{"name":"Panzerdeck", "effect":"+%d %% Rumpf und Schild", "values":[10,15,20], "price":600},
	"hunter":{"name":"Jägerdeck", "effect":"+%d %% Harpunenschaden", "values":[15,25,35], "price":600},
	"navigation":{"name":"Navigationsdeck", "effect":"+%d %% Fahrt", "values":[6,9,12], "price":600},
	"logistics":{"name":"Logistikdeck", "effect":"+%d %% Beutegold", "values":[15,25,35], "price":600}
}
## Gezeitenkessel: every essence thrown pays from this public pool (weights total 100).
const KESSEL_POOL := [
	{"id":"fragment", "name":"Schriftrollenfragment", "amount":1, "weight":24, "rarity":0},
	{"id":"ammo0", "name":"Vollkugeln", "amount":150, "weight":15, "rarity":0},
	{"id":"ammo2", "name":"Harpunen", "amount":30, "weight":8, "rarity":0},
	{"id":"powder", "name":"Schwarzpulver", "amount":5, "weight":12, "rarity":0},
	{"id":"plates", "name":"Panzerplatten", "amount":5, "weight":12, "rarity":0},
	{"id":"gold", "name":"Gold", "amount":150, "weight":11, "rarity":0},
	{"id":"repair_kit", "name":"Notreparatur", "amount":1, "weight":6, "rarity":1},
	{"id":"shield_charge", "name":"Schildladung", "amount":1, "weight":6, "rarity":1},
	{"id":"essence", "name":"Gezeitenessenz", "amount":2, "weight":3, "rarity":1},
	{"id":"tide_deck", "name":"Gezeitendeck 30 min", "amount":1800, "weight":2, "rarity":2},
	{"id":"deck", "name":"Zufälliges Deck I", "amount":0, "weight":1, "rarity":3}
]
const RARITIES := ["Häufig","Selten","Episch","Legendär"]
const KESSEL_THROWS := [1,5,10,25]
const KESSEL_CYCLE := 100
const KESSEL_MILESTONES := [
	{"at":10, "id":"repair_kit", "name":"2 Notreparaturen", "amount":2},
	{"at":25, "id":"scroll0", "name":"Bronze-Schriftrolle", "amount":1},
	{"at":50, "id":"tide_deck", "name":"Gezeitendeck 60 min", "amount":3600},
	{"at":100, "id":"deck_cannon_1", "name":"Kanonendeck II", "amount":1}
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
## Guild fortress on the Schattengewässer: four tower roles around Korsarenfestung.
const FORTRESS_MAP := 2
const FORTRESS_ISLAND := 4
const FORTRESS_TAG := "KRF"
const FORTRESS_HOLD := 1800.0
const TOWERS := [
	{"kind":"cannon", "name":"Kanonenturm", "hp":1500, "range":470.0, "damage":44, "shots":2, "reload":2.6, "offset":Vector2(-0.24,-0.20)},
	{"kind":"mortar", "name":"Mörserturm", "hp":1250, "range":620.0, "damage":115, "shots":1, "reload":5.5, "offset":Vector2(0.20,-0.24)},
	{"kind":"chain", "name":"Kettenturm", "hp":1150, "range":440.0, "damage":22, "shots":2, "reload":3.2, "offset":Vector2(0.24,0.06)},
	{"kind":"guardian", "name":"Wächterturm", "hp":1900, "range":390.0, "damage":28, "shots":2, "reload":2.2, "offset":Vector2(-0.16,0.08)}
]
const GUILD_COST := 300

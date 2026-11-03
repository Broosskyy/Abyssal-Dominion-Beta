extends RefCounted
const MONSTER_COLUMNS := 4
const MONSTER_ROWS := 10
## Authored gameplay data, separate from simulation and presentation.
const MAPS := [
	{"name":"Karibische See", "code":"1-1", "level":1, "art":["tropical","rock","tropical","tropical","rock","tropical","tropical","rock","tropical"], "tint":Color(0.75,1.14,1.12), "npc_hostile":false, "enemy_scale":1.0},
	{"name":"Nordmeer", "code":"2-1", "level":2, "art":["snow2","snow","snow2","snow","rock","snow2","snow","rock","snow2"], "tint":Color(0.78,0.98,1.32), "npc_hostile":false, "enemy_scale":1.5},
	{"name":"Schattengewässer", "code":"3-1", "level":4, "art":["rock","rock","snow2","rock","rock","snow","rock","rock","snow2"], "tint":Color(0.90,0.68,1.02), "npc_hostile":true, "enemy_scale":2.2}
]
const UPGRADE_KEYS := ["cannon","harpoon","hull","sails"]
const UPGRADES := {
	"cannon":{"name":"Kanonen", "icon":"upgrade_cannon", "effect":"+25 % Kugelschaden je Stufe"},
	"harpoon":{"name":"Harpunen", "icon":"upgrade_harpoon", "effect":"+35 % Harpunenschaden je Stufe"},
	"hull":{"name":"Rumpf", "icon":"upgrade_hull", "effect":"+400 maximale Rumpfpunkte je Stufe"},
	"sails":{"name":"Segel", "icon":"upgrade_sails", "effect":"+12 % Fahrtgeschwindigkeit je Stufe"}
}
const QUESTS := [
	{"name":"Küstenwache", "description":"Versenke 3 Gegner", "stat":"kills", "goal":3, "gold":180, "xp":120},
	{"name":"Bergung auf See", "description":"Sammle 3 Beutekisten", "stat":"loot", "goal":3, "gold":140, "xp":100},
	{"name":"Jäger der Tiefe", "description":"Besiege ein Seeungeheuer mit Harpunen", "stat":"monsters", "goal":1, "gold":300, "xp":180},
	{"name":"Kurs nach Norden", "description":"Erreiche das Nordmeer durch ein Portal", "stat":"north", "goal":1, "gold":220, "xp":150},
	{"name":"Admiralsjagd", "description":"Versenke 3 Elite-Schiffe", "stat":"elites", "goal":3, "gold":400, "xp":220},
	{"name":"Hinter dem Nebel", "description":"Erreiche die Schattengewässer", "stat":"abyss", "goal":1, "gold":500, "xp":260},
	{"name":"Herr der Meere", "description":"Versenke insgesamt 20 Gegner", "stat":"kills", "goal":20, "gold":800, "xp":400}
]

extends RefCounted
## M386 – Non-destructive 20-sea world prototype.
## Existing 40 save/server IDs, live map sizes, guild holdings and edge crossings
## remain untouched until a separately tested world-migration release.
const CONTENT = preload("res://content.gd")
const ZONES := ["Küstengewässer","Handelsrouten","Nördliche Gewässer","Umkämpfte See","Tiefe Gewässer"]
const REALMS := [
	{"id":1,"name":"Karibische See","zone":"Küstengewässer","level":1,"harbor":"Sonnenhafen","landscape":"Inselbuchten, kleine Häfen und sichere Handelsrouten","encounters":"Küstenpatrouillen und Riffkrabben","activity":"Erste Aufträge und Erkundung"},
	{"id":2,"name":"Freibeuterbucht","zone":"Küstengewässer","level":2,"harbor":"Hafen der Freibeuter","landscape":"Flache Riffe, Wracks und versteckte Schmugglerbuchten","encounters":"Korsaren und Küstenmonster","activity":"Konvoischutz und Bergung"},
	{"id":3,"name":"Korallenpassage","zone":"Küstengewässer","level":3,"harbor":"Korallenhafen","landscape":"Sandbänke, Korallenfelder und befahrbare Lagunen","encounters":"Riffjäger und kleine Seeschlangen","activity":"Harpunenjagd und Sammelrouten"},
	{"id":4,"name":"Schmugglerküste","zone":"Küstengewässer","level":4,"harbor":"Handelsdock","landscape":"Verwinkelte Inselketten und verborgene Buchten","encounters":"Schmugglerbriggs und Piraten","activity":"Frachtjagd und Hafenhandel"},
	{"id":5,"name":"Handelsstrom","zone":"Handelsrouten","level":5,"harbor":"Kaufmannsreede","landscape":"Offene See, Konvois und Rastplätze","encounters":"Geleitschiffe und Plünderer","activity":"Handelsverträge und Eskorten"},
	{"id":6,"name":"Nebelinseln","zone":"Handelsrouten","level":6,"harbor":"Nebelwarte","landscape":"Dichte Nebelbänke und ein Netz enger Passagen","encounters":"Nebeljäger und rätselhafte Kreaturen","activity":"Schatzsuche und Orientierung"},
	{"id":7,"name":"Sturmklippen","zone":"Handelsrouten","level":7,"harbor":"Klippenhafen","landscape":"Felsenküsten mit wechselnden Strömungen","encounters":"Klippenkorsaren und Seeungeheuer","activity":"Strömungsfahrten und Duelle"},
	{"id":8,"name":"Alte Seewege","zone":"Handelsrouten","level":8,"harbor":"Alte Werft","landscape":"Verlassene Außenposten und zerstörte Handelsrouten","encounters":"Elite-Konvois und Wrackwächter","activity":"Bergung und Gruppenaufträge"},
	{"id":9,"name":"Frostmeer","zone":"Nördliche Gewässer","level":9,"harbor":"Frosthafen","landscape":"Eisinseln und ruhige arktische Buchten","encounters":"Nordmeerpatrouillen und Eisbestien","activity":"Erkundung und seltene Fracht"},
	{"id":10,"name":"Eisbruchpassage","zone":"Nördliche Gewässer","level":10,"harbor":"Eisbrecherreede","landscape":"Treibeis und schmale befahrbare Wasserrinnen","encounters":"Eisbrecher und Tiefenjäger","activity":"Durchfahrt und Materialsuche"},
	{"id":11,"name":"Walbucht","zone":"Nördliche Gewässer","level":11,"harbor":"Walwacht","landscape":"Breite Fjorde und geschützte Küsten","encounters":"Große Meerestiere und Nordkorsaren","activity":"Harpunenaufträge und Schutzmissionen"},
	{"id":12,"name":"Polarwacht","zone":"Nördliche Gewässer","level":12,"harbor":"Nordsternhafen","landscape":"Eisfestungen und gefährliche Außenrouten","encounters":"Elite-Kapitäne und Frostmonster","activity":"Gildenaufträge und Eskorte"},
	{"id":13,"name":"Kanonenstraße","zone":"Umkämpfte See","level":13,"harbor":"Kanonenkai","landscape":"Insel-Forts und strategische Passagen","encounters":"Kriegsschiffe und Seeräuber","activity":"PvP-Zonen und Flottenmissionen"},
	{"id":14,"name":"Trümmermeer","zone":"Umkämpfte See","level":14,"harbor":"Bergungshafen","landscape":"Schiffswracks, Untiefen und verlassene Bastionen","encounters":"Wrackplünderer und große Monster","activity":"Wrackbergung und Beutejagd"},
	{"id":15,"name":"Donnersee","zone":"Umkämpfte See","level":15,"harbor":"Sturmhafen","landscape":"Offene Sturmfronten und zerstörte Küsten","encounters":"Sturmjäger und schwere Fregatten","activity":"Bossbegegnungen und Gruppenfahrt"},
	{"id":16,"name":"Korsarenfront","zone":"Umkämpfte See","level":16,"harbor":"Frontreede","landscape":"Belagerungsinseln und kontrollierte Handelsengen","encounters":"Flottenkapitäne und Gildenverteidiger","activity":"Gildenkrieg und Flottenevents"},
	{"id":17,"name":"Versunkene Reiche","zone":"Tiefe Gewässer","level":17,"harbor":"Ruinenhafen","landscape":"Überflutete Ruinen und versunkene Inselringe","encounters":"Tiefenwächter und Geisterschiffe","activity":"Ruinenexpedition und Relikte"},
	{"id":18,"name":"Schwarze Strömung","zone":"Tiefe Gewässer","level":18,"harbor":"Strömungswacht","landscape":"Dunkles Wasser und mächtige Meeresströmungen","encounters":"Abyssale Jäger und Elite-Schiffe","activity":"Hochrisiko-Konvois und Sonderbeute"},
	{"id":19,"name":"Drachenriff","zone":"Tiefe Gewässer","level":19,"harbor":"Drachenbucht","landscape":"Zerklüftete Riffe und große Höhleneinfahrten","encounters":"Drachenartige Seeungeheuer","activity":"Kooperative Monsterjagd"},
	{"id":20,"name":"Abyssale Tiefe","zone":"Tiefe Gewässer","level":20,"harbor":"Letzter Ankerplatz","landscape":"Tiefe See, seltene Inseln und gefährliche Reviere","encounters":"Legendäre Meeresbestien und Bossflotten","activity":"Endgame-Kampagnen und Welt-Events"}
]

static func realm(realm_id: int) -> Dictionary:
	if realm_id < 1 or realm_id > REALMS.size():return {}
	return REALMS[realm_id-1].duplicate(true)

static func realm_for_map(map_id: int) -> int:
	if not map_id in CONTENT.SEA_MAP_IDS:return -1
	return int(CONTENT.MAPS[map_id].tier)

static func legacy_maps(realm_id: int) -> Array[int]:
	if realm_id < 1 or realm_id > REALMS.size():return []
	# A logical large sea absorbs exactly the two OLD lanes at this tier.
	# This is migration metadata, NOT an active runtime remap.
	return [CONTENT.sea_index(realm_id,1),CONTENT.sea_index(realm_id,2)]

static func zone_id(realm_id: int) -> int:
	if realm_id < 1 or realm_id > REALMS.size():return -1
	return (realm_id-1)/4

## M386 selected topology: classic automatic map-edge transitions only.
## "hybrid": rectangular 4x5 world; corner seas have 2 exits, exterior 3,
## interior 4. No special waypoints, portals or harbor fast travel.
## "two": alternative linear east/west comparison kept only in preview.
const EDGE_MODES := ["hybrid","two"]
const DEFAULT_EDGE_MODE := "hybrid"
const GRID_COLUMNS := 4
const GRID_ROWS := 5
const CARDINAL_EDGES := ["north","south","west","east"]
const OPPOSITE_EDGE := {"north":"south","south":"north","west":"east","east":"west"}

static func edge_links(realm_id: int,mode: String=DEFAULT_EDGE_MODE) -> Dictionary:
	if realm_id<1 or realm_id>REALMS.size() or not mode in EDGE_MODES:return {}
	var result: Dictionary={}
	if mode=="two":
		if realm_id>1:result["west"]=realm_id-1
		if realm_id<REALMS.size():result["east"]=realm_id+1
		return result
	# True geographical adjacency. The perimeter is a world boundary, not
	# an invisible warp; every exit has the opposite entrance in its neighbor.
	var col: int=(realm_id-1)%GRID_COLUMNS
	var row: int=int((realm_id-1)/GRID_COLUMNS)
	if col>0:result["west"]=realm_id-1
	if col<GRID_COLUMNS-1:result["east"]=realm_id+1
	if row>0:result["north"]=realm_id-GRID_COLUMNS
	if row<GRID_ROWS-1:result["south"]=realm_id+GRID_COLUMNS
	return result

static func edge_neighbor(realm_id: int,edge: String,mode: String=DEFAULT_EDGE_MODE) -> int:
	return int(edge_links(realm_id,mode).get(edge,-1))

static func exit_count(realm_id: int,mode: String=DEFAULT_EDGE_MODE) -> int:
	return edge_links(realm_id,mode).size()

static func opposite_edge(edge: String) -> String:
	return str(OPPOSITE_EDGE.get(edge,""))

static func entry_position(world: Vector2,edge: String,tangent: float,inset: float=240.0) -> Vector2:
	# Physical transfer prototype: retains the tangent along the crossed
	# boundary, and places the arrival safely inside the opposite edge.
	# Does not affect the M385 live simulation until the world migration.
	if not edge in CARDINAL_EDGES or not world.is_finite():return Vector2(-1,-1)
	if world.x<=inset*2.0 or world.y<=inset*2.0:return Vector2(-1,-1)
	if edge in ["east","west"]:
		var y: float=clampf(tangent,inset,world.y-inset)
		return Vector2(inset if edge=="east" else world.x-inset,y)
	var x: float=clampf(tangent,inset,world.x-inset)
	return Vector2(x,world.y-inset if edge=="north" else inset)

static func neighbors(realm_id: int,mode: String=DEFAULT_EDGE_MODE) -> Array[int]:
	var result: Array[int]=[]
	for next in edge_links(realm_id,mode).values():
		result.append(int(next))
	result.sort()
	return result

static func route(from_realm: int,to_realm: int,mode: String=DEFAULT_EDGE_MODE) -> Array[int]:
	if realm(from_realm).is_empty() or realm(to_realm).is_empty() or not mode in EDGE_MODES:return []
	if from_realm==to_realm:return [from_realm]
	var queue: Array[int]=[from_realm]
	var previous: Dictionary={from_realm:-1}
	while not queue.is_empty():
		var current: int=queue.pop_front()
		if current==to_realm:break
		for next: int in neighbors(current,mode):
			if previous.has(next):continue
			previous[next]=current
			queue.append(next)
	if not previous.has(to_realm):return []
	var result: Array[int]=[]
	var step: int=to_realm
	while step!=-1:
		result.push_front(step)
		step=int(previous[step])
	return result

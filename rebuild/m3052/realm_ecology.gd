extends RefCounted
## M389 region ecology. Pure, authored, deterministic map content. Every sea
## uses the existing original island atlas and monster/ship art until approved
## replacements arrive. The visual style can be swapped without changing water,
## collisions, NPC identities, loot, saves, or crossplay positions.
const CONTENT=preload("res://content.gd")
const ATLAS=preload("res://realm_catalog.gd")
const REGION_TYPES=[
	{"biome":"Küstenbuchten","palette":["tropical","tropical","rock","tropical","rock"],"roles":["Küstenhändler","Freibeuter","Riffpatrouille","Schmuggler"],"hunt":"Wächter der Sonnenküste"},
	{"biome":"Handelsmeer","palette":["tropical","rock","rock","tropical","rock"],"roles":["Geleitkapitän","Konvoi-Räuber","Nebelpatrouille","Handelsfahrer"],"hunt":"Wächter der Handelswege"},
	{"biome":"Nordmeer","palette":["snow2","snow","rock","snow","snow2"],"roles":["Nordwache","Eiskorsar","Frachtsegler","Fjordjäger"],"hunt":"Wächter des Frostmeers"},
	{"biome":"Kriegsgewässer","palette":["rock","rock","tropical","rock","snow2"],"roles":["Festungskorsar","Flottenwache","Belagerer","Wrackjäger"],"hunt":"Wächter der Sturmfront"},
	{"biome":"Tiefenmeer","palette":["rock","tropical","rock","snow2","rock"],"roles":["Tiefenjäger","Reliktwache","Geisterfahrer","Elite-Korsar"],"hunt":"Wächter der Tiefen"}
]
# 20 distinct encounter names; the underlying species art remains replaceable.
const GUARDIANS=[
	"Riffwächter Aruna","Freibeuterfluch","Korallenfürst","Schatten der Schmuggler",
	"Konvoischrecken","Nebeltentakel","Sturmzahn","Wächter der Alten Route",
	"Frostkoloss","Eisbrecherbestie","Walwächter","Polarherrscher",
	"Kanonenkraken","Wrackverschlinger","Donnerbestie","Korsaren-Titan",
	"Ruinenfürst","Strömungsdrache","Riffdrache","Abyssaler Leviathan"
]
const MONSTER_PREFIX=[
	["Riff","Korallen","Küsten"],["Nebel","Handels","Klippen"],
	["Frost","Eis","Polar"],["Sturm","Korsaren","Trümmer"],
	["Tiefen","Abyss","Drachen"]
]
const ISLAND_NAMES=[
	["Sonnenklippe","Schmugglerfelsen","Ankerinsel","Flaches Riff","Westbucht","Altes Wrack","Wachfelsen","Südkap","Perlenbank"],
	["Handelskap","Lotseninsel","Nebelfelsen","Korsarenriff","Wachtinsel","Wrackufer","Kaufmannsklippe","Seewarte","Frachtbank"],
	["Eisnase","Frostfelsen","Nordbank","Polarinsel","Fjordwacht","Eisriff","Schneekap","Gletscherinsel","Walwarte"],
	["Bastion","Kanonenkap","Ruinenspitze","Schlachtbank","Wachklippe","Festungsriff","Sturmkap","Wrackinsel","Pulverfelsen"],
	["Tiefenkap","Schattenriff","Alte Ruine","Drachenfelsen","Schwarze Bank","Versunkene Insel","Leviathanspitze","Abgrundwacht","Letztes Riff"]
]
# Nine collision-safe anchor points in EACH old sea half, with a wide open
# harbor approach and a ~3km central sailing corridor. Never use runtime RNG.
const SITES=[
	Vector2(1120,900),Vector2(2880,890),Vector2(5340,1050),
	Vector2(7410,960),Vector2(1320,3470),Vector2(3080,5160),
	Vector2(5540,4840),Vector2(7420,4360),Vector2(1090,5560)
]
# Eight patrols per half, independent of screen renderer and current camera.
const PATROLS=[
	Vector2(920,2100),Vector2(2300,2600),Vector2(3760,800),Vector2(6000,2200),
	Vector2(7380,2630),Vector2(4200,4250),Vector2(2700,5780),Vector2(6600,5550)
]
const MONSTER_SITES=[
	Vector2(13200,3120),Vector2(3200,4060),
	Vector2(11600,4960),Vector2(15100,2100)
]
const SALVAGE_SITES=[
	Vector2(3780,3640),Vector2(6150,3620),
	Vector2(11100,3650),Vector2(14800,3550)
]

static func valid_realm(realm_id:int)->bool:
	return realm_id>=1 and realm_id<=20

static func map_realm(map_id:int)->int:
	return CONTENT.realm_id_for_map(map_id)

static func biome(realm_id:int)->String:
	if not valid_realm(realm_id):return ""
	return str(REGION_TYPES[int((realm_id-1)/4)].biome)

static func map_seed(realm_id:int,index:int,half:int)->int:
	return realm_id*127+index*41+half*173

static func island_site(realm_id:int,index:int,half:int)->Vector2:
	if not valid_realm(realm_id) or index<0 or index>=SITES.size() or not half in [0,1]:return Vector2(-1,-1)
	var p:Vector2=SITES[index]
	var seed:int=map_seed(realm_id,index,half)
	var jitter:=Vector2(float(seed%9-4)*25.0,float(int(seed/9)%9-4)*22.0)
	p+=jitter
	if half==1:p=Vector2(8800.0+p.x,6400.0-p.y)
	return p

static func island_art(realm_id:int,index:int,half:int)->String:
	if not valid_realm(realm_id) or index<0 or index>=9:return "rock"
	var palette:Array=REGION_TYPES[int((realm_id-1)/4)].palette
	return str(palette[posmod(realm_id+index*3+half*2,palette.size())])

static func island_title(realm_id:int,index:int,half:int)->String:
	if not valid_realm(realm_id) or index<0 or index>=9:return "Unbekannte Insel"
	var zone:int=int((realm_id-1)/4)
	return "%s · %s" % [ATLAS.realm(realm_id).name,str(ISLAND_NAMES[zone][posmod(index+realm_id+half*2,9)])]

static func patrol_site(realm_id:int,index:int)->Vector2:
	if not valid_realm(realm_id) or index<0 or index>=16:return Vector2(-1,-1)
	var half:int=int(index/8)
	var p:Vector2=PATROLS[index%8]
	var seed:int=map_seed(realm_id,index,half)
	p+=Vector2(float(seed%7-3)*37.0,float(int(seed/7)%7-3)*31.0)
	return p+Vector2(8800.0*half,0.0)

static func patrol_title(realm_id:int,index:int)->String:
	if not valid_realm(realm_id):return ""
	var zone:int=int((realm_id-1)/4)
	var roles:Array=REGION_TYPES[zone].roles
	return "%s · %s" % [ATLAS.realm(realm_id).name,str(roles[posmod(index+realm_id,roles.size())])]

static func monster_site(realm_id:int,index:int)->Vector2:
	if not valid_realm(realm_id) or index<0 or index>=4:return Vector2(-1,-1)
	var seed:int=map_seed(realm_id,index,1)
	return MONSTER_SITES[index]+Vector2(float(seed%5-2)*52.0,float(int(seed/5)%5-2)*41.0)

static func monster_title(realm_id:int,key:String)->String:
	if not valid_realm(realm_id):return ""
	if key=="tiamat":return str(GUARDIANS[realm_id-1])
	var index:int=["kraken","serpent","crab"].find(key)
	if index<0:return ""
	var zone:int=int((realm_id-1)/4)
	var species:=["Krake","Seeschlange","Panzerkrabbe"]
	return "%s-%s" % [str(MONSTER_PREFIX[zone][index]),str(species[index])]

static func mission(realm_id:int)->Dictionary:
	if not valid_realm(realm_id):return {}
	return {
		"realm_id":realm_id,
		"title":"Revierauftrag · %s" % ATLAS.realm(realm_id).name,
		"salvage_goal":3,"hunt_goal":1,
		"gold":120+realm_id*35,"xp":90+realm_id*15,
		"essence":1+int((realm_id-1)/5),
		"description":"3 Gezeitenfunde bergen und 1 Seeungeheuer mit Harpunen besiegen"
	}

static func salvage_site(realm_id:int,index:int)->Vector2:
	if not valid_realm(realm_id) or index<0 or index>=SALVAGE_SITES.size():return Vector2(-1,-1)
	var seed:int=map_seed(realm_id,index,0)
	return SALVAGE_SITES[index]+Vector2(float(seed%5-2)*35.0,float(int(seed/5)%5-2)*29.0)

class_name ChartCompositionCatalog
extends RefCounted
## M196: deterministic, platform-neutral regional macro composition for named 360x360 charts.
## Region changes world identity; device class never changes gameplay geometry/content.

const BASE_ISLAND_ANCHORS:Array[Vector2] = [
	Vector2(-0.68,-0.56), Vector2(0.62,-0.60), Vector2(-0.58,0.58), Vector2(0.66,0.52),
	Vector2(-0.78,0.06), Vector2(0.78,-0.02), Vector2(-0.18,0.78), Vector2(0.20,-0.80)
]
const POI_ANCHORS:Array[Vector2] = [
	Vector2(-0.42,-0.22), Vector2(0.44,0.24), Vector2(-0.28,0.46), Vector2(0.30,-0.48),
	Vector2(-0.72,0.34), Vector2(0.70,-0.36), Vector2(0.08,0.68), Vector2(-0.06,-0.70)
]

# scale/rotation/offset alter the macro silhouette without changing chart size or island count.
const REGION_PROFILES:Dictionary = {
	"shattered_shores":{"scale":Vector2(1.00,0.82),"rotation":-0.08,"offset":Vector2(0.00,0.02),"route":"open_coastal_crossing"},
	"crimson_sea":{"scale":Vector2(0.92,1.00),"rotation":0.18,"offset":Vector2(0.02,-0.02),"route":"diagonal_raider_lanes"},
	"drowned_reach":{"scale":Vector2(1.06,0.88),"rotation":-0.20,"offset":Vector2(-0.03,0.04),"route":"wreck_arc_and_fog_bypass"},
	"stormbound_expanse":{"scale":Vector2(0.82,1.10),"rotation":0.08,"offset":Vector2(0.00,0.00),"route":"storm_chokepoints_with_outer_bypass"},
	"cursed_dominion":{"scale":Vector2(0.90,1.02),"rotation":-0.28,"offset":Vector2(0.04,0.01),"route":"broken_sigil_zigzag"},
	"abyssal_frontier":{"scale":Vector2(1.10,1.08),"rotation":0.24,"offset":Vector2(0.00,-0.02),"route":"rift_ring_and_monster_corridor"},
	"sunken_empire":{"scale":Vector2(0.96,0.92),"rotation":-0.12,"offset":Vector2(-0.02,-0.01),"route":"ruin_archipelago"},
	"void_sea":{"scale":Vector2(1.14,1.12),"rotation":0.05,"offset":Vector2(0.00,0.00),"route":"wide_void_crossing"},
	"sovereign_waters":{"scale":Vector2(0.94,0.90),"rotation":0.14,"offset":Vector2(0.02,0.02),"route":"fortified_trade_lanes"},
	"abyssal_dominion":{"scale":Vector2(0.88,1.04),"rotation":-0.16,"offset":Vector2(0.00,0.03),"route":"dominion_gate_corridors"},
	"dreadwater_march":{"scale":Vector2(0.86,1.08),"rotation":0.27,"offset":Vector2(-0.02,0.00),"route":"blackwake_gauntlet"},
	"iron_maw_reach":{"scale":Vector2(0.84,1.10),"rotation":-0.25,"offset":Vector2(0.03,-0.01),"route":"iron_maw_channels"}
}

const REGION_POI_MIX:Dictionary = {
	"shattered_shores":["navigation","salvage","wreck","supply"],
	"crimson_sea":["navigation","wreck","salvage","monster_warning"],
	"drowned_reach":["wreck_beacon","wreck","shrine","monster_warning"],
	"stormbound_expanse":["navigation","monster_warning","wreck_beacon","supply"],
	"cursed_dominion":["shrine","monster_warning","wreck_beacon","monster_nest"],
	"abyssal_frontier":["monster_warning","monster_nest","shrine","wreck_beacon"],
	"sunken_empire":["shrine","wreck","salvage","monster_warning"],
	"void_sea":["monster_nest","shrine","wreck_beacon","navigation"],
	"sovereign_waters":["navigation","supply","wreck_beacon","shrine"],
	"abyssal_dominion":["shrine","monster_nest","monster_warning","wreck_beacon"],
	"dreadwater_march":["monster_warning","wreck","monster_nest","navigation"],
	"iron_maw_reach":["monster_nest","monster_warning","shrine","wreck_beacon"]
}

static func region_profile(region_id:String)->Dictionary:
	return (REGION_PROFILES.get(region_id,{"scale":Vector2.ONE,"rotation":0.0,"offset":Vector2.ZERO,"route":"balanced_crossing"}) as Dictionary).duplicate(true)

static func route_identity(region_id:String)->String:
	return str(region_profile(region_id).get("route","balanced_crossing"))

static func _regionalize(base:Vector2,region_id:String)->Vector2:
	var profile:=region_profile(region_id)
	var scale:Vector2=profile.get("scale",Vector2.ONE)
	var p:=Vector2(base.x*scale.x,base.y*scale.y)
	p=p.rotated(float(profile.get("rotation",0.0)))+Vector2(profile.get("offset",Vector2.ZERO))
	# Never push authored macro anchors into the transfer edge band.
	return Vector2(clampf(p.x,-0.88,0.88),clampf(p.y,-0.88,0.88))

static func island_anchor(index:int, seed_value:int, extent:float, region_id:String="")->Vector3:
	var base:=_regionalize(BASE_ISLAND_ANCHORS[index % BASE_ISLAND_ANCHORS.size()],region_id)
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value+index*7919
	var jitter:=Vector2(rng.randf_range(-0.055,0.055),rng.randf_range(-0.055,0.055))
	var p:=(base+jitter)*extent
	return Vector3(p.x,0.2,p.y)

static func poi_anchor(index:int, seed_value:int, extent:float, region_id:String="")->Vector3:
	# POIs share the regional transform but are offset by one anchor step so they do not sit on islands.
	var base:=_regionalize(POI_ANCHORS[index % POI_ANCHORS.size()],region_id)
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value+index*3571
	var jitter:=Vector2(rng.randf_range(-0.065,0.065),rng.randf_range(-0.065,0.065))
	var p:=(base+jitter)*extent
	return Vector3(p.x,0.35,p.y)

static func poi_mix(region_id:String, level:int)->Array:
	var regional:Array=REGION_POI_MIX.get(region_id,[])
	if not regional.is_empty():return regional.duplicate()
	return WorldPoiCatalog.level_mix(level)

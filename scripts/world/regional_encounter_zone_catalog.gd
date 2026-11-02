class_name RegionalEncounterZoneCatalog
extends RefCounted
## M197: platform-neutral encounter zoning for named charts.
## Normalized anchors are mapped into the canonical 360x360 chart by EncounterDirector.
## They shape where combat begins without changing spawn counts, rewards, combat math or device parity.

const DEFAULT_PROFILE := {
	"patrol": [Vector2(-0.46,-0.18), Vector2(0.42,0.20), Vector2(-0.18,0.52), Vector2(0.24,-0.50)],
	"monster": [Vector2(0.62,-0.50), Vector2(-0.58,0.48)],
	"admiral": [Vector2(0.0,-0.68)],
	"safe_lane": [Vector2(-0.78,0.70), Vector2(0.76,-0.68)],
	"zone_radius": 34.0,
	"safe_lane_radius": 17.0
}

const REGION_PROFILES := {
	"shattered_shores":{"patrol":[Vector2(-0.54,-0.18),Vector2(0.50,0.22),Vector2(-0.16,0.54),Vector2(0.18,-0.54)],"monster":[Vector2(0.70,-0.52),Vector2(-0.68,0.48)],"admiral":[Vector2(0.02,-0.72)],"safe_lane":[Vector2(-0.80,0.72),Vector2(0.78,-0.70)],"zone_radius":36.0,"safe_lane_radius":20.0},
	"crimson_sea":{"patrol":[Vector2(-0.62,-0.44),Vector2(-0.18,-0.10),Vector2(0.30,0.22),Vector2(0.66,0.50)],"monster":[Vector2(0.62,-0.58),Vector2(-0.58,0.58)],"admiral":[Vector2(0.68,0.04)],"safe_lane":[Vector2(-0.76,0.62),Vector2(0.72,-0.64)],"zone_radius":32.0,"safe_lane_radius":17.0},
	"drowned_reach":{"patrol":[Vector2(-0.66,0.20),Vector2(-0.30,-0.42),Vector2(0.16,-0.56),Vector2(0.58,-0.16)],"monster":[Vector2(-0.60,-0.62),Vector2(0.54,0.54)],"admiral":[Vector2(0.66,0.26)],"safe_lane":[Vector2(-0.74,0.66),Vector2(0.70,-0.56)],"zone_radius":35.0,"safe_lane_radius":16.0},
	"stormbound_expanse":{"patrol":[Vector2(-0.50,-0.60),Vector2(-0.18,-0.22),Vector2(0.18,0.18),Vector2(0.48,0.58)],"monster":[Vector2(-0.70,0.10),Vector2(0.70,-0.12)],"admiral":[Vector2(0.08,0.70)],"safe_lane":[Vector2(-0.78,0.72),Vector2(0.76,0.64)],"zone_radius":31.0,"safe_lane_radius":15.0},
	"cursed_dominion":{"patrol":[Vector2(-0.58,-0.50),Vector2(0.02,-0.34),Vector2(-0.10,0.30),Vector2(0.58,0.48)],"monster":[Vector2(0.64,-0.58),Vector2(-0.66,0.56)],"admiral":[Vector2(0.66,0.04)],"safe_lane":[Vector2(-0.78,0.06),Vector2(0.76,0.04)],"zone_radius":33.0,"safe_lane_radius":14.0},
	"abyssal_frontier":{"patrol":[Vector2(-0.56,-0.24),Vector2(-0.26,0.44),Vector2(0.28,-0.44),Vector2(0.58,0.24)],"monster":[Vector2(-0.68,-0.60),Vector2(0.68,0.58)],"admiral":[Vector2(0.0,0.72)],"safe_lane":[Vector2(-0.78,0.02),Vector2(0.76,0.00)],"zone_radius":37.0,"safe_lane_radius":14.0},
	"sunken_empire":{"patrol":[Vector2(-0.62,-0.34),Vector2(-0.24,0.48),Vector2(0.20,-0.50),Vector2(0.60,0.34)],"monster":[Vector2(-0.66,0.62),Vector2(0.68,-0.60)],"admiral":[Vector2(0.04,0.70)],"safe_lane":[Vector2(-0.76,-0.04),Vector2(0.74,0.06)],"zone_radius":34.0,"safe_lane_radius":15.0},
	"void_sea":{"patrol":[Vector2(-0.68,-0.46),Vector2(-0.34,0.40),Vector2(0.34,-0.40),Vector2(0.68,0.46)],"monster":[Vector2(-0.72,0.04),Vector2(0.72,-0.04)],"admiral":[Vector2(0.0,-0.74)],"safe_lane":[Vector2(-0.76,0.66),Vector2(0.76,-0.66)],"zone_radius":39.0,"safe_lane_radius":14.0},
	"sovereign_waters":{"patrol":[Vector2(-0.64,-0.18),Vector2(-0.24,-0.16),Vector2(0.24,0.16),Vector2(0.64,0.18)],"monster":[Vector2(-0.58,0.62),Vector2(0.60,-0.60)],"admiral":[Vector2(0.68,0.52)],"safe_lane":[Vector2(-0.78,0.54),Vector2(0.74,-0.50)],"zone_radius":31.0,"safe_lane_radius":18.0},
	"abyssal_dominion":{"patrol":[Vector2(-0.52,-0.58),Vector2(-0.16,-0.20),Vector2(0.16,0.20),Vector2(0.52,0.58)],"monster":[Vector2(-0.70,0.12),Vector2(0.70,-0.12)],"admiral":[Vector2(0.0,0.74)],"safe_lane":[Vector2(-0.78,-0.66),Vector2(0.76,-0.62)],"zone_radius":34.0,"safe_lane_radius":14.0},
	"dreadwater_march":{"patrol":[Vector2(-0.60,-0.58),Vector2(-0.24,-0.18),Vector2(0.18,0.22),Vector2(0.58,0.60)],"monster":[Vector2(-0.68,0.52),Vector2(0.66,-0.54)],"admiral":[Vector2(0.70,0.04)],"safe_lane":[Vector2(-0.78,0.68),Vector2(0.76,0.64)],"zone_radius":32.0,"safe_lane_radius":14.0},
	"iron_maw_reach":{"patrol":[Vector2(-0.50,-0.64),Vector2(-0.16,-0.22),Vector2(0.14,0.24),Vector2(0.50,0.64)],"monster":[Vector2(-0.70,0.12),Vector2(0.70,-0.10)],"admiral":[Vector2(0.02,-0.74)],"safe_lane":[Vector2(-0.78,0.68),Vector2(0.76,0.62)],"zone_radius":30.0,"safe_lane_radius":13.0}
}

static func profile(region_id:String)->Dictionary:
	return (REGION_PROFILES.get(region_id,DEFAULT_PROFILE) as Dictionary).duplicate(true)

static func anchors(region_id:String,kind:String)->Array:
	var p:=profile(region_id)
	var key:="admiral" if kind=="admiral" else ("monster" if kind=="monster" else "patrol")
	return (p.get(key,DEFAULT_PROFILE.get(key,[])) as Array).duplicate()

static func anchor(region_id:String,kind:String,slot:int,extent:float)->Vector3:
	var rows:=anchors(region_id,kind)
	if rows.is_empty():return Vector3.ZERO
	var v:Vector2=rows[posmod(slot,rows.size())]
	return Vector3(v.x*extent,0.55,v.y*extent)

static func zone_radius(region_id:String)->float:
	return float(profile(region_id).get("zone_radius",34.0))

static func safe_lane(region_id:String,extent:float)->Array[Vector3]:
	var p:=profile(region_id)
	var rows:Array=p.get("safe_lane",DEFAULT_PROFILE.get("safe_lane",[]))
	var result:Array[Vector3]=[]
	for value in rows:
		var v:Vector2=value
		result.append(Vector3(v.x*extent,0.55,v.y*extent))
	return result

static func safe_lane_radius(region_id:String)->float:
	return float(profile(region_id).get("safe_lane_radius",16.0))

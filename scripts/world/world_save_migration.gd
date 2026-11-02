class_name WorldSaveMigration
extends RefCounted
const SCHEMA:=2

static func resolve_sector_id(world_data:Dictionary)->Dictionary:
	var requested:=str(world_data.get("sector_id",""))
	if not requested.is_empty() and not WorldSectorRegistry.by_id(requested).is_empty():
		return {"ok":true,"sector_id":requested,"migrated":false,"source":"stable_id"}
	var legacy:Array=world_data.get("sector",[])
	if legacy.size()>=2:
		var coordinate:=Vector2i(int(legacy[0]),int(legacy[1]))
		var resolved:=WorldSectorRegistry.id_for_coord(coordinate)
		if not resolved.is_empty():
			return {"ok":true,"sector_id":resolved,"migrated":true,"source":"legacy_coordinate"}
	return {"ok":false,"sector_id":"SECTOR-001","migrated":true,"source":"safe_start_fallback"}

static func payload(sector_id:String,legacy_coord:Vector2i)->Dictionary:
	var out:={"schema":SCHEMA,"sector_id":sector_id}
	if legacy_coord.x>-100:out["sector"]=[legacy_coord.x,legacy_coord.y]
	return out

static func sanitize_local_position(value:Variant,half_size:float=36.0)->Vector3:
	if not value is Array or value.size()<2:return Vector3.ZERO
	var x:=clampf(float(value[0]),-half_size+2.5,half_size-2.5)
	var z:=clampf(float(value[1]),-half_size+2.5,half_size-2.5)
	return Vector3(x,0.55,z)

class_name SectorGraph
extends RefCounted
static func sector_id_for_level(level:int)->String:
	for row in WorldSectorRegistry.effective_all():
		if int(row.get("pirate_level",0))==level:return str(row.get("id",""))
	return ""
static func sector_for_level(level:int)->Vector2i:return WorldSectorRegistry.coord_for_id(sector_id_for_level(level))
static func neighbors(coord:Vector2i)->Array[Vector2i]:
	var out:Array[Vector2i]=[];var id:=WorldSectorRegistry.id_for_coord(coord)
	if id.is_empty():return out
	var row:=WorldSectorRegistry.by_id(id)
	for _direction in (row.get("neighbors",{}) as Dictionary):
		var c:=WorldSectorRegistry.coord_for_id(str(row.neighbors[_direction]))
		if c.x>-100:out.append(c)
	return out
static func connected_levels()->Array[int]:
	var out:Array[int]=[]
	for row in WorldSectorRegistry.effective_all():out.append(int(row.get("pirate_level",0)))
	out.sort();return out
static func validate_progression_path(first:int,last:int)->Array[String]:
	var errors:Array[String]=[]
	for level in range(first,last+1):
		var id:=sector_id_for_level(level)
		if id.is_empty():errors.append("missing_%d"%level);continue
		if level<last:
			var next:=sector_id_for_level(level+1)
			if next.is_empty():errors.append("missing_%d"%(level+1));continue
			var row:=WorldSectorRegistry.by_id(id)
			if next not in (row.get("neighbors",{}) as Dictionary).values():errors.append("not_adjacent_%d_%d"%[level,level+1])
	return errors

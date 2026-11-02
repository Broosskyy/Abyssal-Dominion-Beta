class_name WorldSectorRegistry
extends RefCounted
const PATH:="res://data/world_sector_registry.json"
static var _data:Dictionary={}
static func data()->Dictionary:
	if _data.is_empty():
		var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=v if v is Dictionary else {"sectors":[]}
	return _data
static func all()->Array:return data().get("sectors",[])
static func effective_all()->Array:
	var base:Array=all().duplicate(true)
	var tree:=Engine.get_main_loop() as SceneTree
	if tree==null:return base
	var index:Dictionary={}
	for i in range(base.size()):
		index[str((base[i] as Dictionary).get("id",""))]=i
	for row in DynamicContentResolver.active_records(tree,"sector"):
		var id:=str(row.get("id",""))
		if id.is_empty():continue
		var converted:Dictionary={
			"id":id,
			"legacy_coord":row.get("legacy_coord",[]),
			"map_position":row.get("map_position",row.get("legacy_coord",[0,0])),
			"display_name":str(row.get("name",id)),
			"biome":str(row.get("biome","tropical")),
			"port":str(row.get("harbor_id","")),
			"pirate_level":int(row.get("pirate_level",1)),
			"region_id":str(row.get("region_id","")),
			"map_type":str(row.get("map_type","core_sea")),
			"neighbors":(row.get("neighbors",{}) as Dictionary).duplicate(true),
			"npc_ids":row.get("npc_ids",[]),
			"monster_ids":row.get("monster_ids",[]),
			"admiral_id":str(row.get("admiral_id","")),
			"poi_ids":row.get("poi_ids",[]),
			"island_slots":row.get("island_slots",[]),
			"environment_profile":str(row.get("environment_profile","")),
			"dynamic_content":true
		}
		if index.has(id):
			var existing:Dictionary=(base[int(index[id])] as Dictionary).duplicate(true)
			# Existing IDs may be admin-overlaid only through explicit supported world fields.
			for key in ["map_position","display_name","biome","port","pirate_level","region_id","map_type","neighbors","npc_ids","monster_ids","admiral_id","poi_ids","island_slots","environment_profile"]:
				if row.has(key):
					existing[key]=converted.get(key,existing.get(key))
			existing["dynamic_overlay"]=true
			base[int(index[id])]=existing
		else:
			base.append(converted)
			index[id]=base.size()-1
	return base

static func by_id(id:String)->Dictionary:
	for row in effective_all():
		if str(row.get("id",""))==id:return (row as Dictionary).duplicate(true)
	return {}
static func id_for_coord(coord:Vector2i)->String:
	for row in effective_all():
		var c:Array=row.get("legacy_coord",[])
		if c.size()>=2 and int(c[0])==coord.x and int(c[1])==coord.y:return str(row.get("id",""))
	return ""
static func map_position_for_id(id:String)->Vector2:
	var row:=by_id(id);var p:Array=row.get("map_position",row.get("legacy_coord",[]))
	return Vector2(float(p[0]),float(p[1])) if p.size()>=2 else Vector2.ZERO

static func map_bounds()->Rect2:
	var rows:=effective_all()
	if rows.is_empty():return Rect2(Vector2.ZERO,Vector2.ONE)
	var first:=map_position_for_id(str(rows[0].get("id","")))
	var minp:=first;var maxp:=first
	for row in rows:
		var p:=map_position_for_id(str(row.get("id","")))
		minp.x=minf(minp.x,p.x);minp.y=minf(minp.y,p.y)
		maxp.x=maxf(maxp.x,p.x);maxp.y=maxf(maxp.y,p.y)
	return Rect2(minp,maxp-minp)

static func coord_for_id(id:String)->Vector2i:
	var row:=by_id(id);var c:Array=row.get("legacy_coord",[])
	return Vector2i(int(c[0]),int(c[1])) if c.size()>=2 else Vector2i(-999,-999)
static func by_coord(coord:Vector2i)->Dictionary:return by_id(id_for_coord(coord))
static func direction_key(direction:Vector2i)->String:
	if direction==Vector2i.LEFT:return "left"
	if direction==Vector2i.RIGHT:return "right"
	if direction==Vector2i.UP:return "up"
	if direction==Vector2i.DOWN:return "down"
	return ""

static func runtime_data(id:String)->Dictionary:
	var row:=by_id(id)
	if row.is_empty():return {}
	return {
		"name":str(row.get("display_name",id)),
		"biome":str(row.get("biome","tropical")),
		"port":str(row.get("port","")),
		"level":int(row.get("pirate_level",1)),
		"sector_id":id,
		"region_id":str(row.get("region_id","")),
		"map_type":str(row.get("map_type","core_sea")),
		"poi_ids":row.get("poi_ids",[]),
		"island_slots":row.get("island_slots",[])
	}

static func neighbor_id(id:String,direction:Vector2i)->String:
	var key:=direction_key(direction)
	if key.is_empty():return ""
	return str((by_id(id).get("neighbors",{}) as Dictionary).get(key,""))

static func legacy_dictionary()->Dictionary:
	var out:Dictionary={}
	for row in effective_all():
		var c:Array=row.get("legacy_coord",[])
		if c.size()<2:continue
		out[Vector2i(int(c[0]),int(c[1]))]={"name":str(row.get("display_name","")),"biome":str(row.get("biome","tropical")),"port":str(row.get("port","")),"level":int(row.get("pirate_level",1)),"sector_id":str(row.get("id","")),"region_id":str(row.get("region_id",""))}
	return out
static func validate()->PackedStringArray:
	var errors:=PackedStringArray();var ids:Dictionary={};var coords:Dictionary={}
	var rows:=effective_all()
	for row in rows:
		var id:=str(row.get("id",""));var c:Array=row.get("legacy_coord",[])
		if id.is_empty() or ids.has(id):errors.append("duplicate_or_empty_id:"+id)
		ids[id]=true
		if c.size()>=2:
			var ck:="%d,%d"%[int(c[0]),int(c[1])]
			if coords.has(ck):errors.append("duplicate_coord:"+ck)
			coords[ck]=true
	var opposite:Dictionary={"left":"right","right":"left","up":"down","down":"up"}
	for row in rows:
		var id:=str(row.get("id",""));var neighbors:Dictionary=row.get("neighbors",{})
		for direction in neighbors:
			var other:=str(neighbors[direction])
			if not ids.has(other):errors.append(id+":dangling_neighbor:"+other);continue
			var back:Dictionary=by_id(other).get("neighbors",{})
			var opposite_key:=str(opposite.get(direction,""))
			if not opposite_key.is_empty() and str(back.get(opposite_key,""))!=id:
				errors.append(id+":asymmetric:"+str(direction)+":"+other)
	return errors

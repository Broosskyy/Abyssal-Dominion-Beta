class_name DynamicSpawnTable
extends RefCounted
static func active_tables(tree:SceneTree,sector_id:String,region_id:String)->Array:
	var out:Array=[]
	for row in DynamicContentResolver.active_records(tree,"spawn_table"):
		var sectors:Array=row.get("sector_ids",[])
		var regions:Array=row.get("region_ids",[])
		if not sectors.is_empty() and sector_id not in sectors:continue
		if not regions.is_empty() and region_id not in regions:continue
		out.append(row)
	var now:=TrustedTimeService.now(tree)
	for event in DynamicEventResolver.active_events(tree,now):
		for id in event.get("spawn_table_ids",[]):
			var row:=DynamicContentResolver.by_id(tree,"spawn_table",str(id))
			if not row.is_empty() and row not in out:out.append(row)
	return out
static func effective(tree:SceneTree,sector_id:String,region_id:String,fallback_pool:Dictionary,biome:Dictionary)->Dictionary:
	var regional_defaults:=P1RegionalRuntimeCatalog.spawn(region_id)
	var result:={"entries":[],"slot_count":maxi(1,int(regional_defaults.get("population_target",biome.get("slots",[]).size()))),"respawn_seconds":float(regional_defaults.get("respawn_seconds",2.0)),
		"admiral_kills_required":int(regional_defaults.get("admiral_kills_required",biome.get("required_kills",3))),"admiral_cooldown_seconds":float(regional_defaults.get("admiral_cooldown_seconds",biome.get("cooldown",20.0))),"formation_id":""}
	for id in fallback_pool.get("npc_ids",[]):result.entries.append({"content_id":str(id),"kind":"npc","weight":1.0})
	for id in fallback_pool.get("monster_ids",[]):result.entries.append({"content_id":str(id),"kind":"monster","weight":float(regional_defaults.get("monster_weight",0.35))})
	for id in fallback_pool.get("admiral_ids",[]):result.entries.append({"content_id":str(id),"kind":"admiral","weight":1.0})
	for table in active_tables(tree,sector_id,region_id):
		if not table.get("entries",[]).is_empty():result.entries=table.get("entries",[]).duplicate(true)
		for key in ["slot_count","respawn_seconds","admiral_kills_required","admiral_cooldown_seconds","formation_id"]:
			if table.has(key):result[key]=table[key]
	return result
static func weighted_pick_any(table:Dictionary,rng:RandomNumberGenerator,kinds:Array)->Dictionary:
	var rows:Array=[];var total:=0.0
	for row in table.get("entries",[]):
		if not row is Dictionary or str(row.get("kind","npc")) not in kinds:continue
		var w:=maxf(0.0,float(row.get("weight",1.0)))
		if w<=0.0:continue
		rows.append(row);total+=w
	if rows.is_empty() or total<=0.0:return {}
	var roll:=rng.randf_range(0.0,total)
	for row in rows:
		roll-=maxf(0.0,float(row.get("weight",1.0)))
		if roll<=0.0:return (row as Dictionary).duplicate(true)
	return (rows.back() as Dictionary).duplicate(true)

static func weighted_pick(table:Dictionary,rng:RandomNumberGenerator,kind:String)->Dictionary:
	var rows:Array=[];var total:=0.0
	for row in table.get("entries",[]):
		if not row is Dictionary or str(row.get("kind","npc"))!=kind:continue
		var w:=maxf(0.0,float(row.get("weight",1.0)))
		if w<=0.0:continue
		rows.append(row);total+=w
	if rows.is_empty() or total<=0.0:return {}
	var roll:=rng.randf_range(0.0,total)
	for row in rows:
		roll-=maxf(0.0,float(row.get("weight",1.0)))
		if roll<=0.0:return (row as Dictionary).duplicate(true)
	return (rows.back() as Dictionary).duplicate(true)
static func formation_offsets(tree:SceneTree,formation_id:String,count:int)->Array[Vector3]:
	var out:Array[Vector3]=[]
	if formation_id.is_empty():return out
	var row:=DynamicContentResolver.by_id(tree,"formation",formation_id)
	for value in row.get("offsets",[]):
		if value is Array and value.size()>=2:
			out.append(Vector3(float(value[0]),0.0,float(value[1])))
			if out.size()>=count:break
	return out

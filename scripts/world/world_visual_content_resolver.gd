class_name WorldVisualContentResolver
extends RefCounted
static func island_slots(tree:SceneTree,sector_id:String,region:Dictionary,fallback:Array)->Array:
	var dynamic:Array=[]
	for row in DynamicContentResolver.active_records(tree,"island_visual"):
		var sectors:Array=row.get("sector_ids",[]);var regions:Array=row.get("region_ids",[])
		if not sectors.is_empty() and sector_id not in sectors:continue
		if not regions.is_empty() and str(region.get("id","")) not in regions:continue
		var weight:=maxi(1,int(row.get("weight",1)))
		for _i in weight:dynamic.append(str(row.get("asset_slot",row.get("id",""))))
	if not dynamic.is_empty():return dynamic
	var sector:=WorldSectorRegistry.by_id(sector_id)
	var explicit:Array=sector.get("island_slots",[])
	if not explicit.is_empty():return explicit
	var region_pool:Variant=region.get("island_pool",[])
	if region_pool is Array and not region_pool.is_empty():return region_pool
	var p1_slots:=P1RegionalRuntimeCatalog.island_slots(str(region.get("id","")))
	if not p1_slots.is_empty():return p1_slots
	var canonical:Array=region.get("island_slots",[])
	return canonical if not canonical.is_empty() else fallback
static func harbor_slot(region:Dictionary)->String:
	var dynamic:Variant=region.get("harbor_id","")
	if not str(dynamic).is_empty():return str(dynamic)
	return str(region.get("legacy_harbor_slot",""))
static func visual_budget(compact:bool)->Dictionary:
	return {"max_islands":8,"max_decorators_per_island":8,
		"lod":"LOD1","vfx_quality":"canonical"}

static func dynamic_harbor_slot(tree:SceneTree,sector_id:String,region:Dictionary)->String:
	for row in DynamicContentResolver.active_records(tree,"harbor_visual"):
		var sectors:Array=row.get("sector_ids",[]);var regions:Array=row.get("region_ids",[])
		if not sectors.is_empty() and sector_id not in sectors:continue
		if not regions.is_empty() and str(region.get("id","")) not in regions:continue
		return str(row.get("asset_slot",row.get("id","")))
	return harbor_slot(region)

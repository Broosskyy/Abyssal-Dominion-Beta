extends RefCounted
## M392 island-art registry. All 30 IDs exist as game metadata, but only
## artist-reviewed, checksum-verified texture AND collision pairs can render.
## The default is the existing original coast shape and texture. This must
## not change M376 sailing, M388 transition borders or historic saves.
const EMBEDDED=preload("res://island_asset_embedded.gd")
const REGIONS := ["A","B","C","D","E"]
const SLOT_VARIANTS := [0,1,2,3,4,5,1,3,4]
static var _cache: Dictionary={}

static func catalog() -> Dictionary:
	if _cache.is_empty():
		var parsed: Variant=JSON.parse_string(EMBEDDED.CATALOG_JSON)
		if parsed is Dictionary and int(parsed.get("schema",0))==1:
			_cache=parsed
	return _cache

static func entries() -> Array:
	return catalog().get("items",[])

static func entry(asset_id: String) -> Dictionary:
	for item: Dictionary in entries():
		if str(item.get("id",""))==asset_id:
			return item.duplicate(true)
	return {}

static func island_id(realm_id: int,island_index: int,half: int) -> String:
	if realm_id<1 or realm_id>20 or island_index<0 or island_index>=SLOT_VARIANTS.size() or not half in [0,1]:
		return ""
	var region: String=str(REGIONS[int((realm_id-1)/4)])
	# Distinct locations and layouts come from realm_ecology. The art identity
	# is stable per slot across saves, movement modes and platforms.
	var variant: int=int(SLOT_VARIANTS[island_index])
	if half==1:
		var right_variants := [2,1,4,3,5,0,2,3,5]
		variant=int(right_variants[island_index])
	return "%s%02d" % [region,variant+1]

static func approved_collision(item: Dictionary) -> Dictionary:
	if item.is_empty() or str(item.get("status",""))!="approved" or not bool(item.get("approved",false)):
		return {}
	if not bool(item.get("collision_reviewed",false)):return {}
	var png: String=str(item.get("source_png",""))
	var collision: String=str(item.get("collision_json",""))
	var signature: String=str(item.get("sha256_collision",""))
	# Never allow art-only swaps over the old collision polygon.
	if not png.begins_with("res://assets/m392/islands/") or not collision.begins_with("res://assets/m392/collision/"):return {}
	if signature.length()!=64 or not ResourceLoader.exists(png):return {}
	# Collisions are embedded from exact SHA256-reviewed JSON by the asset
	# sync tool. Never require original .json files inside a signed APK
	# data pack, and never change the native bootstrap export config.
	var records: Variant=JSON.parse_string(EMBEDDED.APPROVED_COLLISIONS_JSON)
	if not records is Dictionary:return {}
	var bundle: Variant=records.get(str(item.get("id","")),{})
	if not bundle is Dictionary or str(bundle.get("sha256",""))!=signature:return {}
	var parsed: Variant=bundle.get("collision",{})
	if not parsed is Dictionary:return {}
	if str(parsed.get("asset_id",""))!=str(item.get("id","")) or not bool(parsed.get("reviewed",false)):return {}
	var dimensions: Variant=parsed.get("size",[])
	var vertices: Variant=parsed.get("points",[])
	if not dimensions is Array or dimensions.size()!=2 or not vertices is Array or vertices.size()<8:return {}
	if float(dimensions[0])<=0.0 or float(dimensions[1])<=0.0:return {}
	for point: Variant in vertices:
		if not point is Array or point.size()!=2:return {}
		if float(point[0])<0.0 or float(point[0])>1.0 or float(point[1])<0.0 or float(point[1])>1.0:return {}
	return {"size":dimensions,"points":vertices}

static func resolve(realm_id: int,island_index: int,half: int,legacy_art: String) -> Dictionary:
	var asset_id: String=island_id(realm_id,island_index,half)
	var descriptor: Dictionary=entry(asset_id) if asset_id!="" else {}
	var response: Dictionary={
		"asset_id":asset_id,
		"size_class":str(descriptor.get("size_class","")),
		"art":legacy_art,
		"texture_path":"",
		"collision":{},
		"approved":false,
		"state":str(descriptor.get("status","unregistered"))
	}
	if descriptor.is_empty():return response
	var reviewed_shape: Dictionary=approved_collision(descriptor)
	if not reviewed_shape.is_empty():
		response.art="m392_"+asset_id.to_lower()
		response.texture_path=str(descriptor.source_png)
		response.collision=reviewed_shape
		response.approved=true
	return response

static func counts() -> Dictionary:
	var data: Dictionary={"total":entries().size(),"approved":0,"pending":0}
	for item: Dictionary in entries():
		if not approved_collision(item).is_empty():
			data.approved=int(data.approved)+1
		else:
			data.pending=int(data.pending)+1
	return data

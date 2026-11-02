class_name GuildVisualMaterialCache
extends RefCounted
static var _cache:Dictionary={}
static func relation(id:String)->StandardMaterial3D:
	if _cache.has(id):return _cache[id]
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=GuildIslandVisualState.RELATION_COLORS.get(id,Color("d7a94f"))
	mat.roughness=0.78
	_cache[id]=mat
	return mat
static func clear()->void:_cache.clear()

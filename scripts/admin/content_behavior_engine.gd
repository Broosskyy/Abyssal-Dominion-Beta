class_name ContentBehaviorEngine
extends RefCounted
const ALLOWED:Array[String]=["damage","status","heal","movement_modifier","barrier","aoe_damage","target_denial","repair_block","recall","spawn","reward","objective","wave","schedule"]
static func validate_components(rows:Array)->PackedStringArray:
	var errors:=PackedStringArray()
	for row in rows:
		if not row is Dictionary:errors.append("component_not_dictionary");continue
		var kind:=str(row.get("kind",""))
		if kind not in ALLOWED:errors.append("unsupported_component:"+kind)
	return errors
static func numeric(row:Dictionary,key:String,fallback:float=0.0)->float:return float(row.get(key,fallback))
static func describe(row:Dictionary)->Dictionary:
	var kind:=str(row.get("kind",""))
	if kind not in ALLOWED:return {}
	return {"kind":kind,"data":row.duplicate(true)}

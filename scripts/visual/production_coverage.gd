class_name ProductionCoverage
extends RefCounted

static func priority_for(kind: String, id: String) -> String:
	if id.begins_with("ship_main_") or id.begins_with("ship_card_main_") or id.begins_with("harbor_module_") or id.begins_with("module_"): return "P1"
	if id.begins_with("ship_") or id.begins_with("npc_") or id.begins_with("island_") or id in ["harbor","cannonball","harpoon"]: return "P0"
	if kind in ["ui","vfx"]: return "P0"
	if kind == "audio": return "P1"
	return "P2"

static func report() -> Dictionary:
	VisualAssetCatalog.ensure_loaded()
	var result := {"total":0,"overrides":0,"missing":0,"p0_missing":0,"p1_missing":0,"p2_missing":0}
	for kind in ["models","ui","vfx","audio"]:
		for id in VisualAssetCatalog.slots.get(kind, {}):
			result.total += 1
			var override: Variant = VisualAssetCatalog.overrides.get(kind, {}).get(id, {})
			var valid := false
			if override is Dictionary:
				var path := str(override.get("path",""))
				valid = not path.is_empty() and ResourceLoader.exists(path)
			if valid:
				result.overrides += 1
			else:
				result.missing += 1
				var priority := priority_for(kind,str(id)).to_lower()
				var key := "%s_missing" % priority
				if result.has(key): result[key] += 1
	return result

static func missing_rows(priority := "") -> Array[Dictionary]:
	VisualAssetCatalog.ensure_loaded()
	var rows: Array[Dictionary] = []
	for kind in ["models","ui","vfx","audio"]:
		for id in VisualAssetCatalog.slots.get(kind, {}):
			var p := priority_for(kind,str(id))
			if not priority.is_empty() and p != priority: continue
			var override: Variant = VisualAssetCatalog.overrides.get(kind, {}).get(id, {})
			var path := str(override.get("path","")) if override is Dictionary else ""
			if path.is_empty() or not ResourceLoader.exists(path):
				rows.append({"priority":p,"kind":kind,"id":str(id),"fallback":str(VisualAssetCatalog.info(kind,str(id)).get("classification",""))})
	return rows

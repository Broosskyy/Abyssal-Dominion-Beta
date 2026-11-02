class_name P0ImportReadiness
extends RefCounted
static func report()->Array[Dictionary]:
	var matrix:=P0ReplacementQa.data()
	var result:Array[Dictionary]=[]
	for row in matrix.get("assets",[]):
		var id:=str(row.get("id",""))
		var fallback:=str(row.get("fallback_path",""))
		var override:=str(row.get("override_path",""))
		var effective:=override if not override.is_empty() else fallback
		var exists:=ResourceLoader.exists(effective)
		var status:="READY_FALLBACK" if override.is_empty() and exists else ("READY_OVERRIDE" if exists else "MISSING")
		result.append({
			"order":int(row.get("order",0)),"id":id,"effective_path":effective,"resource_exists":exists,
			"status":status,"forward_axis":"+Z","waterline":"Y=0","collision":"wrapper_owned",
			"needs_final_art":override.is_empty(),
			"needs_rig_animation":id=="monster_early_01",
			"visual_targets":row.get("m104_visual_targets",{}).duplicate(true)
		})
	return result
static func summary()->Dictionary:
	var rows:=report();var ready:=0;var final_count:=0
	for row in rows:
		if str(row.status).begins_with("READY"):ready+=1
		if str(row.status)=="READY_OVERRIDE":final_count+=1
	return {"total":rows.size(),"resource_ready":ready,"final_overrides":final_count,"fallbacks":rows.size()-final_count}

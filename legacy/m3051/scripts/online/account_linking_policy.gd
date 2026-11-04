class_name AccountLinkingPolicy
extends RefCounted
static func preview_conflicts(guest:Dictionary,target:Dictionary)->Array[String]:
	var result:Array[String]=[]
	if not guest.is_empty():result.append("guest_has_progress")
	if not target.is_empty():result.append("target_account_has_progress")
	var guest_owned:Array=guest.get("owned_ship_ids",[]) if guest.get("owned_ship_ids",[]) is Array else []
	var target_owned:Array=target.get("owned_ship_ids",[]) if target.get("owned_ship_ids",[]) is Array else []
	for id in guest_owned:
		if id in target_owned:
			result.append("ownership_overlap");break
	if str(guest.get("captain_name","")).to_lower()==str(target.get("captain_name","")).to_lower() and not str(guest.get("captain_name","")).is_empty():
		result.append("captain_name_conflict")
	return result
static func can_commit_live()->bool:return false

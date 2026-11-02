class_name ProgressionTrackCatalog
extends RefCounted

static func rows(map_level: int, roster: PlayerShipRoster) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for design in MainProgressionFleet.data().get("designs", []):
		var id := str(design.get("id",""))
		var req := int(design.get("unlock",{}).get("map_level",999))
		var owned := roster.owns_ship(id)
		var eligible := roster.is_main_design_eligible(id)
		var reward := _reward_for_ship(id)
		var state := "OWNED" if owned else ("ELIGIBLE" if eligible else "LOCKED")
		result.append({
			"ship_id":id,
			"display_name":str(design.get("display_name",id)),
			"role":str(design.get("role","")),
			"eligibility_map_level":req,
			"current_map_level":map_level,
			"state":state,
			"owned":owned,
			"eligible":eligible,
			"reward_source":str(reward.get("label","")) if not reward.is_empty() else "",
			"reward_boss_level":int(reward.get("defeated_map_level",-1)) if not reward.is_empty() else -1,
			"reward_recorded":roster.has_reward_history_for_ship(id),
			"visual_slot":str(design.get("visual_slot",id)),
		})
	return result

static func _reward_for_ship(ship_id: String) -> Dictionary:
	for row in MainShipRewardCatalog.data().get("boss_rewards",[]):
		if str(row.get("ship_id","")) == ship_id:
			return row.duplicate(true)
	return {}

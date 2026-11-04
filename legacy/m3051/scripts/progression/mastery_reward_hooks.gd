class_name MasteryRewardHooks
extends RefCounted

const PATH := "res://data/mastery_reward_hooks.json"

static func contract() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}

static func presentation_for(level: int) -> Dictionary:
	var milestone := ShipMasteryCatalog.milestone(level)
	return {
		"level": level,
		"badge_slot": str(milestone.get("presentation_reward", "mastery_badge_%02d" % level)),
		"label": str(milestone.get("label", "Mastery %d" % level)),
		"reward_bound": false,
		"reward_text": str(contract().get("presentation", {}).get("locked_reward_label", "Reward hook prepared")),
	}

static func event_payload(ship_id: String, level: int) -> Dictionary:
	return {
		"event": "mastery_capstone_reached" if level >= ShipMasteryCatalog.max_level() else "mastery_level_reached",
		"ship_id": ship_id,
		"level": level,
		"reward_bound": false,
	}

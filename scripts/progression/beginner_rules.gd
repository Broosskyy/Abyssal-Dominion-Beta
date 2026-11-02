class_name BeginnerRules
extends RefCounted
## M32 local balancing values, not recovered SeeFight server rules.
## Starter designs are separate from the future elite/progression fleet.
const START_SHIP := "barco_low"
const LAST_BEGINNER_LEVEL := 5
const ELITE_MAP_LEVEL := 6 # Provisional, as discussed with the user.
const SHIP_REWARDS := {2: "clipper", 3: "chalupa"}
const GOALS := {"sink": 3, "loot": 2, "dock": 1}
const REWARD_COINS := 300
const REWARD_XP := 120
const BEGINNER_SAVE_VERSION := 2
const LEGACY_SHIP_REWARDS_V1 := {1: "clipper", 5: "chalupa"}

static func reward_ship_for_completed_stage(stage: int) -> String:
	return str(SHIP_REWARDS.get(stage, ""))

static func unlock_text(ship_id: String) -> String:
	if ship_id == START_SHIP: return "Anfangsschiff"
	for stage in SHIP_REWARDS:
		if SHIP_REWARDS[stage] == ship_id:
			return "Anfängerauftrag %d abschließen" % stage
	return "Noch nicht verfügbar"

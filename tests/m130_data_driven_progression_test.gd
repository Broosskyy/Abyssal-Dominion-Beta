extends Node
func _ready()->void:
	var rules:=GameplayRuleset.fallback()
	assert((rules.get("player_progression",{}) as Dictionary).has("upgrade"))
	assert(bool((rules.get("inventory",{}) as Dictionary).get("dynamic_items_allowed",false)))
	assert((rules.get("beginner_trial",{}) as Dictionary).has("goals"))
	assert((rules.get("bonusmaps",{}) as Dictionary).has("abyss"))
	var schemas:=JSON.parse_string(FileAccess.get_file_as_string("res://data/admin_content_type_registry.json"))
	assert((schemas.content_types as Dictionary).has("equipment_module"))
	print("M130_DATA_DRIVEN_PROGRESSION_PASS")

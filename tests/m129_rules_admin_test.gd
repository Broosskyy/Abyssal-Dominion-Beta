extends Node
func _ready()->void:
	var rules:=GameplayRuleset.fallback()
	assert((rules.get("missions",{}) as Dictionary).has("daily_goals"))
	var pkg:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m129_example_admin_event_package.json"))
	assert(ContentPublishValidator.validate_snapshot(pkg).is_empty())
	var rbac:=JSON.parse_string(FileAccess.get_file_as_string("res://data/admin_rbac_contract.json"))
	assert("world.edit" in rbac.permissions and "rules.publish" in rbac.permissions)
	print("M129_RULES_ADMIN_PASS")

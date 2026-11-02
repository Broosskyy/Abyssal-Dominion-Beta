extends Node
func _ready()->void:
	var schemas:=JSON.parse_string(FileAccess.get_file_as_string("res://data/admin_content_type_registry.json"))
	for type_id in ["ship","npc","monster","item","ammo","weapon","harpoon","support","loot_table","quest","encounter","event","shop"]:assert((schemas.content_types as Dictionary).has(type_id))
	assert(ContentBehaviorEngine.validate_components([{"kind":"damage","amount":10}]).is_empty())
	assert(not ContentBehaviorEngine.validate_components([{"kind":"arbitrary_script"}]).is_empty())
	print("M128_DYNAMIC_CONTENT_PASS")

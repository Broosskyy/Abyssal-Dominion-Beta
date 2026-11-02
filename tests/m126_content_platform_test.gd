extends Node
func _ready()->void:
	var r:=AdminContentRegistry.new();add_child(r);await get_tree().process_frame
	for type_id in ["item","ammo","weapon","ship","npc","monster","loot_table","quest","encounter","event","shop","payment_product"]:assert(not r.type_schema(type_id).is_empty())
	var row:=r.create_draft("ship","SHIP-TEST-001","Test Ship");assert(not row.is_empty())
	assert(not r.validate_record(row).is_empty()) # required content fields intentionally still missing
	assert(not AdminModeRuntime.new().production_publish_available())
	print("M126_CONTENT_PLATFORM_PASS")

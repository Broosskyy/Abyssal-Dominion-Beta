extends Node
func _ready() -> void:
	var d := JSON.parse_string(FileAccess.get_file_as_string("res://data/m64_texture_slots.json"))
	assert(d.slots.size() == 8)
	for id in d.slots:
		assert(not str(d.slots[id].fallback).is_empty())
		assert(TextureMaterialCatalog.texture(str(id)) != null)
	print("M64_TEXTURE_MATERIAL_PASS")

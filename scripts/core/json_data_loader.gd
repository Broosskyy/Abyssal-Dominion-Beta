class_name JsonDataLoader
extends RefCounted
## Shared defensive JSON reader used by the data-driven M169+ catalogs.

static func load_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

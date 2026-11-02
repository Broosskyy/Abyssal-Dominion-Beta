class_name ContentDraftStore
extends RefCounted

const PATH := "user://admin/content_drafts_v1.json"
const FORMAT := "abyssal-local-admin-drafts-v1"

static func load_or_seed(seed: Dictionary) -> Dictionary:
	if FileAccess.file_exists(PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary and str((parsed as Dictionary).get("format", "")) == FORMAT:
			return (parsed as Dictionary).duplicate(true)
	var initial := seed.duplicate(true)
	initial["format"] = FORMAT
	initial["authority"] = "LOCAL_PREVIEW_ONLY"
	initial["schema_version"] = 1
	save(initial)
	return initial

static func save(data: Dictionary) -> bool:
	var base_dir := PATH.get_base_dir()
	if not DirAccess.dir_exists_absolute(base_dir):
		DirAccess.make_dir_recursive_absolute(base_dir)
	var temporary := PATH + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)
	return DirAccess.rename_absolute(temporary, PATH) == OK

static func clear_local() -> bool:
	return not FileAccess.file_exists(PATH) or DirAccess.remove_absolute(PATH) == OK

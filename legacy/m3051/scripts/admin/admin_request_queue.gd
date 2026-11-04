class_name AdminRequestQueue
extends RefCounted

const PATH := "user://admin/request_queue_v1.json"
const FORMAT := "abyssal-admin-request-queue-v1"
const MAX_ENTRIES := 100
const SECRET_KEYS := ["authorization", "cookie", "token", "access_token", "refresh_token", "password", "secret", "mfa_code"]

var storage_path := PATH
var entries: Array = []

func _init(target_path := PATH) -> void:
	storage_path = target_path
	_load()

func enqueue(envelope: Dictionary) -> Dictionary:
	for field in ["request_id", "operation", "method", "path", "environment", "permission", "payload"]:
		if not envelope.has(field):
			return {"ok":false, "error":"missing_" + field}
	var request_id := str(envelope.get("request_id", ""))
	for row in entries:
		if row is Dictionary and str(row.get("request_id", "")) == request_id:
			return {"ok":true, "duplicate":true, "request_id":request_id}
	if entries.size() >= MAX_ENTRIES:
		return {"ok":false, "error":"queue_full"}
	var row: Dictionary = _sanitize(envelope) as Dictionary
	row["status"] = "pending"
	row["attempts"] = 0
	row["created_unix"] = int(Time.get_unix_time_from_system())
	row["next_attempt_unix"] = 0
	entries.append(row)
	_save()
	return {"ok":true, "duplicate":false, "request_id":request_id}

func next_ready(now_unix := -1) -> Dictionary:
	var now := int(Time.get_unix_time_from_system()) if now_unix < 0 else now_unix
	for row in entries:
		if row is Dictionary and str(row.get("status", "")) in ["pending", "retry"] and int(row.get("next_attempt_unix", 0)) <= now:
			return (row as Dictionary).duplicate(true)
	return {}

func mark_retry(request_id: String, delay_seconds: int) -> bool:
	for row in entries:
		if row is Dictionary and str(row.get("request_id", "")) == request_id:
			row["status"] = "retry"
			row["attempts"] = int(row.get("attempts", 0)) + 1
			row["next_attempt_unix"] = int(Time.get_unix_time_from_system()) + maxi(0, delay_seconds)
			_save()
			return true
	return false

func remove(request_id: String) -> bool:
	for index in range(entries.size()):
		var row: Variant = entries[index]
		if row is Dictionary and str(row.get("request_id", "")) == request_id:
			entries.remove_at(index)
			_save()
			return true
	return false

func summary() -> Dictionary:
	var retry_count := 0
	for row in entries:
		if row is Dictionary and str(row.get("status", "")) == "retry": retry_count += 1
	return {"count":entries.size(), "retry":retry_count, "authentication_persisted":false, "path":storage_path}

func _sanitize(value: Variant) -> Variant:
	if value is Dictionary:
		var clean := {}
		for key in value:
			if str(key).to_lower() not in SECRET_KEYS:
				clean[key] = _sanitize(value[key])
		return clean
	if value is Array:
		var clean_array := []
		for item in value: clean_array.append(_sanitize(item))
		return clean_array
	return value

func _save() -> void:
	var absolute := ProjectSettings.globalize_path(storage_path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var temporary := absolute + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify({"format":FORMAT, "entries":entries}, "\t"))
	file.close()
	if FileAccess.file_exists(absolute): DirAccess.remove_absolute(absolute)
	DirAccess.rename_absolute(temporary, absolute)

func _load() -> void:
	entries.clear()
	if not FileAccess.file_exists(storage_path): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(storage_path))
	if parsed is Dictionary and str(parsed.get("format", "")) == FORMAT and parsed.get("entries", []) is Array:
		entries = (parsed.get("entries", []) as Array).duplicate(true)

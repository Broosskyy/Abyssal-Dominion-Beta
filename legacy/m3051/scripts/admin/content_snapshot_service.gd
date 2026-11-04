class_name ContentSnapshotService
extends Node

signal snapshot_changed(content_version: String)

var active_snapshot: Dictionary = {}
var content_version := "local-fallback"
var source := "LOCAL"
var server_verified := false

func _ready() -> void:
	add_to_group("content_snapshot_service")
	get_tree().root.set_meta("content_snapshot_version", content_version)
	get_tree().root.set_meta("content_snapshot_verified", false)

func apply_verified_snapshot(snapshot: Dictionary, verified_transport: bool) -> bool:
	if not verified_transport or not _shape_valid(snapshot):
		return false
	active_snapshot = snapshot.duplicate(true)
	content_version = str(snapshot.get("content_version", "unknown"))
	source = str(snapshot.get("environment", "GLOBAL"))
	server_verified = true
	get_tree().root.set_meta("content_snapshot_version", content_version)
	get_tree().root.set_meta("content_snapshot_verified", true)
	snapshot_changed.emit(content_version)
	return true

func clear_to_local() -> void:
	active_snapshot.clear()
	content_version = "local-fallback"
	source = "LOCAL"
	server_verified = false
	get_tree().root.set_meta("content_snapshot_version", content_version)
	get_tree().root.set_meta("content_snapshot_verified", false)
	snapshot_changed.emit(content_version)

func records(type_id: String = "") -> Array:
	var result: Array = []
	var rows: Variant = active_snapshot.get("records", [])
	if not rows is Array:
		return result
	for entry in rows:
		if entry is Dictionary and (type_id.is_empty() or str((entry as Dictionary).get("type", "")) == type_id):
			result.append((entry as Dictionary).duplicate(true))
	return result

func _shape_valid(snapshot: Dictionary) -> bool:
	if str(snapshot.get("format", "")) != "abyssal-content-snapshot-v1":
		return false
	if str(snapshot.get("environment", "")) not in ["TEST", "STAGING", "GLOBAL"]:
		return false
	for field in ["content_version", "generated_at", "records", "asset_slots", "content_hash", "signature"]:
		if not snapshot.has(field):
			return false
	return snapshot.get("records") is Array and snapshot.get("asset_slots") is Dictionary

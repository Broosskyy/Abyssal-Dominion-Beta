class_name AdminModuleRegistry
extends Node

const PATH := "res://data/m143_unified_admin_modules.json"
var modules: Array = []

func _ready() -> void:
	add_to_group("admin_module_registry")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary:
		modules = (parsed as Dictionary).get("modules", []).duplicate(true)

func all_modules() -> Array:
	return modules.duplicate(true)

func visible_modules(authorization: AdminAuthorization, local_preview := false) -> Array:
	var visible: Array = []
	for entry in modules:
		if not entry is Dictionary:
			continue
		var module := entry as Dictionary
		var permission := str(module.get("permission", "admin.access"))
		if local_preview or (authorization != null and authorization.can(permission)):
			visible.append(module.duplicate(true))
	return visible

func by_id(module_id: String) -> Dictionary:
	for entry in modules:
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) == module_id:
			return (entry as Dictionary).duplicate(true)
	return {}

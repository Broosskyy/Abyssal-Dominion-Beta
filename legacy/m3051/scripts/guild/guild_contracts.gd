class_name GuildContracts
extends RefCounted
## M35-M36 contract-only foundation. No membership, treasury, diplomacy or war state is persisted here.
const CONTRACT_PATH := "res://data/guild_contracts.json"
const ISLAND_SLOTS_PATH := "res://data/guild_island_visual_slots.json"

static func read_contracts() -> Dictionary:
	return _read(CONTRACT_PATH)

static func read_island_slots() -> Dictionary:
	return _read(ISLAND_SLOTS_PATH)

static func role_permissions(role_id: String) -> Array:
	var data := read_contracts()
	var roles: Dictionary = data.get("roles", {})
	var result: Variant = roles.get(role_id, [])
	return result.duplicate() if result is Array else []

static func has_permission(role_id: String, permission: String) -> bool:
	return role_permissions(role_id).has(permission)

static func validate() -> Array[String]:
	var errors: Array[String] = []
	var data := read_contracts()
	var island := read_island_slots()
	if data.get("schema", 0) != 1:
		errors.append("guild contract schema")
	if data.get("authority", "") != "contract_only_local_prototype":
		errors.append("guild authority boundary")
	if data.get("live_authority_required", false) != true:
		errors.append("live authority requirement")
	var permissions: Array = data.get("permissions", [])
	for role_id in data.get("roles", {}):
		for permission in data.roles[role_id]:
			if not permissions.has(permission):
				errors.append("unknown permission %s/%s" % [role_id, permission])
	if island.get("schema", 0) != 1 or island.get("mode", "") != "visual_socket_contract_only":
		errors.append("guild island contract schema")
	if island.get("ownership_persistence", true) != false:
		errors.append("guild island must not persist ownership before the authoritative guild backend")
	for required_slot in ["island_base", "harbor", "guild_hall", "warehouse", "repair_station", "walls", "tower_cannon", "tower_mortar", "tower_chain", "tower_guardian", "decoration_layer", "event_layer"]:
		if not island.get("slots", {}).has(required_slot):
			errors.append("missing island slot " + required_slot)
	return errors

static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return {}
	return json.data

class_name GuildWorldHooks
extends RefCounted

const PATH := "res://data/guild_world_hooks.json"

static func read() -> Dictionary:
	if not FileAccess.file_exists(PATH): return {}
	var value = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return value if value is Dictionary else {}

static func empty_context() -> Dictionary:
	return {"guild_id": "", "member_id": "", "alliance_id": "", "war_context_id": ""}

static func attach_identity_meta(node: Node, context: Dictionary) -> void:
	if node == null: return
	for key in ["guild_id", "member_id", "alliance_id", "war_context_id"]:
		var value := str(context.get(key, ""))
		if value.is_empty(): node.remove_meta(key)
		else: node.set_meta(key, value)

static func contribution_event(kind: String, amount: float, context: Dictionary = {}) -> Dictionary:
	var allowed: Array = read().get("contribution_events", [])
	if not allowed.has(kind) or amount <= 0.0: return {}
	return {"kind": kind, "amount": amount, "context": context.duplicate(true), "contract_only": true}

static func validate() -> Array[String]:
	var errors: Array[String] = []
	var data := read()
	if data.get("mode", "") != "compatibility_contract_only": errors.append("guild hook mode")
	if data.get("persistence", true) != false: errors.append("guild hook persistence")
	if data.get("server_authority_required", false) != true: errors.append("guild hook authority")
	if data.get("rules", {}).get("overheal_contribution", -1) != 0: errors.append("guild support contribution")
	return errors

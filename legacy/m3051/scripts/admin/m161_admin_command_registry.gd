class_name M161AdminCommandRegistry
extends Node
signal command_previewed(result: Dictionary)

const PATH := "res://data/m161_admin_command_catalog.json"
var data: Dictionary = {}

func _ready() -> void:
	add_to_group("admin_command_registry")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	data = parsed if parsed is Dictionary else {}

func commands() -> Array:
	return data.get("commands", [])

func definition(command_id: String) -> Dictionary:
	var needle := command_id.trim_prefix("/").to_lower()
	for row in commands():
		if not row is Dictionary: continue
		if str(row.get("id", "")).to_lower() == needle: return (row as Dictionary).duplicate(true)
		for alias in row.get("aliases", []):
			if str(alias).to_lower() == needle: return (row as Dictionary).duplicate(true)
	return {}

func parse(text: String) -> Dictionary:
	var clean := text.strip_edges()
	if not clean.begins_with(str(data.get("prefix", "/"))): return {"ok":false,"error":"not_staff_command"}
	var parts := clean.split(" ", false)
	if parts.is_empty(): return {"ok":false,"error":"empty_command"}
	var def := definition(parts[0])
	if def.is_empty(): return {"ok":false,"error":"unknown_command","command":parts[0]}
	var args: Array = []
	for i in range(1, parts.size()): args.append(parts[i])
	return {"ok":true,"definition":def,"args":args,"raw":clean}

func preview(tree: SceneTree, text: String) -> Dictionary:
	var parsed := parse(text)
	if not bool(parsed.get("ok", false)): return parsed
	var def: Dictionary = parsed.get("definition", {})
	var auth := tree.get_first_node_in_group("admin_authorization") as AdminAuthorization
	var permission := str(def.get("permission", "admin.access"))
	var allowed := auth != null and auth.can(permission)
	var result := {
		"ok":true,"command":str(def.get("id", "")),"permission":permission,"risk":str(def.get("risk", "read")),
		"args":parsed.get("args", []),"authorized":allowed,"server_only":bool(def.get("server_only", true)),
		"requires_confirmation":bool(def.get("confirmation", false)),"description":str(def.get("description", "")),
		"production_execution":"SERVER_REQUIRED"
	}
	command_previewed.emit(result.duplicate(true))
	return result

func build_execution_request(tree: SceneTree, text: String, confirmation_token := "") -> Dictionary:
	var preview_result := preview(tree, text)
	if not bool(preview_result.get("ok", false)): return preview_result
	if not bool(preview_result.get("authorized", false)): return {"ok":false,"error":"permission_denied","preview":preview_result}
	if bool(preview_result.get("requires_confirmation", false)) and confirmation_token.is_empty(): return {"ok":false,"error":"confirmation_required","preview":preview_result}
	var gateway := tree.get_first_node_in_group("content_admin_gateway") as ContentAdminGateway
	if gateway == null: return {"ok":false,"error":"admin_gateway_unavailable"}
	var payload := {"command":preview_result.get("command", ""),"args":preview_result.get("args", []),"confirmation_token":confirmation_token}
	return gateway.build_request("commands.execute", payload, "TEST", "ingame_chat_command")

func summary() -> Dictionary:
	var critical := 0
	for row in commands():
		if row is Dictionary and str(row.get("risk", "")) == "critical": critical += 1
	return {"commands":commands().size(),"critical":critical,"authority":str(data.get("authority", ""))}

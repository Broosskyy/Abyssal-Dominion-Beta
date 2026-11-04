class_name ContentAdminGateway
extends Node

signal request_ready(envelope: Dictionary)
signal response_accepted(operation: String, response: Dictionary)
signal request_cancelled(request_id: String, reason: String)

const CONTRACT_PATH := "res://data/m144_admin_api_contract.json"
var contract: Dictionary = {}
var pending: Dictionary = {}
var transport: AdminHttpTransport
var snapshot_service: ContentSnapshotService

func _ready() -> void:
	add_to_group("content_admin_gateway")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
	contract = parsed if parsed is Dictionary else {}

func operation(operation_id: String) -> Dictionary:
	return ((contract.get("operations", {}) as Dictionary).get(operation_id, {}) as Dictionary).duplicate(true)

func configure(target_transport: AdminHttpTransport, target_snapshots: ContentSnapshotService) -> void:
	transport = target_transport
	snapshot_service = target_snapshots
	if transport != null: transport.bind(self)

func build_request(operation_id: String, payload: Dictionary, environment := "TEST", surface := "ingame_admin") -> Dictionary:
	var definition := operation(operation_id)
	if definition.is_empty():
		return {"ok":false,"error":"unsupported_operation"}
	var request_id := "ADMIN-" + Crypto.new().generate_random_bytes(16).hex_encode()
	var envelope := {
		"request_id":request_id,
		"operation":operation_id,
		"method":str(definition.get("method", "GET")),
		"path":str(definition.get("path", "")),
		"environment":environment,
		"surface":surface,
		"client_version":BuildIdentity.compact(),
		"permission":str(definition.get("permission", "admin.access")),
		"payload":payload.duplicate(true),
		"server_execution_required":bool(definition.get("server_only", false)),
		"server_verified":false
	}
	pending[request_id] = operation_id
	request_ready.emit(envelope.duplicate(true))
	return envelope

func accept_server_response(response: Dictionary, verified_transport: bool) -> bool:
	var request_id := str(response.get("request_id", ""))
	if not verified_transport or not pending.has(request_id) or not bool(response.get("server_verified", false)):
		return false
	for field in ["status", "server_time", "revision", "payload", "audit_event_id"]:
		if not response.has(field):
			return false
	var operation_id := str(pending[request_id])
	if operation_id == "snapshots.current":
		var payload: Variant = response.get("payload", {})
		if not payload is Dictionary or snapshot_service == null or not snapshot_service.apply_verified_snapshot(payload as Dictionary, true):
			return false
	pending.erase(request_id)
	response_accepted.emit(operation_id, response.duplicate(true))
	return true

func cancel_pending(request_id: String, reason: String) -> bool:
	if not pending.has(request_id): return false
	pending.erase(request_id)
	request_cancelled.emit(request_id, reason)
	return true

func transport_status() -> Dictionary:
	var result := transport.status() if transport != null else {"adapter":"NOT_CONNECTED", "production_authority":false}
	result["network_adapter"] = str(result.get("adapter", "NOT_CONNECTED"))
	result["contract_loaded"] = not contract.is_empty()
	result["pending_requests"] = pending.size()
	return result

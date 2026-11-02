class_name AdminHttpTransport
extends Node

signal status_changed(status: Dictionary)

const PROFILE_PATH := "res://data/m145_admin_transport_profiles.json"
var config: Dictionary = {}
var queue := AdminRequestQueue.new()
var gateway: ContentAdminGateway
var http: HTTPRequest
var inflight: Dictionary = {}
var last_event := "OFFLINE_READY"

func _ready() -> void:
	add_to_group("admin_http_transport")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
	config = parsed if parsed is Dictionary else {}
	http = HTTPRequest.new()
	http.timeout = float((config.get("requirements", {}) as Dictionary).get("timeout_seconds", 15))
	add_child(http)
	http.request_completed.connect(_on_request_completed)
	_emit_status()

func bind(target_gateway: ContentAdminGateway) -> void:
	gateway = target_gateway
	if not gateway.request_ready.is_connected(submit): gateway.request_ready.connect(submit)

func submit(envelope: Dictionary) -> Dictionary:
	var environment := str(envelope.get("environment", "TEST"))
	var profile := _profile(environment)
	if environment == "GLOBAL" or bool(profile.get("hard_locked", false)):
		last_event = "GLOBAL_HARD_LOCKED"
		if gateway != null: gateway.cancel_pending(str(envelope.get("request_id", "")), "global_hard_locked")
		_emit_status()
		return {"ok":false, "error":"global_hard_locked"}
	var is_write := str(envelope.get("method", "GET")) != "GET"
	if is_write and bool(profile.get("queue_writes", true)):
		var queued := queue.enqueue(envelope)
		if not bool(queued.get("ok", false)): return queued
	if not _profile_online(environment):
		last_event = "QUEUED_OFFLINE" if is_write else "READ_OFFLINE"
		if not is_write and gateway != null: gateway.cancel_pending(str(envelope.get("request_id", "")), "transport_offline")
		_emit_status()
		return {"ok":is_write, "queued":is_write, "online":false}
	if not inflight.is_empty():
		last_event = "QUEUED_BEHIND_INFLIGHT"
		_emit_status()
		return {"ok":is_write, "queued":is_write}
	return _start(envelope)

func flush() -> Dictionary:
	if not inflight.is_empty(): return {"ok":false, "error":"request_inflight"}
	var envelope := queue.next_ready()
	if envelope.is_empty(): return {"ok":true, "empty":true}
	if not _profile_online(str(envelope.get("environment", "TEST"))):
		last_event = "QUEUE_WAITING_FOR_HTTPS"
		_emit_status()
		return {"ok":false, "error":"transport_offline"}
	return _start(envelope)

func request_snapshot(environment := "TEST") -> Dictionary:
	if gateway == null: return {"ok":false, "error":"gateway_missing"}
	return gateway.build_request("snapshots.current", {}, environment, "ingame_admin")

func status() -> Dictionary:
	var online_profiles := []
	for environment in (config.get("profiles", {}) as Dictionary):
		if _profile_online(str(environment)): online_profiles.append(str(environment))
	return {
		"adapter":"M145_HTTPS_JSON", "online_profiles":online_profiles,
		"inflight":not inflight.is_empty(), "queue":queue.summary(), "last_event":last_event,
		"production_authority":false, "global_hard_locked":true, "authentication_persisted":false
	}

func _start(envelope: Dictionary) -> Dictionary:
	var profile := _profile(str(envelope.get("environment", "TEST")))
	var path := str(envelope.get("path", ""))
	var payload := envelope.get("payload", {}) as Dictionary
	for key in payload:
		path = path.replace("{" + str(key) + "}", str(payload[key]).uri_encode())
	var url := str(profile.get("base_url", "")).trim_suffix("/") + str(config.get("api_base_path", "/api/admin/v1")) + path
	var headers := PackedStringArray(["Accept: application/json", "Content-Type: application/json", "Idempotency-Key: " + str(envelope.get("request_id", ""))])
	var method := _method(str(envelope.get("method", "GET")))
	var body := "" if method == HTTPClient.METHOD_GET else JSON.stringify(envelope)
	var error := http.request(url, headers, method, body)
	if error != OK:
		_schedule_retry(envelope, "request_start_failed")
		return {"ok":false, "error":error_string(error)}
	inflight = envelope.duplicate(true)
	last_event = "REQUEST_INFLIGHT"
	_emit_status()
	return {"ok":true, "online":true}

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var sent := inflight.duplicate(true)
	inflight.clear()
	var response: Variant = JSON.parse_string(body.get_string_from_utf8())
	var accepted := result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300 and response is Dictionary
	if accepted and gateway != null: accepted = gateway.accept_server_response(response as Dictionary, true)
	if accepted:
		queue.remove(str(sent.get("request_id", "")))
		last_event = "SERVER_RESPONSE_ACCEPTED"
	else:
		_schedule_retry(sent, "response_rejected")
	_emit_status()
	call_deferred("flush")

func _schedule_retry(envelope: Dictionary, reason: String) -> void:
	if envelope.is_empty(): return
	var request_id := str(envelope.get("request_id", ""))
	if str(envelope.get("method", "GET")) == "GET":
		if gateway != null: gateway.cancel_pending(request_id, reason)
		last_event = "READ_FAILED"
		return
	var attempts := 0
	for row in queue.entries:
		if row is Dictionary and str(row.get("request_id", "")) == request_id: attempts = int(row.get("attempts", 0))
	var requirements := config.get("requirements", {}) as Dictionary
	var maximum := int(requirements.get("maximum_attempts", 5))
	if attempts >= maximum - 1:
		queue.remove(request_id)
		if gateway != null: gateway.cancel_pending(request_id, "retry_exhausted")
		last_event = "RETRY_EXHAUSTED"
		return
	var delays := requirements.get("retry_delay_seconds", [2,5,15,30,60]) as Array
	var delay := int(delays[mini(attempts, delays.size() - 1)]) if not delays.is_empty() else 5
	queue.mark_retry(request_id, delay)
	last_event = "RETRY_SCHEDULED_" + reason.to_upper()

func _profile(environment: String) -> Dictionary:
	return ((config.get("profiles", {}) as Dictionary).get(environment, {}) as Dictionary)

func _profile_online(environment: String) -> bool:
	var profile := _profile(environment)
	return bool(profile.get("enabled", false)) and not bool(profile.get("hard_locked", false)) and str(profile.get("base_url", "")).begins_with("https://")

func _method(value: String) -> int:
	match value:
		"POST": return HTTPClient.METHOD_POST
		"PATCH": return HTTPClient.METHOD_PATCH
		"PUT": return HTTPClient.METHOD_PUT
		"DELETE": return HTTPClient.METHOD_DELETE
		_: return HTTPClient.METHOD_GET

func _emit_status() -> void:
	status_changed.emit(status())

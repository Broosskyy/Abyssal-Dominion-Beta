extends SceneTree

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func _run() -> void:
	var gateway := ContentAdminGateway.new()
	root.add_child(gateway)
	await process_frame
	assert(gateway.transport_status().contract_loaded)
	assert(gateway.transport_status().network_adapter == "NOT_CONNECTED")
	var request := gateway.build_request("publish", {"id":"BADGE-M144-TEST","revision":2}, "TEST", "ingame_admin")
	assert(request.operation == "publish")
	assert(request.permission == "content.publish")
	assert(request.server_execution_required and not request.server_verified)
	assert(not gateway.accept_server_response({"request_id":request.request_id,"server_verified":true}, true))
	var response := {"request_id":request.request_id,"status":"accepted","server_time":"2026-09-01T00:00:00Z","revision":3,"payload":{},"audit_event_id":"AUDIT-M144-TEST","server_verified":true}
	assert(not gateway.accept_server_response(response, false))
	assert(gateway.accept_server_response(response, true))
	var registry := AdminContentRegistry.new()
	root.add_child(registry)
	await process_frame
	var id := "BADGE-M144-LOCAL-TRANSITION"
	registry.delete_draft(id)
	assert(not registry.create_draft("badge", id, "M144 local transition").is_empty())
	assert(registry.set_local_status(id, "validated"))
	assert(registry.set_local_status(id, "review"))
	assert(not registry.set_local_status(id, "active"))
	assert(registry.delete_draft(id))
	print("M144_ADMIN_ADAPTER_PASS")
	quit()

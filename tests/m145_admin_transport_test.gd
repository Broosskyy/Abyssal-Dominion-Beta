extends SceneTree

var queue_path := "user://m145_transport_test_%d.json" % Time.get_ticks_usec()

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func _run() -> void:
	var queue := AdminRequestQueue.new(queue_path)
	var envelope := {
		"request_id":"M145-QUEUE-ONE", "operation":"publish", "method":"POST",
		"path":"/content/drafts/{id}/publish", "environment":"TEST",
		"permission":"content.publish", "token":"must-not-persist",
		"payload":{"id":"SHIP-TEST", "password":"must-not-persist", "nested":{"mfa_code":"123456", "revision":4}}
	}
	assert(queue.enqueue(envelope).ok)
	assert(queue.enqueue(envelope).duplicate)
	assert(queue.entries.size() == 1)
	var persisted := FileAccess.get_file_as_string(queue_path)
	assert(not persisted.contains("must-not-persist"))
	assert(not persisted.contains("mfa_code"))
	assert(persisted.contains("revision"))
	var snapshots := ContentSnapshotService.new()
	root.add_child(snapshots)
	var gateway := ContentAdminGateway.new()
	root.add_child(gateway)
	var transport := AdminHttpTransport.new()
	root.add_child(transport)
	await process_frame
	transport.queue = AdminRequestQueue.new(queue_path + ".transport")
	gateway.configure(transport, snapshots)
	var global_request := gateway.build_request("publish", {"id":"SHIP-GLOBAL", "revision":1}, "GLOBAL", "ingame_admin")
	assert(not gateway.pending.has(global_request.request_id))
	assert(transport.queue.entries.is_empty())
	var test_request := gateway.build_request("publish", {"id":"SHIP-TEST", "revision":1}, "TEST", "ingame_admin")
	assert(gateway.pending.has(test_request.request_id))
	assert(transport.queue.entries.size() == 1)
	var before_read := transport.queue.entries.size()
	var snapshot_request := transport.request_snapshot("TEST")
	assert(not gateway.pending.has(snapshot_request.request_id))
	assert(transport.queue.entries.size() == before_read)
	assert(gateway.transport_status().global_hard_locked)
	assert(not gateway.transport_status().authentication_persisted)
	_cleanup(queue_path)
	_cleanup(queue_path + ".transport")
	print("M145_ADMIN_TRANSPORT_PASS")
	quit()

func _cleanup(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute): DirAccess.remove_absolute(absolute)
	if FileAccess.file_exists(absolute + ".tmp"): DirAccess.remove_absolute(absolute + ".tmp")

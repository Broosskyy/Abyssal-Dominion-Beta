extends SceneTree

var checks := 0
var failures := 0


func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()


func _check(value: bool, title: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: " + title)


func _run() -> void:
	_check(NetworkProtocol.valid_url("ws://127.0.0.1:9080"), "local WebSocket endpoint")
	_check(NetworkProtocol.valid_url("wss://example.com/probe", true), "secure browser endpoint")
	_check(not NetworkProtocol.valid_url("ws://example.com", true), "HTTPS page blocks insecure socket")
	_check(not NetworkProtocol.valid_url("https://example.com"), "HTTP not accepted as WebSocket")
	_check(not NetworkProtocol.valid_url("wss://user:password@example.com"), "credentials in endpoint rejected")
	_check(NetworkProtocol.valid_hello({"type": "hello", "protocol": 1, "build": "M12"}), "protocol handshake accepted")
	_check(not NetworkProtocol.valid_hello({"type": "hello", "protocol": 2, "build": "M12"}), "protocol mismatch rejected")
	_check(not NetworkProtocol.valid_hello({"type": "hello", "protocol": 1, "build": "M11"}), "build mismatch rejected")
	_check(not NetworkProtocol.valid_hello([]), "malformed handshake rejected")
	var adapter := ReferenceVisualAdapter.new()
	var profile := adapter._profile("clipper")
	_check(profile.meshes.size() == 6, "Clipper includes details and flags")
	_check(profile.meshes[0].texture.ends_with("clipper_hull.png"), "original Clipper hull mapping")
	_check(not profile.meshes[1].has("texture"), "missing sail bitmap is not replaced with unrelated atlas")
	adapter.free()
	for asset in ["clipper_hull.png", "clipper_details.png", "clipper_details.obj", "clipper_flags.obj", "coast_foam.png"]:
		_check(load("res://assets/recovered_test/m12/" + asset) != null, "new original resource loads: " + asset)
	var server := TransportProbeServer.new()
	root.add_child(server)
	_check(server.listen(19080) == OK, "actual TCP listener")
	var first := TransportProbeClient.new()
	var second := TransportProbeClient.new()
	root.add_child(first)
	root.add_child(second)
	_check(first.connect_probe("ws://127.0.0.1:19080") == OK, "first client connects")
	_check(second.connect_probe("ws://127.0.0.1:19080") == OK, "second client connects")
	var deadline := Time.get_ticks_msec() + 4000
	while (first.session_id == 0 or second.session_id == 0) and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(first.session_id > 0 and second.session_id > 0, "both real WebSocket handshakes complete")
	_check(first.session_id != second.session_id, "server assigns distinct probe sessions")
	_check(server.accepted == 2, "two accepted sessions")
	first.disconnect_probe()
	second.disconnect_probe()
	for index in 10:
		await process_frame
	_check(first.session_id == 0 and second.session_id == 0, "disconnect clears local sessions")
	server.stop()
	first.queue_free()
	second.queue_free()
	server.queue_free()
	await process_frame
	print("M12_ENGINE_TESTS: %d/%d passed" % [checks - failures, checks])
	quit(0 if failures == 0 else 1)

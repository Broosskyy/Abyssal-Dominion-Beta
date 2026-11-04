extends SceneTree

var server: TransportProbeServer


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var port := 9080
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--port="):
			port = int(argument.trim_prefix("--port="))
	server = TransportProbeServer.new()
	root.add_child(server)
	var error := server.listen(port)
	if error != OK:
		push_error("Transport probe failed to listen: " + str(error))
		quit(1)
	else:
		print("TRANSPORT PROBE READY ws://127.0.0.1:%d — no shared gameplay" % port)

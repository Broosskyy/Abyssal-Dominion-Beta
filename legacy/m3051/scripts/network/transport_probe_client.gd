class_name TransportProbeClient
extends Node
## Explicit opt-in probe reusable on native and Web. Not game-state replication.

signal welcomed(session_id: int)
signal failed(reason: String)

var socket := WebSocketPeer.new()
var session_id := 0
var endpoint := ""
var _elapsed := 0.0
var _hello_sent := false
var _active := false


func connect_probe(url: String) -> Error:
	var secure_page := false
	if OS.has_feature("web"):
		secure_page = bool(JavaScriptBridge.eval("location.protocol === 'https:'"))
	if not NetworkProtocol.valid_url(url, secure_page):
		return ERR_INVALID_PARAMETER
	disconnect_probe()
	socket = WebSocketPeer.new()
	socket.inbound_buffer_size = 8192
	socket.outbound_buffer_size = 8192
	socket.max_queued_packets = 8
	var error := socket.connect_to_url(url)
	if error != OK:
		return error
	endpoint = url
	_active = true
	_elapsed = 0.0
	_hello_sent = false
	return OK


func disconnect_probe() -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.close(1000, "probe complete")
	_active = false
	session_id = 0


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	socket.poll()
	var state := socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if not _hello_sent:
			socket.send_text(JSON.stringify({"type": "hello", "protocol": NetworkProtocol.VERSION, "build": NetworkProtocol.BUILD}))
			_hello_sent = true
		while socket.get_available_packet_count() > 0:
			var packet := socket.get_packet()
			if packet.size() > NetworkProtocol.MAX_PACKET_BYTES:
				_fail("oversized response")
				return
			var data = JSON.parse_string(packet.get_string_from_utf8())
			if data is Dictionary and data.get("type") == "welcome" and data.get("protocol") == NetworkProtocol.VERSION and data.get("build") == NetworkProtocol.BUILD:
				session_id = int(data.get("session", 0))
				if session_id > 0:
					welcomed.emit(session_id)
	elif state == WebSocketPeer.STATE_CLOSED:
		_fail("connection closed")
	if _active and session_id == 0 and _elapsed > 5.0:
		_fail("handshake timeout")


func _fail(reason: String) -> void:
	disconnect_probe()
	failed.emit(reason)

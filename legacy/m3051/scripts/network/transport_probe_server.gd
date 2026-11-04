class_name TransportProbeServer
extends Node
## Local protocol check; never a production game/account server.

const MAX_CLIENTS := 8
var tcp := TCPServer.new()
var peers: Dictionary = {}
var next_session := 1
var accepted := 0


func listen(port: int, address: String = "127.0.0.1") -> Error:
	return tcp.listen(port, address)


func stop() -> void:
	tcp.stop()
	for entry in peers.values():
		entry.socket.close(1001, "server stopped")
	peers.clear()


func _process(delta: float) -> void:
	if tcp.is_connection_available():
		var stream := tcp.take_connection()
		if peers.size() >= MAX_CLIENTS:
			stream.disconnect_from_host()
		else:
			var peer := WebSocketPeer.new()
			peer.inbound_buffer_size = 8192
			peer.outbound_buffer_size = 8192
			peer.max_queued_packets = 8
			if peer.accept_stream(stream) == OK:
				peers[next_session] = {"socket": peer, "age": 0.0, "greeted": false}
				next_session += 1
	for id in peers.keys():
		var entry: Dictionary = peers[id]
		var peer: WebSocketPeer = entry.socket
		entry.age += delta
		peer.poll()
		if peer.get_ready_state() == WebSocketPeer.STATE_CLOSED:
			peers.erase(id)
			continue
		if entry.age > 5.0 and not entry.greeted:
			peer.close(1008, "hello required")
			peers.erase(id)
			continue
		if peer.get_ready_state() != WebSocketPeer.STATE_OPEN:
			continue
		var packet_budget := 4
		while peer.get_available_packet_count() > 0 and packet_budget > 0:
			packet_budget -= 1
			var packet := peer.get_packet()
			if packet.size() > NetworkProtocol.MAX_PACKET_BYTES or not peer.was_string_packet():
				peer.close(1008, "invalid packet")
				break
			var value = JSON.parse_string(packet.get_string_from_utf8())
			if not entry.greeted and NetworkProtocol.valid_hello(value):
				entry.greeted = true
				accepted += 1
				peer.send_text(JSON.stringify({"type": "welcome", "protocol": NetworkProtocol.VERSION, "build": NetworkProtocol.BUILD, "session": id, "scope": "transport-only"}))
			else:
				peer.close(1008, "unsupported protocol or message")
				break


func _exit_tree() -> void:
	stop()

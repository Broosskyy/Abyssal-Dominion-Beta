extends Node
## Development zone, deliberately loopback-only unless --bind is specified.
const ZONE = preload("res://scripts/network/classic_zone.gd")
var zone := ZONE.new()
var tcp := TCPServer.new()
var peers: Dictionary = {}
var serial := 1
var accumulator := 0.0
var broadcast_clock := 0.0
func _ready() -> void:
	var address := "127.0.0.1"
	var port := 9080
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--port="): port = int(arg.trim_prefix("--port="))
		if arg.begins_with("--bind="): address = arg.trim_prefix("--bind=")
	var err := tcp.listen(port,address)
	if err != OK:
		push_error("Zone listen failed: %s" % error_string(err))
		get_tree().quit(1)
		return
	print("ZONE_READY ws://%s:%d (development guests, no persistence)" % [address,port])
func _process(delta: float) -> void:
	while tcp.is_connection_available():
		var stream := tcp.take_connection()
		if peers.size() >= 32:
			stream.disconnect_from_host()
			continue
		serial += 1
		var ws := WebSocketPeer.new()
		ws.inbound_buffer_size = 8192
		ws.max_queued_packets = 32
		ws.accept_stream(stream)
		peers[serial] = {"ws":ws,"joined":false,"window":0.0,"count":0,"routes":0,"age":0.0,"idle":0.0}
	for id in peers.keys():
		var slot: Dictionary = peers[id]
		var ws: WebSocketPeer = slot.ws
		ws.poll()
		slot.age += delta
		slot.idle += delta
		slot.window += delta
		if float(slot.window) >= 1:
			slot.window = 0.0
			slot.count = 0
			slot.routes = 0
		if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			if not slot.joined:
				slot.joined = true
				zone.join(id)
				ws.send_text(JSON.stringify({"type":"welcome","id":id,"protocol":1,"event_serial":zone.serial}))
			while ws.get_available_packet_count() > 0:
				var bytes := ws.get_packet()
				slot.idle = 0.0
				slot.count += 1
				if bytes.size() > 2048 or int(slot.count) > 24:
					ws.close(1008,"command budget")
					break
				var cmd: Variant = JSON.parse_string(bytes.get_string_from_utf8())
				if cmd is Dictionary:
					if cmd.get("op") == "move":
						slot.routes += 1
						if int(slot.routes) > 4: continue
					zone.command(id,cmd)
		if ws.get_ready_state() == WebSocketPeer.STATE_CLOSED or (not slot.joined and float(slot.age)>8) or float(slot.idle)>120:
			ws.close()
			peers.erase(id)
			zone.players.erase(id)
			for key in zone.drops.keys():
				if int(zone.drops[key].owner) == id: zone.drops.erase(key)
	accumulator = minf(accumulator+delta,0.25)
	while accumulator >= 0.05:
		zone.step(0.05)
		accumulator -= 0.05
	broadcast_clock += delta
	if broadcast_clock >= 0.1:
		broadcast_clock = 0.0
		var payload := JSON.stringify(zone.snapshot())
		for slot in peers.values():
			if slot.joined and slot.ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
				slot.ws.send_text(payload)

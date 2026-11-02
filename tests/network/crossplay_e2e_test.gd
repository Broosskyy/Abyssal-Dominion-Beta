extends SceneTree
var failed: Array[String] = []
var observer := WebSocketPeer.new()
var game: Node3D
var observed: Dictionary = {}
var other_id := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok:failed.append(label)
func wait_seconds(seconds: float) -> void:
	var end := Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<end:
		observer.poll()
		while observer.get_available_packet_count()>0:
			var data: Variant = JSON.parse_string(observer.get_packet().get_string_from_utf8())
			if data is Dictionary:
				if data.get("type")=="welcome":other_id=int(data.id)
				if data.get("type")=="snapshot":observed=data
		await process_frame
func run() -> void:
	root.size=Vector2i(844,390)
	root.set_meta("m3035_graphic_mode","original_fleet")
	var server := load("res://scenes/network/zone_server.tscn").instantiate() as Node
	root.add_child(server)
	root.set_meta("zone_url","ws://127.0.0.1:9080")
	game=load("res://scenes/network/crossplay_chart.tscn").instantiate()
	root.add_child(game)
	observer.connect_to_url("ws://127.0.0.1:9080")
	await wait_seconds(1.0)
	check(game.player_id>0 and other_id>0,"two websocket clients welcomed")
	check(game.received_snapshots>2,"production Godot client receives real snapshots")
	check(game.other_ships.size()==1,"other captain visible in production chart")
	check(observed.get("players",[]).size()==2,"observer receives same shared population")
	game._course(Vector3(12,0.65,0))
	await wait_seconds(1.8)
	check(absf(game.ship.position.x-12)<0.4,"real client sends course and follows confirmed server position")
	var remote_x := -1000.0
	for p in observed.get("players",[]):
		if int(p.id)==game.player_id:remote_x=float(p.x)
	check(absf(remote_x-12)<0.2,"observer sees the same confirmed movement")
	game._send("target",{"target":0})
	game._send("ammo",{"mode":"cannon"})
	game._send("fire",{"enabled":true,"hp":99999,"gold":99999})
	await wait_seconds(6.1)
	check(game.enemies[0].hp==0,"shared NPC sunk by server-confirmed cannon fire")
	check(game.cannonballs==95,"server ammunition reaches client")
	check(game.gold==0 and game.hull<=100,"client payload cannot mint gold or HP")
	check(int(observed.npcs[0].hp)==0,"both clients agree on enemy HP")
	game._course(Vector3(-13,0.65,-25))
	await wait_seconds(3.7)
	check(game.gold==50,"server-owned loot collection reflected in production HUD")
	check(observed.drops.is_empty(),"collected drop removed for all clients")
	observer.close()
	await wait_seconds(0.2)
	game.queue_free()
	server.queue_free()
	await process_frame
	print(JSON.stringify({"test":"crossplay_e2e","engine":Engine.get_version_info().string,"status":"PASS" if failed.is_empty() else "FAIL","failed":failed,"scope":"Godot chart plus second real WebSocket client; local transport, not physical devices/browser exports"}))
	quit(0 if failed.is_empty() else 1)

extends SceneTree
var done:=false
var authenticated:=false
var received:=false
var moved:=false
var count:=0
var failures: Array[String]=[]
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var client=load("res://network_client.gd").new();root.add_child(client);await process_frame
	client.server_url="http://127.0.0.1:8787"
	client.auth_completed.connect(func(ok: bool,_message: String):authenticated=ok;done=true)
	client.authenticate("crossplay-%d@example.com" % Time.get_ticks_usec(),"fixture-passphrase-937","CrossplayCaptain",true)
	for _i in 150:
		if done:break
		await create_timer(.02).timeout
	count+=1
	if not authenticated:failures.append("Godot HTTP registration failed")
	client.snapshot_received.connect(func(value: Dictionary):
		if value.get("type")=="snapshot":
			received=true
			for player: Dictionary in value.get("players",[]):
				if str(player.id)==str(client.account.get("id","")) and float(player.x)>2100.1:moved=true)
	if authenticated:
		client.connect_world(0)
		for _i in 150:
			if received:break
			await create_timer(.02).timeout
		count+=1
		if not received:failures.append("Godot WebSocket snapshot failed")
		client.send_course(Vector2(2300,1600))
		for _i in 100:
			if moved:break
			await create_timer(.02).timeout
		count+=1
		if not moved:failures.append("Godot course did not produce authoritative movement")
	client.sign_out();count+=1
	if has_meta("abyssal_session"):failures.append("session remained after logout")
	client.queue_free();await process_frame
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures,"real_http_websocket":true}));quit(0 if failures.is_empty() else 1)

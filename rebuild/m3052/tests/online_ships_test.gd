extends SceneTree
var failures: Array[String]=[]
var checks: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var clients: Array=[]
	for index in 2:
		var client=load("res://network_client.gd").new()
		root.add_child(client)
		await process_frame
		client.sign_out()
		client.server_url="http://127.0.0.1:8787"
		client.authenticate("ships-%d-%d@example.com" % [Time.get_ticks_usec(),index],"fixture-passphrase-937","Captain%d" % index,true)
		for attempt in 150:
			if not client.token.is_empty():break
			await create_timer(.02).timeout
		check(not client.token.is_empty(),"Godot account %d authenticated" % index)
		clients.append(client)
	if has_meta("abyssal_session"):remove_meta("abyssal_session")
	var game=load("res://sea_map.tscn").instantiate()
	game.browser_classic=OS.get_cmdline_user_args().has("--browser")
	root.add_child(game)
	current_scene=game
	await process_frame
	game.online_client=clients[0]
	clients[0].snapshot_received.connect(game._online_snapshot)
	clients[0].connection_changed.connect(game._online_connection_changed)
	clients[0].connect_world(game.sim.map_id)
	clients[1].connect_world(game.sim.map_id)
	for attempt in 150:
		if game.online_players.size()==1 and clients[1].joined:break
		await create_timer(.02).timeout
	check(game.online_players.size()==1,"second captain becomes a real ship actor")
	if game.online_players.size()==1:
		var remote: Dictionary=game.online_players[0]
		check(remote.remote_player and int(remote.id)<0,"remote identity cannot collide with NPC combat ids")
		check(game._actor_visual_length(remote)==game._actor_visual_length(game.sim.player),"same hull scale as local captain")
		clients[1].send_appearance(13,1200,2400)
		clients[1].send_course(Vector2(4200,3000))
		await create_timer(.6).timeout
		remote=game.online_players[0]
		check(int(remote.skin)==13 and int(remote.hp)==1200,"live design and HP reach the game actor")
		check(game._classic_atlas_key(remote)=="event_columbus","browser resolves correct eight-view design")
		if not game.browser_classic:
			check(game.mesh_layer.can_render_actor(remote),"native renderer admits the remote player hull")
			check(game.mesh_layer.model_instances.has(int(remote.id)),"native remote GLB is instantiated in the visible fleet")
		elif game.classic_atlases.has("event_columbus"):
			check(game.classic_atlases.event_columbus!=null,"browser remote uses a loaded atlas")
		check(Vector2(remote.pos).y>2900 and Vector2(remote.heading).y>.9,"remote hull moves and faces its course")
		var mesh=load("res://ship_mesh_layer.gd").new()
		check(mesh.player_key_for_skin(int(remote.skin))=="black_crown_corsair_elite_test" and mesh.elite_texture_level(int(remote.skin))==12,"native renderer resolves same hull and finish")
		mesh.free()
		var before: Vector2=game.sim.player.pos
		game.sim.player.path=[before+Vector2(80,0)]
		game._send_online_course(before+Vector2(80,0))
		await create_timer(.6).timeout
		check(game.sim.player.pos.x>before.x+20,"own hull follows the shared server position")
	clients[1].leave_world()
	await create_timer(.2).timeout
	check(game.online_players.is_empty(),"departed captain disappears")
	clients[0].leave_world()
	check(not bool(game.sim.player.get("network_motion",true)),"disconnect restores guest movement")
	for client in clients:client.queue_free()
	game.queue_free()
	await process_frame
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"two_real_godot_clients":true}))
	quit(0 if failures.is_empty() else 1)

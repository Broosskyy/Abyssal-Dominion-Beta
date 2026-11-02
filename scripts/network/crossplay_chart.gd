extends "res://scripts/classic/m3049_mobile_user_art_import.gd"
## Presentation-only adapter: local authority loop is intentionally never called.
var socket := WebSocketPeer.new()
var player_id := 0
var command_seq := 0
var last_event := 0
var other_ships: Dictionary = {}
var network_drops: Dictionary = {}
var confirmed: Dictionary = {}
var targets: Dictionary = {}
var snapshot_clock := 0.0
var keepalive := 0.0
var received_snapshots := 0
var _online_banner: Label
var _return_button: Button

func _ready() -> void:
	super._ready()
	_hud_header.text = "ABYSSAL DOMINION · CROSSPLAY TEST"
	_build_label.text = "M3050 · Gast-Testserver · kein dauerhafter Spielstand"
	# These local progression actions are not part of the zone protocol yet.
	for control in [_quest_frame,_quest_title,_quest_progress,_quest_claim,_dock_quick_button,_coating_button]:
		control.hide()
	_online_banner = _label(_ui_root,"VERBINDUNG WIRD HERGESTELLT",14)
	_online_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_online_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_return_button = _control("ZURÜCK",_leave_zone)
	_return_button.name = "LeaveZone"
	get_viewport().size_changed.connect(_layout_online)
	_layout_online()
	var url := str(get_tree().root.get_meta("zone_url","ws://127.0.0.1:9080"))
	var err := socket.connect_to_url(url)
	if err != OK:
		hint = "Verbindung nicht möglich: %s" % error_string(err)
		_online_banner.text = hint
	_refresh()

func _layout_online() -> void:
	if _online_banner == null: return
	var s := get_viewport().get_visible_rect().size
	_online_banner.add_theme_font_size_override("font_size",12)
	_place(_online_banner,s.x-430,8,210,24)
	_place(_return_button,8,_hud_player_frame.get_rect().end.y+8,110,36)

func _send(op: String, payload: Dictionary = {}) -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN or player_id == 0: return
	command_seq += 1
	var cmd := payload.duplicate()
	cmd["op"] = op
	cmd["seq"] = command_seq
	socket.send_text(JSON.stringify(cmd))

func _process(delta: float) -> void:
	if camera == null: return
	socket.poll()
	keepalive += delta
	snapshot_clock += delta
	if keepalive > 30 and player_id != 0:
		keepalive = 0
		_send("hello",{"name":"Kapitän %d" % player_id})
	while socket.get_available_packet_count() > 0:
		var packet: Variant = JSON.parse_string(socket.get_packet().get_string_from_utf8())
		if not packet is Dictionary: continue
		if packet.get("type") == "welcome":
			player_id = int(packet.id)
			last_event = int(packet.get("event_serial",0))
			_send("hello",{"name":"Kapitän %d" % player_id})
		if packet.get("type") == "snapshot":
			_apply_snapshot(packet)
	if socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		_online_banner.text = "GETRENNT · zum Startmenü zurückkehren"
	elif snapshot_clock > 5 and player_id != 0:
		_online_banner.text = "VERBINDUNG UNTERBROCHEN · warte auf Server"
	for key in targets:
		var node: Node3D = get_node_or_null(NodePath(str(key)))
		if node != null:
			var point: Vector3 = targets[key]
			node.position = node.position.lerp(point,minf(1,delta*16))
	var center := ship.global_position + pan
	camera.global_position = camera.global_position.lerp(center+OFFSET,minf(1,delta*4))
	camera.look_at(center)
	camera.size = lerpf(camera.size,zoom,minf(1,delta*7))
	mini.set("player_position",Vector2(ship.position.x,ship.position.z))
	mini.set("islands",islands)
	var dots: Array[Vector2] = []
	for enemy in enemies:
		if int(enemy.hp)>0: dots.append(Vector2(enemy.node.position.x,enemy.node.position.z))
	for actor in other_ships.values(): dots.append(Vector2(actor.position.x,actor.position.z))
	mini.set("enemies",dots)
	mini.queue_redraw()
	if _target_ring != null:
		_target_ring.visible = target >= 0 and target < enemies.size() and int(enemies[target].hp)>0
		if _target_ring.visible: _target_ring.position = enemies[target].node.position + Vector3(0,0.16,0)

func _apply_snapshot(data: Dictionary) -> void:
	received_snapshots += 1
	snapshot_clock = 0
	var alive: Array[int] = []
	for p in data.players:
		var id := int(p.id)
		alive.append(id)
		var actor: Node3D
		if id == player_id:
			actor = ship
			confirmed = p.duplicate(true)
			hull = int(p.hp)
			gold = int(p.gold)
			kills = int(p.kills)
			cannonballs = int(p.ammo[0])
			harpoons = int(p.ammo[1])
			chainballs = int(p.ammo[2])
			weapon_mode = str(p.mode)
			target = int(p.target)
			firing = bool(p.firing)
			hint = str(p.message)
			_sea_speed = 11.0 if p.moving else 0.0
		else:
			if not other_ships.has(id):
				actor = _asset(SHIP,Vector3(p.x,0.65,p.z),0.9,"PlayerShip",CAPTAIN_ATLAS)
				actor.name = "Peer_%d" % id
				_nameplate(actor,str(p.name),Color("7ee3df"))
				other_ships[id] = actor
			actor = other_ships[id]
		actor.visible = int(p.hp)>0
		targets[str(actor.name)] = Vector3(p.x,0.65,p.z)
		actor.rotation.y = float(p.yaw)
		_update_actor_art(actor,p)
	for id in other_ships.keys():
		if id not in alive:
			targets.erase(str(other_ships[id].name))
			other_ships[id].queue_free()
			other_ships.erase(id)
	for i in mini(data.npcs.size(),enemies.size()):
		var n: Dictionary = data.npcs[i]
		var actor: Node3D = enemies[i].node
		actor.position = Vector3(n.x,0.65,n.z)
		enemies[i].hp = int(n.hp)
		actor.visible = int(n.hp)>0
		_update_actor_art(actor,{"hp":n.hp,"max_hp":n.max_hp,"yaw":actor.rotation.y,"moving":false})
	for key in data.drops:
		if network_drops.has(key): continue
		var d: Dictionary = data.drops[key]
		var index := loot_items.size()
		_create_loot(Vector3(d.x,0.65,d.z),int(d.gold))
		network_drops[key] = loot_items[index].node
		loot_items.remove_at(index)
	for key in network_drops.keys():
		if not data.drops.has(key):
			network_drops[key].queue_free()
			network_drops.erase(key)
	for event in data.events:
		if int(event.id) <= last_event: continue
		last_event = int(event.id)
		var victim: Node3D = enemies[int(event.target)].node
		if victim.visible:
			_spawn_shot(Vector3(event.x,2.6,event.z),victim,Color("ffd38c"),Callable(self,"_network_hit").bind(victim.position,int(event.damage)),event.mode == "harpoon")
	_online_banner.text = "ONLINE · %d KAPITÄNE" % data.players.size()
	_refresh()

func _update_actor_art(actor: Node3D, state: Dictionary) -> void:
	for child in actor.get_children():
		if child.has_method("set_heading"): child.set_heading(float(state.yaw))
		if child.has_method("set_moving"): child.set_moving(bool(state.moving))
		if child.has_method("set_hull_ratio"): child.set_hull_ratio(float(state.hp)/float(state.get("max_hp",100)))

func _network_hit(at: Vector3, damage: int) -> void:
	_damage_number(at,str(damage),Color("ffd38c"))
	_impact_flash(at,Color("ffcf8b"))

func _course(point: Vector3) -> void:
	_send("move",{"x":point.x,"z":point.z})
func _world_click(screen: Vector2) -> void:
	# Reuse screen projection/selection only; _course is a server command.
	var before := target
	super._world_click(screen)
	if target != before:
		_send("target",{"target":target})
		_send("fire",{"enabled":false})
func _toggle_fire() -> void:
	_send("target",{"target":target})
	_send("fire",{"enabled":not firing})
func _select_ammo(mode: String) -> void:
	_send("ammo",{"mode":mode})
func _select_chain() -> void:
	_send("ammo",{"mode":"chain"})
func _repair() -> void:
	_send("repair")
func _buy_ammunition(index: int) -> void:
	_send("buy",{"item":index})
func _restock_chain() -> void:
	_send("buy",{"item":2})
func _purchase_or_equip(_index: int) -> void:
	hint = "Werftausbau folgt nach dem Netzwerktest"
	_refresh()
func _claim_quest() -> void:
	pass
func _leave_zone() -> void:
	socket.close()
	get_tree().change_scene_to_file("res://scenes/network/start_menu.tscn")
func _exit_tree() -> void:
	socket.close()

func _refresh() -> void:
	super._refresh()
	if _online_banner != null and status != null:
		status.text = "GEMEINSAME TESTKARTE · RUMPF %d/100 · GOLD %d\n%s" % [hull,gold,hint]

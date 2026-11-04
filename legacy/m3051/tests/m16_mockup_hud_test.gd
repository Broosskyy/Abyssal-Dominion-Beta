extends SceneTree

var checks := 0
var failures := 0
var samples := []

func _initialize() -> void:
	root.set_meta("reconstruction_test_mode", true)
	_run.call_deferred()

func _check(value: bool, title: String) -> void:
	checks += 1
	if not value:
		failures += 1
		print("FAIL: " + title)

func _frames() -> void:
	for i in 5:
		await process_frame

func _touch(input: PlayerShipInput, id: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = point
	event.pressed = pressed
	input._unhandled_input(event)

func _mouse(input: PlayerShipInput, point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = point
	input._unhandled_input(event)

func _run() -> void:
	for extent in [Vector2(1536, 1024), Vector2(1280, 720), Vector2(844, 390), Vector2(915, 412), Vector2(390, 844)]:
		var safe := Rect2(Vector2.ZERO, extent)
		var geometry := NauticalLayout.calculate(safe)
		var ids: Array = geometry.actions.keys()
		for id in ids:
			var rect: Rect2 = geometry.actions[id]
			_check(safe.encloses(rect), "control inside viewport " + str(extent) + id)
			_check(rect.size.x >= 48 and rect.size.y >= 48, "48px target " + id)
			_check(NauticalLayout.action_at(rect.get_center(), geometry) == id, "paint and hit test agree " + id)
		for a in ids.size():
			for b in range(a + 1, ids.size()):
				_check(not (geometry.actions[ids[a]] as Rect2).intersects(geometry.actions[ids[b]]), "nonoverlapping targets %s/%s %s" % [ids[a], ids[b], extent])
		_check(not NauticalLayout.blocks_world(Vector2(extent.x * 0.5, extent.y * 0.5), geometry), "central sea stays interactive " + str(extent))
		samples.append({"viewport": [extent.x, extent.y], "controls": geometry.actions, "central_sea": true})
	var safe := Rect2(0, 0, 1000, 800)
	var ship_box := Rect2(400, 300, 160, 180)
	var label := NauticalLayout.nameplate_box(ship_box, Vector2(160, 43), safe, [], true)
	_check(label.position.y > ship_box.end.y and not label.intersects(ship_box), "player label below actual bounds")
	var alternative := NauticalLayout.nameplate_box(ship_box, Vector2(160, 43), safe, [label], true)
	_check(alternative.end.y < ship_box.position.y, "blocked player label moves above hull")
	_check(not NauticalLayout.nameplate_box(ship_box, Vector2(160, 43), safe, [safe], true).has_area(), "no forced label/UI overlap")
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await _frames()
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(844, 390)
	await _frames()
	var world: WorldMapSystem = game.get_node("WorldMapSystem")
	world.set_process(false)
	world.encounters.set_process(false)
	var player := world.player
	player.set_physics_process(false)
	player.set_meta("in_safe_zone", false)
	var input: PlayerShipInput = player.get_node("PlayerInput")
	input.set_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.get_node("EnemyAI").set_process(false)
	var hud: GameHud = game.get_node("HUDLayer/GameHUD")
	var inventory: PlayerInventory = player.get_node("Inventory")
	var weapons: ShipWeapons = player.get_node("Weapons")
	var geometry := hud.layout()
	var ammo := inventory.count("iron")
	var sea := Vector2(620, 205)
	_mouse(input, sea)
	_check(input.has_navigation_target, "right-side sea click navigates")
	_check(inventory.count("iron") == ammo, "no invisible right-half fire zone")
	input.cancel_navigation()
	_mouse(input, (geometry.mission as Rect2).get_center())
	_check(not input.has_navigation_target, "mission panel does not steer")
	_touch(input, 0, (geometry.wheel as Rect2).get_center(), true)
	_check(input.joystick_visible, "visible wheel starts steering")
	weapons.last_shot_time = -99
	_touch(input, 1, (geometry.actions.fire as Rect2).get_center(), true)
	_touch(input, 1, (geometry.actions.fire as Rect2).get_center(), false)
	_check(inventory.count("iron") == ammo - inventory.volley_size(), "fire button works while steering")
	_check(input.joystick_visible and not input.pinch_active, "steer + fire is not mistaken for pinch")
	_touch(input, 0, (geometry.wheel as Rect2).get_center(), false)
	_check(not input.joystick_visible, "wheel release stops steering")
	var stock := inventory.count("iron")
	weapons.last_shot_time = -99
	_touch(input, 2, (geometry.actions.fire as Rect2).get_center(), true)
	_touch(input, 2, (geometry.actions.fire as Rect2).get_center() + Vector2(-70, -70), false)
	_check(inventory.count("iron") == stock, "drag off fire cancels action")
	_mouse(input, (geometry.actions.ammo_2 as Rect2).get_center())
	_check(weapons.ammo_index == 2, "ammo circle selects actual chain loadout")
	_mouse(input, (geometry.actions.minimap as Rect2).get_center())
	_check(hud.global_map_open and not input.has_navigation_target, "round minimap opens map and cancels course")
	_mouse(input, sea)
	_check(not hud.global_map_open and not input.has_navigation_target, "map dismissal does not steer")
	_touch(input, 4, Vector2(350, 220), true)
	_touch(input, 5, Vector2(480, 220), true)
	_check(input.pinch_active, "two world fingers still pinch")
	_touch(input, 4, Vector2(350, 220), false)
	_touch(input, 5, Vector2(480, 220), false)
	_check(not input.has_navigation_target, "pinch release does not start navigation")
	var ui: ArsenalPanel = game.get_node("HUDLayer/ArsenalPanel")
	_check(ui.opener.get_global_rect() == geometry.actions.arsenal, "native arsenal shares exact layout")
	_check(player.has_meta("hud_visual_bounds"), "real recovered model bounds cached")
	if hud._nameplate_rects.is_empty():
		print("PLATE DEBUG bounds=", player.get_meta("hud_visual_bounds"), " player=", player.position, " camera=", get_root().get_camera_3d().global_position)
	_check(hud._nameplate_rects.size() > 0, "runtime projects nameplates")
	game.queue_free()
	await _frames()
	await create_timer(0.2).timeout
	var file := FileAccess.open("res://docs/m16_hud_layout_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"mode": "headless geometry/input, not screenshot validation", "samples": samples}, "\t"))
	file.close()
	print("M16_ENGINE_TESTS: %d/%d passed" % [checks - failures, checks])
	quit.call_deferred(0 if failures == 0 else 1)

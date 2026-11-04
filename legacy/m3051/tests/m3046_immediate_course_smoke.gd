extends SceneTree
## M304.6 regression: immediate click movement without turn/acceleration wait.
var failures: Array[String] = []

func check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	# CI stages the real existing local SeaBattles test sprite sheets.
	if root.has_meta("m3035_graphic_mode"):
		root.remove_meta("m3035_graphic_mode")
	var scene_data := load("res://scenes/classic/classic_sea_map.tscn") as PackedScene
	check(scene_data != null, "M304.6 scene parses")
	if scene_data == null:
		_finish()
		return
	var game: Node3D = scene_data.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var current_script: Script = game.get_script()
	var has_instant_course := false
	while current_script != null:
		if current_script.resource_path.ends_with("m3046_direct_course_reference_default.gd"):
			has_instant_course = true
			break
		current_script = current_script.get_base_script()
	check(has_instant_course, "immediate tap steering remains active under the ship integrity upgrade")
	check(game._asset_mode == "private_sprite",
		"test build with extracted SeaBattles PNG pack defaults to real reference sprites")
	check(game.ship.get_node_or_null("ShipSprite") != null,
		"ship is real integrated reference sprite, not low-poly fallback")
	check(game.camera.size <= 60.0, "closer default zoom for readable ships")
	game.ship.rotation.y = 0.0
	var before: Vector3 = game.ship.position
	var goal := before + Vector3(24.0, 0.0, 0.0)
	game._course(goal)
	check(not game.route.is_empty(), "tap computes course immediately")
	check(game._sea_speed >= game.SEA_MAX_SPEED - 0.01,
		"tap sets full speed rather than waiting for the bow to turn")
	check(absf(angle_difference(game.ship.rotation.y, -PI / 2.0)) < 0.05,
		"visible ship points directly along new course")
	game._sail(0.016)
	check(game.ship.position.x > before.x + 0.05,
		"ship travels on the very first movement frame")
	check(game._sea_speed >= game.SEA_MAX_SPEED - 0.01,
		"no acceleration or turn-related speed reduction after start")
	var first: Vector3 = game.ship.position
	game._course(first + Vector3(-29.0, 0.0, 0.0))
	check(game.ship.rotation.y > 1.4 or game.ship.rotation.y < -4.7,
		"opposite tap changes heading immediately without turning arc")
	game._sail(0.016)
	check(game.ship.position.x < first.x - 0.05,
		"reversed direction moves immediately on next frame")
	check(game.ship.position.distance_to(first) <= game.SEA_MAX_SPEED * 0.016 + 0.01,
		"speed step is bounded by delta seconds")
	var expected_ship_id: int = game.ship.get_instance_id()
	var hp: int = game.hull
	var money: int = game.gold
	game._switch_graphics()
	check(game._asset_mode == "seaofbones_sprite", "Sea of Bones reference sprites remain selectable")
	check(game.ship.get_instance_id() == expected_ship_id,
		"graphic pack change preserves ship identity")
	game._switch_graphics()
	check(game._asset_mode == "private_sprite", "SeaBattles test graphics restored")
	check(game.hull == hp and game.gold == money, "pack switch preserves gameplay resources")
	check(game._ammo_panel != null and game._yard_panel != null,
		"ammunition and shipyard controls remain active")
	_finish()

func _finish() -> void:
	print(JSON.stringify({
		"status": "PASS" if failures.is_empty() else "FAIL",
		"version": "M304.6",
		"scope": "reference sprites default, direct tap full-speed movement, immediate reverse, retained route planner, ship identity, UI",
		"failed": failures
	}))
	quit(0 if failures.is_empty() else 1)

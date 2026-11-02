extends SceneTree
## Exercise every live ship, including additional patrols beyond NPC_4.
var failures: Array[String] = []
var examined := 0
var sources: Dictionary = {}

func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.set_meta("m3035_graphic_mode", "private_sprite")
	var packed := load("res://scenes/classic/classic_sea_map.tscn") as PackedScene
	check(packed != null, "local sea chart loads")
	if packed == null:
		_finish()
		return
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	_check_ship(game.ship, "PlayerShip")
	var extra_patrols := 0
	for i in game.enemies.size():
		var entry: Dictionary = game.enemies[i]
		if str(entry.get("kind", "")) != "ship":
			continue
		if i >= 5:
			extra_patrols += 1
		_check_ship(entry["node"], "NPC_%d" % i)
	check(extra_patrols > 0, "test includes additional targetable patrol ships")
	check(sources.size() >= 4, "live fleet uses all four integrated ship atlases")

	# A live graphics refresh must preserve gameplay and the reference fleet.
	var ship_id: int = game.ship.get_instance_id()
	var hp: int = game.hull
	var money: int = game.gold
	game._apply_graphics_mode()
	await process_frame
	check(game.ship.get_instance_id() == ship_id, "graphics refresh preserves player identity")
	check(game.hull == hp and game.gold == money, "graphics refresh preserves HP and currency")
	for i in game.enemies.size():
		var entry: Dictionary = game.enemies[i]
		if str(entry.get("kind", "")) == "ship":
			_check_ship(entry["node"], "refreshed NPC_%d" % i)
	_finish()

func _check_ship(actor: Node3D, label: String) -> void:
	var adapter := actor.get_node_or_null("ShipSprite")
	check(adapter != null, label + ": ship visual exists")
	if adapter == null:
		return
	var sprite := adapter.get("visual") as Sprite3D
	check(sprite != null, label + ": sprite exists")
	if sprite == null:
		return
	var source: String = sprite.texture.resource_path if sprite.texture != null else ""
	check(source.begins_with("res://assets/classic/private_seabattles/ships/"),
		label + ": uses integrated reference art instead of placeholder")
	check(sprite.hframes == 4 and sprite.vframes == 2, label + ": directional source atlas")
	if not source.begins_with("res://assets/classic/private_seabattles/ships/"):
		return
	sources[source] = true
	examined += 1
	var frames: Dictionary = {}
	for step in 32:
		adapter.set_moving(step % 2 == 0)
		adapter.set_heading(float(step) * TAU / 32.0)
		frames[sprite.frame] = true
		check(sprite.frame >= 4 and sprite.frame <= 7,
			label + ": motion and heading retain intact full sails")
	check(frames.size() == 4, label + ": all four directional views work")

func _finish() -> void:
	print(JSON.stringify({
		"status": "PASS" if failures.is_empty() else "FAIL",
		"scope": "all live reference ships, extra patrols, healthy directional frames, live visual refresh",
		"ships_examined": examined, "unique_hulls": sources.size(), "failed": failures
	}))
	quit(0 if failures.is_empty() else 1)

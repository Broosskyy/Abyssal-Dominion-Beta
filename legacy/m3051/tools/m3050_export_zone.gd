extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/classic/classic_sea_map.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var config := {"version": 1, "zone": "nordmeer_10_2", "bounds": [135,100], "islands": [], "npcs": []}
	for island in game.islands:
		config.islands.append({"x": island.position.x, "z": island.position.z, "radius": island.radius})
	for enemy in game.enemies:
		config.npcs.append({"x": enemy.node.position.x, "z": enemy.node.position.z, "name": enemy.name, "kind": enemy.kind, "hp": enemy.hp})
	var f := FileAccess.open("res://data/classic_zone.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(config,"\t"))
	print("ZONE_EXPORTED ",config.npcs.size())
	quit()

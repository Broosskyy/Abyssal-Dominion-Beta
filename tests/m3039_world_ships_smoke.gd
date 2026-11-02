extends SceneTree
## M303.9 in-engine gameplay QA, not screenshot inference.
var failures: Array[String] = []

func check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.set_meta("m3035_graphic_mode", "private_sprite")
	var packed: PackedScene = load("res://scenes/classic/classic_sea_map.tscn") as PackedScene
	check(packed != null, "actual Godot main scene imports")
	if packed == null:
		_finish()
		return
	var scene: Node3D = packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	check(scene.islands.size() == 6, "two additional navigable coastal islands")
	check(scene._shore_halos.size() == 2, "coastal shallows are in actual world")
	check(scene.enemies.size() == 12, "three additional shootable ship classes")
	check(scene.get_node_or_null("Island_6") != null, "rock island uses supported source asset slot")
	check(scene.get_node_or_null("Island_7") != null, "tropical island uses supported source asset slot")
	check(scene.zoom == 59.0, "M304.6 camera brings reference ships closer to screen")
	check(scene._wake_visual.mesh == null, "old rectangular wake mesh removed")
	check(scene._wake_visual.get_child_count() == 2, "narrow port and starboard foamy wakes")
	check(not scene._wake_visual.visible, "wake disabled when ship stopped")
	var sea: MeshInstance3D = scene.get_node_or_null("UnifiedOcean") as MeshInstance3D
	check(sea != null and sea.material_override is ShaderMaterial, "source-wave texture ocean remains")
	var names: Array[String] = ["Schmuggler-Karavelle", "Eisenfregatte", "Geisterkorsar"]
	var strengths: Array[int] = [70, 155, 130]
	for n in 3:
		var enemy: Dictionary = scene.enemies[9+n]
		check(str(enemy["name"]) == names[n], "class %d correct name" % n)
		check(int(enemy["hp"]) == strengths[n], "class %d unique combat HP" % n)
		var visual: Node = enemy["node"].get_node_or_null("ShipSprite")
		check(visual != null and visual.get("visual") != null, "class %d uses existing SeaBattles artwork" % n)
	scene.target = 10
	scene._refresh()
	check(scene._target_bar.max_value == 155.0, "armored ship has proper target health maximum")
	var before: int = scene.loot_items.size()
	var victim: Dictionary = scene.enemies[11]
	victim["hp"] = 20
	scene.enemies[11] = victim
	scene._player_impact(11, victim["node"], 24)
	check(int(scene.enemies[11]["hp"]) == 0, "ghost ship sinks with real damage")
	check(scene.loot_items.size() == before + 2, "class-specific bonus gold appears in collectable chest")
	# Real player customization: selecting a ship coating must not reset the game.
	var ship_id: int = scene.ship.get_instance_id()
	var current_hull: int = scene.hull
	var current_kills: int = scene.kills
	var current_ammo: int = scene.cannonballs
	check(scene._coating_button != null, "ship coating control exists in actual UI")
	scene._cycle_player_coating()
	check(scene._coating_index == 1, "player can switch to frigate visual")
	check(scene.ship.get_instance_id() == ship_id, "coating does not replace playable ship")
	check(scene.hull == current_hull and scene.kills == current_kills and scene.cannonballs == current_ammo,
		"coating preserves gameplay state")
	var adapter: Node = scene.ship.get_node_or_null("ShipSprite")
	check(adapter != null and adapter.get("visual") != null, "coating has valid imported ship texture")
	check(scene._coating_button.text.contains("Eisenfregatte"), "selected coating visible in menu")
	scene._switch_graphics()
	check(scene._coating_index == 1, "coating selection survives source pack swap")
	check(scene.ship.get_instance_id() == ship_id, "source pack swap also preserves ship node")
	check(scene.enemies.size() == 12, "ships survive swap to SeaOfBones")
	for n in 3:
		var visual: Node = scene.enemies[9+n]["node"].get_node_or_null("ShipSprite")
		check(visual != null and visual.get("visual") != null, "new class %d survives source-pack swap" % n)
	_finish()

func _finish() -> void:
	print(JSON.stringify({"status": "PASS" if failures.is_empty() else "FAIL",
		"version": "M303.9",
		"scope": "shoreline assets and water, narrower wake, closer camera, ship-class HP and loot, pack swap",
		"failed": failures}))
	quit(0 if failures.is_empty() else 1)

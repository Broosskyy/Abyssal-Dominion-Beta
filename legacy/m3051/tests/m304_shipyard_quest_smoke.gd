extends SceneTree
## In-game M304 integration: a real shipyard, purchases and combat effects.
var failures: Array[String] = []

func check(ok: bool, reason: String) -> void:
	if not ok:
		failures.append(reason)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.set_meta("m3035_graphic_mode", "private_sprite")
	var packed := load("res://scenes/classic/classic_sea_map.tscn") as PackedScene
	check(packed != null, "M304 main scene loads")
	if packed == null:
		_finish()
		return
	var scene: Node3D = packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	check(scene._yard_panel != null and scene._yard_buttons.size() == 3, "three interactive ship class cards")
	check(scene._coating_button.text.contains("WERFT"), "shipyard is accessible via menu")
	check(scene._quest_claim != null and scene._quest_claim.disabled, "quest reward is initially locked")
	check(scene._ship_class_index == 0, "starter vessel equipped")
	var vessel_id: int = scene.ship.get_instance_id()
	var original_position: Vector3 = scene.ship.position
	scene._toggle_shipyard()
	check(scene._yard_panel.visible, "shipyard opens")
	scene._purchase_or_equip(1)
	check(scene._ship_class_index == 0 and scene.gold == 0, "cannot buy armored ship without money")
	scene.gold = 45
	scene._purchase_or_equip(1)
	check(scene.gold == 0 and scene._ship_class_index == 1, "frigate costs exactly 45 gold")
	check(scene._unlocked_hulls[1], "frigate stays unlocked")
	check(scene.ship.get_instance_id() == vessel_id, "purchase retains existing ship identity")
	check(scene.ship.position == original_position, "purchase does not teleport player")
	check(scene._captain_title.text.contains("EISENFREGATTE"), "real HUD shows equipped hull")
	var start_hull: int = scene.hull
	scene._enemy_impact(5)
	check(scene.hull == start_hull - 3, "frigate armor reduces 5 incoming damage to 3")
	var raider: Dictionary = scene.enemies[0]
	var before_hp: int = int(raider["hp"])
	scene._player_impact(0, raider["node"], 24)
	check(int(scene.enemies[0]["hp"]) == before_hp - 27, "frigate cannon bonus is applied on hit")
	scene._purchase_or_equip(0)
	check(scene._ship_class_index == 0 and scene.gold == 0, "return to starter hull is free")
	scene._purchase_or_equip(1)
	check(scene._ship_class_index == 1 and scene.gold == 0, "unlocked hull can be re-equipped for free")
	scene._purchase_or_equip(2)
	check(scene._ship_class_index == 1, "ghost ship remains locked without gold")
	scene.kills = 3
	scene._refresh()
	check(not scene._quest_claim.disabled, "quest reward unlocks after three victories")
	scene._claim_quest()
	check(scene.gold == 90 and scene._quest_claimed, "quest pays 90 gold once")
	scene._claim_quest()
	check(scene.gold == 90, "quest cannot be claimed repeatedly")
	scene._purchase_or_equip(2)
	check(scene._ship_class_index == 2 and scene.gold == 0, "ghost ship bought with earned quest gold")
	check(scene.ship.get_instance_id() == vessel_id, "ship identity unchanged after multiple upgrades")
	# Confirm the two private packs still furnish real sprites for the hulls.
	scene._switch_graphics()
	check(scene._ship_class_index == 2 and scene._coating_index == 2, "equipped class survives art pack switch")
	var adapter: Node = scene.ship.get_node_or_null("ShipSprite")
	check(adapter != null and adapter.get("visual") != null, "SeaOfBones ship sprite survives equipped class")
	check(scene._coating_button.text.contains("WERFT"), "shipyard menu remains reachable after pack change")
	scene._toggle_shipyard()
	check(not scene._yard_panel.visible, "shipyard closes")
	_finish()

func _finish() -> void:
	print(JSON.stringify({
		"status": "PASS" if failures.is_empty() else "FAIL",
		"engine": Engine.get_version_info().string,
		"version": "M304",
		"scope": "three unlockable hulls, wallet security, armor and damage stats, once-only quest, same player ship and SeaOfBones sprites",
		"failed": failures
	}))
	quit(0 if failures.is_empty() else 1)

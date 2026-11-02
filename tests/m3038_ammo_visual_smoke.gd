extends SceneTree
## M303.8 live-scene test; rejects HUD-only mockups and fake ammo shapes.
var errors: Array[String] = []

func verify(ok: bool, message: String) -> void:
	if not ok:
		errors.append(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.set_meta("m3035_graphic_mode", "private_sprite")
	var packed := load("res://scenes/classic/classic_sea_map.tscn") as PackedScene
	verify(packed != null, "real main scene loads")
	if packed == null:
		_done()
		return
	var scene: Node3D = packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	verify(scene._ammo_cannon != null and scene._ammo_harpoon != null, "two actual ammo HUD controls")
	verify(scene._ammo_cannon.icon != null and scene._ammo_harpoon.icon != null, "original imported SVG textures")
	verify(scene._target_ring != null, "3D target indicator is built")
	verify(scene._ammo_cannon.text == str(scene.cannonballs), "cannon ammo displayed")
	verify(scene._ammo_harpoon.text == str(scene.harpoons), "harpoon ammo displayed")
	scene._choose_harpoon()
	verify(scene.weapon_mode == "harpoon", "harpoon quickslot changes live weapon state")
	verify(scene._ammo_state.begins_with("harpoon:"), "harpoon quickslot is selected")
	scene._choose_cannon()
	verify(scene.weapon_mode == "cannon", "cannon quickslot changes live weapon state")
	# Real rendered projectile is a mesh group with a dark metallic cannonball.
	scene.ship.position = scene.enemies[0].node.position + Vector3(8.0, 0.0, 0.0)
	scene.target = 0
	var cannon_count: int = scene.cannonballs
	var enemy_hp: int = scene.enemies[0].hp
	scene._fire()
	verify(scene.cannonballs == cannon_count - 1, "cannon ammo consumed on fire")
	var cannon: Node3D = scene._projectile_layer.get_node_or_null("IronCannonball")
	verify(cannon != null, "real cannonball projectile in game world")
	if cannon != null:
		var ball: MeshInstance3D = cannon.get_child(0) as MeshInstance3D
		verify(ball.mesh is SphereMesh, "cannonball is spherical physical 3D ammunition")
		var material: StandardMaterial3D = ball.material_override as StandardMaterial3D
		verify(material != null and material.metallic > 0.5, "cannonball has iron material")
	verify(int(scene.enemies[0].hp) == enemy_hp, "no invisible instant damage")
	await create_timer(1.2).timeout
	verify(int(scene.enemies[0].hp) == enemy_hp - 24, "cannonball hits after visible flight")
	# Monster target: unique long harpoon geometry (not a renamed sphere).
	var monster_index := -1
	for i in scene.enemies.size():
		if str(scene.enemies[i]["kind"]) == "monster":
			monster_index = i
			break
	verify(monster_index >= 0, "monster exists for harpoon test")
	if monster_index < 0:
		_done()
		return
	scene.target = monster_index
	scene._choose_harpoon()
	scene.ship.position = scene.enemies[scene.target].node.position + Vector3(8.0, 0.0, 0.0)
	var harpoon_count: int = scene.harpoons
	var monster_hp: int = scene.enemies[scene.target].hp
	scene._fire()
	verify(scene.harpoons == harpoon_count - 1, "harpoon ammo consumed")
	var harpoon: Node3D = scene._projectile_layer.get_node_or_null("Harpoon")
	verify(harpoon != null, "harpoon projectile in game world")
	if harpoon != null:
		verify(harpoon.get_child_count() >= 4, "harpoon has shaft, tip and barbs")
		var shaft: MeshInstance3D = harpoon.get_child(0) as MeshInstance3D
		verify(shaft.mesh is CylinderMesh, "harpoon shaft is elongated cylinder, not sphere")
	await create_timer(1.2).timeout
	verify(int(scene.enemies[scene.target].hp) == monster_hp - 20, "harpoon damages monster after flight")
	scene._switch_graphics()
	verify(scene._ammo_cannon != null and scene._ammo_harpoon != null, "ammo UI retained after art switch")
	verify(scene._target_ring != null, "target marker retained after art switch")
	_done()

func _done() -> void:
	var report := {
		"status": "PASS" if errors.is_empty() else "FAIL",
		"version": "M303.8",
		"engine": Engine.get_version_info().string,
		"failed": errors,
		"scope": "Godot in-game ammo UI, physical cannonball, harpoon mesh, delayed damage, real graphics pack swap"
	}
	print(JSON.stringify(report))
	quit(0 if errors.is_empty() else 1)

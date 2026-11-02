extends SceneTree
## M303.7 graphics integration smoke, against actual private PNG packs.
## Export must never silently substitute placeholders for missing private test assets.
const BRIDGE = preload("res://scripts/classic/m3035_render_adapter.gd")
var failures: Array[String] = []
var checks: int = 0

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures.append(detail)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for pack_name: String in ["seabattles", "seaofbones"]:
		BRIDGE.active_pack = pack_name
		var config: Dictionary = BRIDGE.pack_config()
		check(not config.is_empty(), "%s pack.json loaded" % pack_name)
		var actors: Dictionary = config.get("actors", {})
		check(actors.has("PlayerShip"), "%s player config" % pack_name)
		for actor_name: String in ["PlayerShip", "NPC_0", "NPC_1", "NPC_2", "SeaMonster", "Island_0"]:
			var file_path: String = BRIDGE.local_path(actor_name)
			check(not file_path.is_empty() and file_path.begins_with("res://assets/classic/private_"),
					"%s / %s path" % [pack_name, actor_name])
			if not file_path.is_empty():
				var texture: Texture2D = BRIDGE._read_texture(file_path)
				check(texture != null, "%s / %s texture decoded" % [pack_name, actor_name])
				if texture != null:
					check(texture.get_width() > 32 and texture.get_height() > 32,
						"%s / %s valid resolution" % [pack_name, actor_name])
	root.set_meta("m3035_graphic_mode", "private_sprite")
	BRIDGE.active_pack = "seabattles"
	var packed: PackedScene = load("res://scenes/classic/classic_sea_map.tscn") as PackedScene
	check(packed != null, "M303.7 main scene can be loaded")
	if packed == null:
		_finish()
		return
	var scene: Node3D = packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	check(str(scene._asset_mode) == "private_sprite", "SeaBattles is first graphics mode")
	_check_visual(scene, "seabattles")
	scene._switch_graphics()
	check(str(scene._asset_mode) == "seaofbones_sprite", "Switched to Sea of Bones")
	_check_visual(scene, "seaofbones")
	scene._switch_graphics()
	check(str(scene._asset_mode) == "private_sprite", "Switched back to SeaBattles")
	_check_visual(scene, "seabattles")
	_finish()

func _check_visual(scene: Node3D, pack_name: String) -> void:
	var actor: Node3D = scene.ship
	check(actor != null, "%s player actor" % pack_name)
	if actor == null:
		return
	var adapter: Node = actor.get_node_or_null("ShipSprite")
	check(adapter != null, "%s ship graphics adapter" % pack_name)
	if adapter == null:
		return
	var sprite: Sprite3D = adapter.get("visual") as Sprite3D
	check(sprite != null and sprite.texture != null, "%s rendered ship sprite" % pack_name)
	if sprite != null and sprite.texture != null:
		check(sprite.texture.get_width() > 200, "%s ship artwork not tiny placeholder" % pack_name)
		var actual_path: String = str(sprite.texture.resource_path)
		check(actual_path.contains("private_" + pack_name), "%s displayed source art from proper pack (%s)" % [pack_name, actual_path])

func _finish() -> void:
	var result: Dictionary = {
		"status": "PASS" if failures.is_empty() else "FAIL",
		"checks": checks,
		"failed": failures,
		"scope": "SeaBattles/SeaOfBones PNG source decode, actor mapping, live graphics swap and runtime sprite provenance",
		"engine": Engine.get_version_info().string
	}
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)

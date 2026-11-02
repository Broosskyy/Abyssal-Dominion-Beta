extends SceneTree
## Real SeaBattles sprite-mode desktop captures; private test sources only.
## These are NOT a physical Android screenshot or an Android performance test.
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.set_meta("m3035_graphic_mode", "private_sprite")
	root.size = Vector2i(1280, 720)
	var resource := load("res://scenes/classic/classic_sea_map.tscn") as PackedScene
	if resource == null:
		push_error("Cannot instantiate M304.6 scene for visual QA")
		quit(1)
		return
	var game: Node3D = resource.instantiate()
	root.add_child(game)
	current_scene = game
	var screenshots := "res://builds/visual"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(screenshots))
	await _warmup()
	_save_capture(screenshots + "/m3046_reference_ocean_fleet.png")
	game._toggle_ammo_inventory()
	await _warmup()
	_save_capture(screenshots + "/m3046_reference_ammunition_menu.png")
	game._toggle_ammo_inventory()
	game._toggle_shipyard()
	await _warmup()
	_save_capture(screenshots + "/m3046_reference_shipyard.png")
	print(JSON.stringify({
		"version": "M304.6",
		"status": "PASS" if failures.is_empty() else "FAIL",
		"kind": "desktop_GL_compatibility_offscreen_capture_not_android",
		"captures": 3,
		"failed": failures
	}))
	quit(0 if failures.is_empty() else 1)

func _warmup() -> void:
	for i in 18:
		await process_frame
	await RenderingServer.frame_post_draw

func _save_capture(path: String) -> void:
	var image := root.get_texture().get_image()
	if image == null or image.get_width() < 800 or image.get_height() < 360:
		failures.append("empty frame: " + path)
		return
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		failures.append("save error %d: %s" % [error, path])

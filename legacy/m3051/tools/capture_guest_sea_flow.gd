extends SceneTree

const OUTPUT_DIR := "user://qa_capture/flow/"
const ENTRY_SCENE := "res://scenes/entry.tscn"
const GAME_SCENE := "res://scenes/main.tscn"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var entry_packed := load(ENTRY_SCENE) as PackedScene
	if entry_packed == null:
		push_error("Missing entry scene")
		quit(1)
		return
	var entry := entry_packed.instantiate() as EntryFlow
	root.add_child(entry)
	call_deferred("_run_flow", entry)


func _run_flow(entry: EntryFlow) -> void:
	await _wait_frames(75)
	await _capture("01_splash")
	entry._action("continue", "")
	await _wait_frames(45)
	await _capture("02_login")
	entry._action("guest", "")
	await _wait_frames(45)
	await _capture("03_home_guest")
	print("FLOW loading sea scene")
	if entry.menu != null:
		entry.menu.hide()
	var game_packed := load(GAME_SCENE) as PackedScene
	if game_packed == null:
		push_error("Failed to load sea scene")
		quit(2)
		return
	var game := game_packed.instantiate()
	entry.add_child(game)
	for i in 240:
		await process_frame
		var player := entry.get_tree().get_first_node_in_group("player")
		if player != null:
			print("FLOW sea ready frame=", i)
			break
	await _wait_frames(180)
	await _capture("04_sea_initial")
	await _wait_frames(150)
	await _capture("05_sea_settled")
	_write_report(entry)
	quit(0)


func _wait_frames(count: int) -> void:
	for _i in count:
		await process_frame


func _capture(name: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var output_path := OUTPUT_DIR.path_join(name + ".png")
	var err := image.save_png(output_path)
	print("CAPTURE_SAVED ", ProjectSettings.globalize_path(output_path), " err=", err)


func _write_report(entry: EntryFlow) -> void:
	var player := entry.get_tree().get_first_node_in_group("player") as ShipMotor
	var report := {
		"flow": ["splash", "login", "home_guest", "sea_initial", "sea_settled"],
		"player_present": player != null,
		"guest": entry.session.guest if entry.session != null else false,
		"display_name": entry.session.display_name() if entry.session != null else "",
		"ship_position": [player.position.x, player.position.y, player.position.z] if player != null else [],
	}
	var path := OUTPUT_DIR.path_join("flow_report.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		print("FLOW_REPORT ", ProjectSettings.globalize_path(path))

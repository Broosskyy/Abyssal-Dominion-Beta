extends SceneTree

const OUTPUT_DIR := "user://qa_capture/flow/"
const GAME_SCENE := "res://scenes/main.tscn"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	root.set_meta("reconstruction_test_mode", true)
	root.set_meta("environment_id", "LOCAL_DEVELOPMENT")
	root.set_meta("guest_session", true)
	root.set_meta("selected_ship_id", "swift_barco")
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		push_error("Failed to load sea scene")
		quit(1)
		return
	root.add_child(packed.instantiate())
	call_deferred("_capture_run")

func _capture_run() -> void:
	for i in 600:
		await process_frame
		var player := get_first_node_in_group("player")
		var world := get_first_node_in_group("world_map")
		if player != null and world != null:
			print("SEA ready frame=", i)
			break
	for _i in 240:
		await process_frame
	await _capture("04_sea_initial")
	for _i in 180:
		await process_frame
	await _capture("05_sea_settled")
	quit(0)

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var output_path := OUTPUT_DIR.path_join(name + ".png")
	var err := image.save_png(output_path)
	print("CAPTURE_SAVED ", ProjectSettings.globalize_path(output_path), " err=", err, " size=", image.get_size())

extends SceneTree

const OUTPUT_DIR := "user://qa_capture/flow/"
const ENTRY_SCENE := "res://scenes/entry.tscn"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var entry := (load(ENTRY_SCENE) as PackedScene).instantiate() as EntryFlow
	root.add_child(entry)
	call_deferred("_run", entry)

func _run(entry: EntryFlow) -> void:
	await _wait(90)
	await _capture("01_splash")
	entry._action("continue", "")
	await _wait(60)
	await _capture("02_login")
	entry._action("guest", "")
	await _wait(60)
	await _capture("03_home_guest")
	quit(0)

func _wait(count: int) -> void:
	for _i in count:
		await process_frame

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var output_path := OUTPUT_DIR.path_join(name + ".png")
	var err := image.save_png(output_path)
	print("CAPTURE_SAVED ", ProjectSettings.globalize_path(output_path), " err=", err, " size=", image.get_size())

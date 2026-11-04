extends SceneTree

const OUTPUT_DIR := "user://qa_capture/"
const SCENE := "res://scenes/entry.tscn"
const DEFAULT_WAIT_FRAMES := 90

func _initialize() -> void:
	var scene_path := str(OS.get_environment("CAPTURE_SCENE") if OS.has_environment("CAPTURE_SCENE") else SCENE)
	var output_name := str(OS.get_environment("CAPTURE_NAME") if OS.has_environment("CAPTURE_NAME") else "capture.png")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Failed to load scene: " + scene_path)
		quit(1)
		return
	var root_node := packed.instantiate()
	root.add_child(root_node)
	call_deferred("_capture_after_wait", output_name)


func _capture_after_wait(output_name: String) -> void:
	var wait_frames := DEFAULT_WAIT_FRAMES
	if OS.has_environment("CAPTURE_WAIT"):
		wait_frames = maxi(1, int(OS.get_environment("CAPTURE_WAIT")))
	for _i in wait_frames:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var output_path := OUTPUT_DIR.path_join(output_name)
	var err := image.save_png(output_path)
	print("CAPTURE_SAVED ", ProjectSettings.globalize_path(output_path), " err=", err)
	quit(err if err != OK else 0)

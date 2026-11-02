extends RefCounted

const DEFAULT_FPS := 30

var _tree: SceneTree
var _output_dir: String
var _fps: int
var _frame_index: int = 0
var _accumulator: float = 0.0
var _recording: bool = false
var _last_size: Vector2i = Vector2i.ZERO


func _init(tree: SceneTree, output_dir: String, fps: int = DEFAULT_FPS) -> void:
	_tree = tree
	_output_dir = output_dir
	_fps = maxi(1, fps)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))


func begin() -> void:
	_recording = true
	_frame_index = 0
	_accumulator = 0.0


func end() -> Dictionary:
	_recording = false
	return {
		"frames": _frame_index,
		"fps": _fps,
		"dir": _output_dir,
		"resolution": [_last_size.x, _last_size.y],
	}


func is_recording() -> bool:
	return _recording


func tick(delta: float) -> void:
	if not _recording:
		return
	_accumulator += delta
	var step := 1.0 / float(_fps)
	while _accumulator >= step:
		_accumulator -= step
		_capture_frame()


func capture_now() -> void:
	if not _recording:
		return
	_capture_frame()


func _capture_frame() -> void:
	var viewport := _tree.root.get_viewport()
	if viewport == null:
		return
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		return
	_last_size = image.get_size()
	_frame_index += 1
	var path := _output_dir.path_join("frame_%06d.png" % _frame_index)
	var err := image.save_png(path)
	if err != OK:
		push_error("QA frame save failed: %s err=%s" % [path, str(err)])

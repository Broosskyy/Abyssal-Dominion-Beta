extends SceneTree
## Independent native Godot ETC2 decompression check; no APK code is executed.
func _initialize() -> void:
	var root_path := OS.get_environment("ETC2_AUDIT_DIR")
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string(root_path.path_join("manifest.json")))
	var failures: Array = []
	for item: Dictionary in entries:
		var bytes := FileAccess.get_file_as_bytes(root_path.path_join(str(item.payload)))
		var image := Image.create_from_data(int(item.width), int(item.height), false, Image.FORMAT_ETC2_RGBA8, bytes)
		var result := image.decompress()
		if result != OK:
			failures.append({"id": item.id, "error": result})
			continue
		image.convert(Image.FORMAT_RGBA8)
		# Unity stores its first scanline at the lower edge; PNG is top-down.
		image.flip_y()
		FileAccess.open(root_path.path_join(str(item.native_rgba)), FileAccess.WRITE).store_buffer(image.get_data())
	print("Native ETC2 decoded: ", entries.size() - failures.size(), " / ", entries.size())
	FileAccess.open(root_path.path_join("native_failures.json"), FileAccess.WRITE).store_string(JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

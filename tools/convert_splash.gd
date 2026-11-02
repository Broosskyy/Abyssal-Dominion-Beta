extends SceneTree


func _initialize() -> void:
	var image := Image.new()
	var result := image.load_svg_from_string(FileAccess.get_file_as_string("res://assets/production/ui/splash.svg"))
	if result == OK:
		result = image.save_png("res://assets/production/ui/splash.png")
	quit(0 if result == OK else 1)

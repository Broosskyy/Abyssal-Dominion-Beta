extends SceneTree
## Rasterizes the SVG asset sheet on CPU, not a screenshot of the game.
func _initialize() -> void:
	var image := Image.new()
	var result := image.load_svg_from_string(FileAccess.get_file_as_string("res://docs/m33_ui_contact.svg"))
	if result == OK: result = image.save_png("res://docs/m33_ui_contact.png")
	print("UI asset sheet result: ", result)
	quit(0 if result == OK else 1)

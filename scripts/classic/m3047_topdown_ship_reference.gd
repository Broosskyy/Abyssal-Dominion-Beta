extends Node3D
## M304.7 source-image top-down ship renderer.
## Always shows ONE independently verified INTACT still, never reads a wreck row.
## Parent actor owns movement, targeting, hull HP and collision as before.
var visual: Sprite3D
var _ship_name := ""
var _world_length := 13.5

static func _load_art(path: String) -> Texture2D:
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var texture := load(path) as Texture2D
		if texture != null:
			return texture
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)
	return null


func configure(image_path: String, ship_name: String, world_length: float) -> bool:
	var texture := _load_art(image_path)
	if texture == null or texture.get_width() < 60:
		return false
	_ship_name = ship_name
	_world_length = world_length
	var plane := Node3D.new()
	plane.name = "TopdownRotation"
	# The input top-view art has its bow pointing LEFT. Turn it toward
	# local -Z so yaw rotates the complete painted vessel in world space.
	plane.rotation.y = -PI * 0.5
	add_child(plane)
	visual = Sprite3D.new()
	visual.name = "IntactReferenceShip"
	visual.texture = texture
	visual.hframes = 1
	visual.vframes = 1
	visual.frame = 0
	visual.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	visual.rotation.x = -PI * 0.5
	visual.shaded = false
	visual.double_sided = true
	visual.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	visual.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	visual.pixel_size = _world_length / float(texture.get_width())
	visual.position.y = 1.7
	plane.add_child(visual)
	return true


func set_heading(_yaw: float) -> void:
	# The parent ship already rotates. No alternate frame selection required.
	if visual != null:
		visual.frame = 0


func set_moving(_moving: bool) -> void:
	# Sailing is NOT a damage state. An intact ship remains intact at rest.
	if visual != null:
		visual.frame = 0


func set_hull_ratio(_hp: float) -> void:
	# HP is handled by independent game effects, never a wreck picture.
	if visual != null:
		visual.frame = 0

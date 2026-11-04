extends Node3D
## M303 interchangeable Sprite3D view of a 16-direction ship atlas.
## This is presentation only. Travel and combat remain owned by world nodes.
const FRAME_COUNT := 16
var sprite: Sprite3D
var heading_offset_degrees := 0.0

func configure(atlas_path: String, pixel_size: float = 0.029) -> bool:
	if not ResourceLoader.exists(atlas_path):
		push_warning("M303 sprite not available: " + atlas_path)
		return false
	var atlas := load(atlas_path) as Texture2D
	if atlas == null:
		push_warning("M303 atlas not importable: " + atlas_path)
		return false
	sprite = Sprite3D.new()
	sprite.name = "Ship16Dir"
	sprite.texture = atlas
	sprite.hframes = FRAME_COUNT
	sprite.vframes = 1
	sprite.frame = 0
	sprite.pixel_size = pixel_size
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.position = Vector3(0.0, 2.1, 0.0)
	add_child(sprite)
	return true

func set_heading(world_yaw: float) -> void:
	if sprite == null:
		return
	var heading := wrapf(rad_to_deg(world_yaw) + heading_offset_degrees, 0.0, 360.0)
	sprite.frame = posmod(roundi(heading / 360.0 * FRAME_COUNT), FRAME_COUNT)

func set_visual_scale(factor: float) -> void:
	if sprite != null:
		sprite.pixel_size = 0.029 * clampf(factor, 0.2, 3.0)

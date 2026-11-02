extends Node3D
## M303.5 private artwork bridge: original game mechanics don't depend on art.
## Source images MUST already be decoded as ordinary PNG or WebP.
## This code neither decrypts Unity bundles nor downloads any third-party data.
const PRIVATE_RES = "res://assets/classic/private_seabattles/"
const PRIVATE_USER = "user://seabattles/"
static var active_pack := "seabattles"
const COMPATIBLE_2D = {
	"PlayerShip": "ships/elite8.png",
	"NPC_0": "ships/warship.png",
	"NPC_1": "ships/pinnace.png",
	"NPC_2": "ships/flyingdutchman.png",
	"NPC_3": "ships/elite8.png",
	"NPC_4": "ships/warship.png"
}
const ISLANDS = {
	"Island_0": "islands/snow.png",
	"Island_1": "islands/snow.png",
	"Island_2": "islands/rock.png",
	"Island_3": "islands/tropical.png"
}
var visual: Sprite3D
var frame_count := 8
var heading_bias := 0.0
var _idle_frames: Array[int] = []
var _moving_frames: Array[int] = []
var _moving := false
var _heading_index := 0
var _animation_rows := 1
var _animation_fps := 0.0
var _animation_time := 0.0
var _animation_row := 0
var _motion_frames_verified := false
var _last_drawn_frame := -1
# VISUALLY AUDITED M304.7: SeaBattles ship atlases use row 0 for furled
# sails and row 1 for FULL sails (healthy). Row 0 resembled a wreck.
var _verified_full_sail_row := -1

static func _is_available(path: String) -> bool:
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)

static func _path_for(relative: String) -> String:
	if relative.is_empty():
		return ""
	# Never silently use the earlier atlas with known color decoding errors.
	var resource_root := PRIVATE_RES if active_pack == "seabattles" else ("res://assets/classic/private_captainofsea/" if active_pack == "captainofsea" else "res://assets/classic/private_seaofbones/")
	var user_root := PRIVATE_USER if active_pack == "seabattles" else ("user://captainofsea/" if active_pack == "captainofsea" else "user://seaofbones/")
	var options: Array[String] = [resource_root + relative, user_root + relative]
	for path in options:
		if _is_available(path):
			return path
	return ""

static func pack_config() -> Dictionary:
	var path := _path_for("pack.json")
	if path.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

static func actor_config(actor_name: String) -> Dictionary:
	var actors: Dictionary = pack_config().get("actors", {})
	var slot := actor_name
	# Extra patrols keep their gameplay identity, but reuse an audited source
	# hull when the SeaBattles pack has no dedicated binding for their ID.
	# Explicit pack overrides always win; other packs retain their own mapping.
	if not actors.has(slot) and active_pack == "seabattles" and actor_name.begins_with("NPC_"):
		var suffix := actor_name.trim_prefix("NPC_")
		if suffix.is_valid_int() and suffix.to_int() >= 0:
			slot = "NPC_%d" % posmod(suffix.to_int(), 5)
	var entry: Variant = actors.get(slot, {})
	return entry if entry is Dictionary else {}

static func has_local_actor(actor_name: String) -> bool:
	return not local_path(actor_name).is_empty()

static func has_local_ship(actor_name: String) -> bool:
	return not _path_for(str(COMPATIBLE_2D.get(actor_name, ""))).is_empty()

static func has_local_island(actor_name: String) -> bool:
	return not _path_for(str(ISLANDS.get(actor_name, ""))).is_empty()

static func local_path(actor_name: String) -> String:
	var entry := actor_config(actor_name)
	if not entry.is_empty():
		return _path_for(str(entry.get("path", "")))
	if COMPATIBLE_2D.has(actor_name):
		return _path_for(str(COMPATIBLE_2D[actor_name]))
	if ISLANDS.has(actor_name):
		return _path_for(str(ISLANDS[actor_name]))
	return ""

static func _read_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var resource := load(path) as Texture2D
		if resource != null:
			return resource
	if FileAccess.file_exists(path):
		var bitmap := Image.new()
		if bitmap.load(path) == OK:
			return ImageTexture.create_from_image(bitmap)
	return null

func set_ship_atlas(path: String, columns: int, rows: int, world_width: float, heading_offset: float = 0.0) -> bool:
	if columns < 1 or rows < 1:
		return false
	var texture := _read_texture(path)
	if texture == null or texture.get_width() < columns or texture.get_height() < rows:
		return false
	# Atlas rows are NOT automatically additional orientations: only columns encode yaw.
	frame_count = columns
	heading_bias = heading_offset
	visual = Sprite3D.new()
	visual.name = "MultiDirectionShip"
	visual.texture = texture
	visual.hframes = columns
	visual.vframes = rows
	visual.frame = 0
	# Crucial: the pictured SeaBattles row 0 has almost no visible sail area.
	# The deployed row is row 1. This is a SAIL state, NOT hull damage!
	_verified_full_sail_row = 1 if (active_pack == "seabattles" and
		rows >= 2 and (path.contains("/ships/") or path.contains("\\ships\\"))) else -1
	# Normalize visual width across different atlas resolutions.
	visual.pixel_size = maxf(world_width, 0.1) / float(texture.get_width() / columns)
	visual.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	visual.shaded = false
	visual.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	visual.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	visual.position = Vector3(0.0, 1.7, 0.0)
	add_child(visual)
	return true

func set_island_image(path: String, diameter: float) -> bool:
	var texture := _read_texture(path)
	if texture == null:
		return false
	visual = Sprite3D.new()
	visual.name = "IslandImage"
	visual.texture = texture
	# This is a camera-baked 2D silhouette on a 3D sea plane. Its lower half
	# must not disappear behind that plane merely because the quad crosses it.
	visual.no_depth_test = true
	visual.pixel_size = diameter / maxf(1.0, float(maxi(texture.get_width(), texture.get_height())))
	visual.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	visual.shaded = false
	visual.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	visual.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	visual.position.y = 1.4
	add_child(visual)
	return true

func set_heading(world_yaw: float) -> void:
	if visual == null or frame_count < 2:
		return
	var degrees := wrapf(rad_to_deg(world_yaw) + heading_bias, 0.0, 360.0)
	var next_frame := posmod(roundi(degrees / 360.0 * float(frame_count)), frame_count)
	# Preserve the current cardinal art until heading clears a small deadband.
	# Prevents rapid back/forth frame switching close to a 45-degree boundary.
	var old_center := float(_heading_index) * 360.0 / float(frame_count)
	var angular_distance := absf(wrapf(degrees - old_center, -180.0, 180.0))
	if angular_distance > 180.0 / float(frame_count) + 6.0:
		_heading_index = next_frame
	_apply_frame()

func configure_frames(entry: Dictionary) -> void:
	# Protect healthy ships from damaged/wreck atlas rows. The original imported
	# row mapping is not a validated damage or sailing-state mapping.
	_idle_frames.clear()
	_moving_frames.clear()
	var columns := visual.hframes if visual != null else 4
	# Dedicated health-safe visual selection. At 100% HP we ALWAYS pick
	# the full-sail row, even when stopped. Sail state is never HP state.
	if _verified_full_sail_row >= 0 and visual != null:
		for column in columns:
			_idle_frames.append(_verified_full_sail_row * columns + column)
		frame_count = _idle_frames.size()
		_motion_frames_verified = false
		_animation_rows = 1
		_animation_fps = 0.0
		_last_drawn_frame = -1
		_apply_frame()
		return
	for frame in entry.get("idle_frames", []):
		if int(frame) >= 0 and int(frame) < columns:
			_idle_frames.append(int(frame))
	if _idle_frames.is_empty():
		for frame in columns:
			_idle_frames.append(frame)
	frame_count = _idle_frames.size()
	_motion_frames_verified = bool(entry.get("verified_sailing_row", false))
	if _motion_frames_verified:
		for frame in entry.get("moving_frames", []):
			if int(frame) >= 0 and int(frame) < visual.hframes * visual.vframes:
				_moving_frames.append(int(frame))
		if _moving_frames.size() != frame_count:
			_motion_frames_verified = false
			_moving_frames.clear()
	_animation_rows = maxi(1, int(entry.get("animation_rows", 1)))
	_animation_fps = maxf(0.0, float(entry.get("animation_fps", 0.0)))
	_last_drawn_frame = -1
	_apply_frame()

func set_moving(value: bool) -> void:
	if _moving == value:
		return
	_moving = value
	if _motion_frames_verified:
		_apply_frame()

func _apply_frame() -> void:
	if visual == null:
		return
	var frames := _moving_frames if _motion_frames_verified and _moving and not _moving_frames.is_empty() else _idle_frames
	var frame := _heading_index if frames.is_empty() else frames[posmod(_heading_index, frames.size())]
	if _animation_rows > 1:
		frame += _animation_row * visual.hframes
	frame = clampi(frame, 0, visual.hframes * visual.vframes - 1)
	if frame != _last_drawn_frame:
		visual.frame = frame
		_last_drawn_frame = frame

func _process(delta: float) -> void:
	if _animation_rows < 2 or _animation_fps <= 0.0:
		return
	_animation_time += delta
	var row := int(_animation_time * _animation_fps) % _animation_rows
	if row != _animation_row:
		_animation_row = row
		_apply_frame()

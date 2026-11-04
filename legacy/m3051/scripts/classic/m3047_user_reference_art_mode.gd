extends "res://scripts/classic/m3046_direct_course_reference_default.gd"
## M304.7: Visual source priority remains SeaBattles/SeaOfBones; optionally
## overlay the user's privately staged high-detail TOP-VIEW images.
## The original refs are not committed to this public repository.
const TOP_VIEW = preload("res://scripts/classic/m3047_topdown_ship_reference.gd")
const USER_ART_RES := "res://assets/classic/private_user_art/"
const USER_ART_DATA := "user://abyssal_user_art/"

var _private_reference_manifest: Dictionary = {}
var _private_art_root := ""


func _ready() -> void:
	_find_private_art_pack()
	super._ready()
	_hud_header.text = "ABYSSAL DOMINION · M304.7"
	_build_label.text = "M304.7 · INTACKTE SEGEL · SCHIFFSGRAFIKEN"
	_refresh()


func _find_private_art_pack() -> void:
	for root_path in [USER_ART_RES, USER_ART_DATA]:
		var manifest_path: String = str(root_path) + "pack.json"
		if not FileAccess.file_exists(manifest_path):
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		if data is Dictionary and data.has("actors"):
			_private_reference_manifest = data
			_private_art_root = root_path
			return


func _custom_actor(label: String) -> Dictionary:
	if _private_reference_manifest.is_empty():
		return {}
	var actors: Dictionary = _private_reference_manifest.get("actors", {})
	var result: Variant = actors.get(label, {})
	return result if result is Dictionary else {}


func _asset(file: String, where: Vector3, factor: float, label: String, atlas: String = "") -> Node3D:
	# Source sheet sprites are the fallback, but the user's own detailed top
	# views win for actors explicitly named in the private manifest.
	if _asset_mode == "private_sprite" and (label == "PlayerShip" or label.begins_with("NPC_")):
		var config := _custom_actor(label)
		if not config.is_empty():
			var source := _private_art_root + str(config.get("path", ""))
			var holder := Node3D.new()
			holder.position = where
			holder.name = label
			add_child(holder)
			var sprite := TOP_VIEW.new()
			sprite.name = "ShipSprite"
			holder.add_child(sprite)
			var world_length := float(config.get("world_length", 13.5)) * factor
			if sprite.configure(source, str(config.get("name", label)), world_length):
				return holder
			holder.remove_child(sprite)
			sprite.queue_free()
			holder.queue_free()
	return super._asset(file, where, factor, label, atlas)


func _refresh() -> void:
	super._refresh()
	if ship == null:
		return
	var art := ship.get_node_or_null("ShipSprite")
	if art != null and art.has_method("set_hull_ratio"):
		art.set_hull_ratio(clampf(float(hull) / 100.0, 0.0, 1.0))


func _private_ui_texture(name: String) -> Texture2D:
	if _private_art_root.is_empty():
		return null
	return TOP_VIEW._load_art(_private_art_root + "ui/" + name + ".png")


func _style_decorative_panels() -> void:
	super._style_decorative_panels()
	# Proper sliced UI textures from the user's references, not stretching a
	# pre-rendered card over its full width and distorting corner ornaments.
	var image := _private_ui_texture("standard_panel")
	if image == null:
		return
	for panel: Panel in [_hud_player_frame, _hud_target_frame, _yard_panel, _options, _ammo_panel]:
		if panel == null:
			continue
		var style := StyleBoxTexture.new()
		style.texture = image
		style.set_texture_margin_all(35.0)
		style.set_content_margin_all(10.0)
		panel.add_theme_stylebox_override("panel", style)

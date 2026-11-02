extends "res://scripts/classic/m3047_user_reference_art_mode.gd"
## User-supplied ship + ammunition art. Cosmetic FX NEVER imply hull damage.
## Private PNG pack is optional; SeaBattles source remains fallback.
var _cosmetic_ship_effects := false
var _art_variants_button: Button
var _pack_status: Label

func _ready() -> void:
	super._ready()
	_hud_header.text = "ABYSSAL DOMINION · M304.8"
	_build_label.text = "M304.8 · REFERENZ-SCHIFFE & MUNITION"
	_refresh()

func _custom_actor(label: String) -> Dictionary:
	var definition: Dictionary = super._custom_actor(label)
	if definition.is_empty() or not _cosmetic_ship_effects:
		return definition
	var path: String = str(definition.get("path", ""))
	if not path.begins_with("ships/") or not path.ends_with(".png"):
		return definition
	var skin: String = "ship_effect_variants/" + path.trim_prefix("ships/").trim_suffix(".png") + "_cosmetic.png"
	if not _private_art_root.is_empty() and FileAccess.file_exists(_private_art_root + skin):
		var copy: Dictionary = definition.duplicate()
		copy["path"] = skin
		return copy
	return definition

func _asset(file: String, where: Vector3, factor: float, label: String, atlas: String = "") -> Node3D:
	var holder: Node3D = super._asset(file, where, factor, label, atlas)
	if not (label == "PlayerShip" or label.begins_with("NPC_")):
		return holder
	var custom_sprite := holder.get_node_or_null("ShipSprite")
	if custom_sprite == null or not custom_sprite.has_method("set_hull_ratio"):
		return holder
	# Artwork is 3/4-oblique rather than an orthographic top view.
	var view := custom_sprite.get_node_or_null("TopdownRotation") as Node3D
	var art: Sprite3D = custom_sprite.get("visual") as Sprite3D
	if art != null:
		art.rotation.x = -deg_to_rad(57.0)
		art.position.y = 2.35
		art.frame = 0
	if view != null:
		view.rotation.y = deg_to_rad(-45.0)
	return holder

func _make_hud() -> void:
	super._make_hud()
	_art_variants_button = _control("SCHIFFSEFFEKTE: AUS", Callable(self, "_toggle_cosmetic_ship_effects"))
	_art_variants_button.name = "UserArtworkCosmeticToggle"
	var parent := _art_variants_button.get_parent()
	if parent != null:
		parent.remove_child(_art_variants_button)
	_options.add_child(_art_variants_button)
	_art_variants_button.tooltip_text = "Kosmetische Varianten – unabhängig von Schaden oder Rumpf-HP"
	_pack_status = _label(_options, "GRAFIKEN: Standard", 10)
	_pack_status.name = "UserArtworkImportStatus"
	var names := ["cannonball", "harpoon", "chain"]
	for i in 3:
		var texture: Texture2D = _private_ui_texture(names[i])
		if texture != null and i < _ammo_buttons.size():
			_ammo_buttons[i].icon = texture
			_ammo_buttons[i].expand_icon = true
	# Further ammunition concepts are ART REFERENCES only, not fake controls.

func _toggle_cosmetic_ship_effects() -> void:
	_cosmetic_ship_effects = not _cosmetic_ship_effects
	if not _private_art_root.is_empty() and ship != null and _asset_mode == "private_sprite":
		_replace_visual(ship, SHIP, 0.9, "PlayerShip", CAPTAIN_ATLAS)
		for i in enemies.size():
			var entry: Dictionary = enemies[i]
			if str(entry.get("kind", "")) != "ship":
				continue
			var actor: Node3D = entry["node"]
			if is_instance_valid(actor):
				_replace_visual(actor, ENEMY, 0.8, "NPC_%d" % i, CORSAIR_ATLAS)
	_refresh()

func _layout_hud() -> void:
	super._layout_hud()
	if _art_variants_button == null:
		return
	var panel_width: float = _options.size.x
	_place(_options, _options.position.x, _options.position.y, panel_width, 338.0)
	_place(_art_variants_button, 18.0, 158.0, panel_width - 36.0, 35.0)
	_place(_options_close, 18.0, 210.0, panel_width - 36.0, 37.0)
	_place(_pack_status, 18.0, 257.0, panel_width - 36.0, 18.0)
	_place(_build_label, 18.0, 292.0, panel_width - 36.0, 24.0)

func _refresh() -> void:
	super._refresh()
	if _art_variants_button != null:
		_art_variants_button.text = "SCHIFFSEFFEKTE: AN" if _cosmetic_ship_effects else "SCHIFFSEFFEKTE: AUS"
		_art_variants_button.disabled = _private_art_root.is_empty()
	if _pack_status != null:
		_pack_status.text = "PRIVAT-ARTPAKET AKTIV" if not _private_art_root.is_empty() else "OHNE PRIVAT-ARTPAKET"

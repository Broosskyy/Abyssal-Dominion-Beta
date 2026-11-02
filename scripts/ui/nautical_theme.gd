class_name NauticalTheme
extends RefCounted
const ROOT := "res://assets/placeholder_pack/ui/"

static func density_scale() -> float:
	var dpi := float(DisplayServer.screen_get_dpi())
	return clampf(dpi / 210.0, 1.0, 1.65) if dpi > 180.0 else 1.0

static func create() -> Theme:
	var result := Theme.new()
	var sx := density_scale()
	result.default_font_size = roundi(17 * sx)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = VisualAssetCatalog.texture("button_" + state)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			style.set_texture_margin(side, VisualAssetCatalog.slice_margin("button_" + state))
			style.set_content_margin(side, (18 if side in [SIDE_LEFT, SIDE_RIGHT] else 12) * sx)
		for type in ["Button", "OptionButton"]: result.set_stylebox(state, type, style)
	var focus := graphic_style("button_focus")
	for type in ["Button", "OptionButton", "LineEdit"]: result.set_stylebox("focus", type, focus)
	result.set_constant("separation", "VBoxContainer", roundi(12 * sx))
	return result

static func graphic_style(id: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = VisualAssetCatalog.texture(id)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		style.set_texture_margin(side, VisualAssetCatalog.slice_margin(id))
		style.set_content_margin(side, 12)
	return style

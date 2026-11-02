extends "res://scripts/classic/m3043_original_fleet_ocean.gd"
## M304.4: real navigable, responsive naval HUD with original SVG icon assets.
## UI controls are bound to the local M304 economy, ammunition and shipyard.
const BRIG_ICON: Texture2D = preload("res://assets/classic/original_ui/ship-brig.svg")
const FRIGATE_ICON: Texture2D = preload("res://assets/classic/original_ui/ship-frigate.svg")
const GHOST_ICON: Texture2D = preload("res://assets/classic/original_ui/ship-ghost.svg")
const AMMO_CHEST_ICON: Texture2D = preload("res://assets/classic/original_ui/ammo-chest.svg")
const COIN_ICON: Texture2D = preload("res://assets/classic/original_ui/coin.svg")
const SHIPYARD_ICON: Texture2D = preload("res://assets/classic/original_ui/shipyard.svg")
const NAVY := Color("091c2a", 0.97)
const MIDNIGHT := Color("06131e", 0.98)
const GOLD := Color("cdb176")
const GOLD_BRIGHT := Color("f8d994")
const AQUA := Color("80cbbb")

var _ammo_overlay: ColorRect
var _ammo_panel: Panel
var _ammo_title: Label
var _ammo_description: Label
var _ammo_buttons: Array[Button] = []
var _restock_buttons: Array[Button] = []
var _ammo_close: Button
var _ammo_menu_button: Button
var _dock_quick_button: Button
var _speed_info: Label
var _last_hud_update := 0.0


func _ready() -> void:
	super._ready()
	_hud_header.text = "ABYSSAL DOMINION  ·  NORDMEER 10/2"
	_build_label.text = "M304.4 · ORIGINAL NAVAL HUD"
	_refresh()


func _make_hud() -> void:
	super._make_hud()
	_ammo_menu_button = _control("MUNITION · NACHLADEN", Callable(self, "_toggle_ammo_inventory"))
	_ammo_menu_button.name = "OpenAmmoInventory"
	_ammo_menu_button.icon = AMMO_CHEST_ICON
	_ammo_menu_button.expand_icon = true
	_ammo_menu_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_ammo_menu_button.add_theme_font_size_override("font_size", 12)
	_ammo_menu_button.tooltip_text = "Munitionsarten, Munitionsvorräte und Nachschub anzeigen"
	_dock_quick_button = _control("WERFT", Callable(self, "_toggle_shipyard"))
	_dock_quick_button.name = "QuickShipyard"
	_dock_quick_button.icon = SHIPYARD_ICON
	_dock_quick_button.expand_icon = true
	_dock_quick_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_dock_quick_button.tooltip_text = "Schiffe kaufen, ausrüsten und verbessern"
	_speed_info = _label(_ui_root, "KURS BEREIT", 12)
	_speed_info.name = "SeaSpeedReadout"
	_speed_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed_info.add_theme_color_override("font_color", AQUA)

	_ammo_overlay = ColorRect.new()
	_ammo_overlay.name = "AmmoModalBackdrop"
	_ammo_overlay.color = Color(0.008, 0.024, 0.04, 0.74)
	_ammo_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ammo_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_ammo_overlay.z_index = 30
	_ammo_overlay.visible = false
	_ui_root.add_child(_ammo_overlay)
	_ammo_overlay.gui_input.connect(Callable(self, "_on_ammo_backdrop"))
	_ammo_panel = _panel(_ui_root)
	_ammo_panel.name = "M3044AmmoInventory"
	_ammo_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_ammo_panel.z_index = 31
	_ammo_panel.visible = false
	_ammo_panel.add_theme_stylebox_override("panel", _naval_frame(MIDNIGHT, GOLD, 2, 13))
	_ammo_title = _label(_ammo_panel, "MUNITIONSDEPOT  /  NORDMEER", 19)
	_ammo_description = _label(_ammo_panel, "Munition auswählen und mit erbeutetem Gold auffüllen", 12)
	_ammo_description.add_theme_color_override("font_color", Color("a9c7cb"))
	for i in 3:
		var select_action := Callable(self, "_equip_from_ammo_inventory").bind(i)
		var choice := _control("", select_action)
		_move_into_panel(choice, _ammo_panel)
		choice.name = "AmmoSelect_%d" % i
		choice.icon = _ammo_cannon.icon if i == 0 else (_ammo_harpoon.icon if i == 1 else _ammo_chain.icon)
		choice.expand_icon = true
		choice.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice.alignment = HORIZONTAL_ALIGNMENT_CENTER
		choice.add_theme_font_size_override("font_size", 12)
		choice.tooltip_text = ["Eisenkugeln: gegen Schiffe", "Harpunen: gegen Monster", "Kettengeschosse: schwächen feindliche Kanonen"][i]
		_ammo_buttons.append(choice)
		var buy_action := Callable(self, "_buy_ammunition").bind(i)
		var buy := _control("", buy_action)
		_move_into_panel(buy, _ammo_panel)
		buy.name = "AmmoRestock_%d" % i
		buy.icon = COIN_ICON
		buy.expand_icon = true
		buy.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		buy.alignment = HORIZONTAL_ALIGNMENT_CENTER
		buy.add_theme_font_size_override("font_size", 13)
		_restock_buttons.append(buy)
	_ammo_close = _control("ZURÜCK ZUR SEEKARTE", Callable(self, "_toggle_ammo_inventory"))
	_move_into_panel(_ammo_close, _ammo_panel)
	_ammo_close.name = "CloseAmmoInventory"
	for i in _yard_buttons.size():
		var button: Button = _yard_buttons[i]
		button.icon = BRIG_ICON if i == 0 else (FRIGATE_ICON if i == 1 else GHOST_ICON)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 14)
		button.tooltip_text = "Schiff durch Antippen kaufen oder ausrüsten"
	_style_decorative_panels()
	_style_common_actions()


func _move_into_panel(control: Control, panel: Control) -> void:
	var old_parent := control.get_parent()
	if old_parent != null:
		old_parent.remove_child(control)
	panel.add_child(control)


func _naval_frame(base: Color, border_color: Color, thickness: int = 1, corner: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = base
	style.border_color = border_color
	style.set_border_width_all(thickness)
	style.set_corner_radius_all(corner)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	style.shadow_size = 4
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style


func _style_control(button: Button, selected: bool = false, accent: bool = false) -> void:
	var border := GOLD_BRIGHT if selected else (AQUA if accent else Color("6b8190"))
	var base := Color("514222") if selected else (Color("194750") if accent else Color("102a3c"))
	button.add_theme_stylebox_override("normal", _naval_frame(base, border, 2 if selected else 1, 9))
	button.add_theme_stylebox_override("hover", _naval_frame(base.lightened(0.16), GOLD_BRIGHT, 2, 9))
	button.add_theme_stylebox_override("pressed", _naval_frame(Color("6d5430"), GOLD_BRIGHT, 2, 9))
	button.add_theme_stylebox_override("disabled", _naval_frame(Color("101d29"), Color("475461"), 1, 9))
	button.add_theme_color_override("font_color", GOLD_BRIGHT if selected else Color("e4ece7"))
	button.add_theme_color_override("font_disabled_color", Color("8a989d"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)


func _style_decorative_panels() -> void:
	_hud_bar.add_theme_stylebox_override("panel", _naval_frame(Color("071923"), GOLD, 1, 3))
	_hud_player_frame.add_theme_stylebox_override("panel", _naval_frame(NAVY, GOLD, 2, 10))
	_hud_target_frame.add_theme_stylebox_override("panel", _naval_frame(NAVY, Color("c17861"), 2, 10))
	_hud_mini_frame.add_theme_stylebox_override("panel", _naval_frame(NAVY, AQUA, 2, 10))
	_hud_status_frame.add_theme_stylebox_override("panel", _naval_frame(Color("0b2635"), Color("557988"), 1, 9))
	_quest_frame.add_theme_stylebox_override("panel", _naval_frame(NAVY, GOLD, 1, 10))
	_yard_panel.add_theme_stylebox_override("panel", _naval_frame(MIDNIGHT, GOLD_BRIGHT, 2, 12))
	_options.add_theme_stylebox_override("panel", _naval_frame(MIDNIGHT, GOLD, 2, 12))
	_ammo_backplate.add_theme_stylebox_override("panel", _naval_frame(Color("061c2b"), GOLD, 1, 11))
	_hud_header.add_theme_color_override("font_color", GOLD_BRIGHT)
	_quest_title.add_theme_color_override("font_color", GOLD_BRIGHT)
	_captain_title.add_theme_color_override("font_color", GOLD_BRIGHT)
	_yard_heading.add_theme_color_override("font_color", GOLD_BRIGHT)
	_options_title.add_theme_color_override("font_color", GOLD_BRIGHT)
	_ammo_heading.add_theme_color_override("font_color", GOLD_BRIGHT)
	_ammo_heading.add_theme_font_size_override("font_size", 11)


func _style_common_actions() -> void:
	for button in [_ammo_menu_button, _dock_quick_button, _ammo_close, _yard_close, _options_close, _quest_claim]:
		_style_control(button, false, button == _dock_quick_button)
	for key in ["center", "left", "right", "zoom_in", "zoom_out", "repair"]:
		_style_control(_hud_controls[key])
	_style_control(attack_button, false, true)
	for b in _restock_buttons:
		_style_control(b)
	for b in _ammo_buttons:
		_style_control(b)


func _layout_hud() -> void:
	super._layout_hud()
	if _ammo_panel == null or _ammo_menu_button == null:
		return
	var bounds := get_viewport().get_visible_rect().size
	var w := bounds.x
	var h := bounds.y
	var compact := h < 540.0 or w < 1024.0
	var m := 8.0 if compact else 14.0
	var header := 36.0 if compact else 42.0
	var bh := 47.0 if compact else 54.0
	var bottom := h - m - bh
	var ammo_w := 56.0 * 3.0 + 8.0 if compact else 74.0 * 3.0 + 12.0
	var toggle_w := 170.0 if not compact else 148.0
	_place(_ammo_menu_button, (w - toggle_w) * 0.5, bottom - 66.0, toggle_w, 34.0)
	var repair_x: float = (_hud_controls["repair"] as Control).position.x
	var right_cluster_w: float = w - repair_x - m
	_place(_dock_quick_button, repair_x, bottom - 64.0, right_cluster_w, 37.0)
	# Keep the status above the ocean in the free space BETWEEN the side cards.
	var player_right := _hud_player_frame.position.x + _hud_player_frame.size.x + 12.0
	var minimap_left := _hud_mini_frame.position.x - 12.0
	var free_w := maxf(120.0, minimap_left - player_right)
	var status_w := minf(340.0, free_w)
	var status_x := player_right + maxf(0.0, (free_w - status_w) * 0.5)
	var status_y := header + m + 2.0
	_place(_hud_status_frame, status_x, status_y, status_w, 45.0)
	_place(status, status_x + 8.0, status_y + 3.0, status_w - 16.0, 39.0)
	status.add_theme_font_size_override("font_size", 11 if compact else 13)
	_place(_speed_info, status_x, status_y + 49.0, status_w, 22.0)
	# Ensure the modal catches taps over the world but stays below its own buttons.
	_place(_ammo_overlay, 0.0, 0.0, w, h)
	var panel_w := minf(540.0, w - 2.0 * m)
	var panel_h := minf(354.0, h - 2.0 * m)
	_place(_ammo_panel, (w - panel_w) * 0.5, (h - panel_h) * 0.5, panel_w, panel_h)
	_place(_ammo_title, 18.0, 10.0, panel_w - 36.0, 27.0)
	_place(_ammo_description, 18.0, 39.0, panel_w - 36.0, 21.0)
	var gap := 6.0
	var tile_w := (panel_w - 32.0 - 2.0 * gap) / 3.0
	var choice_h := clampf(panel_h * 0.14, 38.0, 52.0)
	for i in 3:
		_place(_ammo_buttons[i], 16.0 + float(i) * (tile_w + gap), 65.0, tile_w, choice_h)
	var restock_y := 65.0 + choice_h + 10.0
	var close_y := panel_h - 45.0
	var restock_h := clampf((close_y - restock_y - 16.0) / 3.0 - 4.0, 25.0, 45.0)
	for i in 3:
		_place(_restock_buttons[i], 16.0, restock_y + float(i) * (restock_h + 5.0), panel_w - 32.0, restock_h)
	_place(_ammo_close, 16.0, close_y, panel_w - 32.0, 36.0)
	# Previous compact modal did not show title/icon status for the ship types.
	_yard_description.text = "GOLD %d   ·   SCHIFFSKLASSE %d / 3" % [gold, _ship_class_index + 1]


func _toggle_ammo_inventory() -> void:
	if _ammo_panel == null:
		return
	var opening := not _ammo_panel.visible
	_ammo_panel.visible = opening
	_ammo_overlay.visible = opening
	if opening:
		_yard_panel.visible = false
		_options.visible = false
	_refresh()


func _on_ammo_backdrop(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			_toggle_ammo_inventory()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_toggle_ammo_inventory()


func _toggle_shipyard() -> void:
	if _ammo_panel != null:
		_ammo_panel.visible = false
		_ammo_overlay.visible = false
	super._toggle_shipyard()


func _toggle_options() -> void:
	if _ammo_panel != null:
		_ammo_panel.visible = false
		_ammo_overlay.visible = false
	super._toggle_options()


func _unhandled_input(event: InputEvent) -> void:
	if _ammo_panel != null and _ammo_panel.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_toggle_ammo_inventory()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)


func _equip_from_ammo_inventory(index: int) -> void:
	if index == 0:
		_choose_cannon()
	elif index == 1:
		_choose_harpoon()
	elif index == 2:
		_select_chain()
	if _ammo_panel != null and ((index == 0 and weapon_mode == "cannon") or
		(index == 1 and weapon_mode == "harpoon") or (index == 2 and weapon_mode == "chain")):
		_ammo_panel.visible = false
		_ammo_overlay.visible = false
	_refresh()


func _buy_ammunition(index: int) -> void:
	var amount := 0
	var price := 0
	if index == 0:
		amount = 50
		price = 15
	elif index == 1:
		amount = 25
		price = 18
	elif index == 2:
		_restock_chain()
		return
	else:
		return
	if gold < price:
		hint = "Nicht genug Gold: Nachschub kostet %d Gold" % price
	else:
		gold -= price
		if index == 0:
			cannonballs += amount
			hint = "+50 Eisenkugeln aufgefüllt"
		else:
			harpoons += amount
			hint = "+25 Harpunen aufgefüllt"
	_refresh()


func _refresh() -> void:
	super._refresh()
	if _ammo_panel == null:
		return
	var icons: Array[Texture2D] = [BRIG_ICON, FRIGATE_ICON, GHOST_ICON]
	for i in _yard_buttons.size():
		var button: Button = _yard_buttons[i]
		button.icon = icons[i]
		_style_control(button, i == _ship_class_index)
		# A locked ship is an actionable purchase, NOT a disabled decoration.
		button.disabled = false
	var counts := [cannonballs, harpoons, chainballs]
	var choices := ["EISENKUGEL", "HARPUNE", "KETTE"]
	var modes := ["cannon", "harpoon", "chain"]
	var prices := [15, 18, CHAIN_AMMO_RESTOCK_COST]
	var quantities := [50, 25, CHAIN_AMMO_RESTOCK_AMOUNT]
	for i in 3:
		var choice: Button = _ammo_buttons[i]
		choice.text = "%s\n%d STK." % [choices[i], int(counts[i])]
		choice.disabled = int(counts[i]) == 0
		_style_control(choice, weapon_mode == modes[i])
		var buy: Button = _restock_buttons[i]
		buy.text = "%s  +%d  /  %d GOLD" % [choices[i], int(quantities[i]), int(prices[i])]
		buy.disabled = gold < int(prices[i])
		_style_control(buy)
	_ammo_description.text = "GOLD %d    ·    AKTUELL: %s" % [gold, str(weapon_mode).to_upper()]
	if _speed_info != null and ship != null:
		_speed_info.text = "KURS %d°  ·  GESCHW. %.1f" % [posmod(roundi(rad_to_deg(ship.rotation.y)), 360), _sea_speed]
	_yard_description.text = "GOLD %d   ·   SCHIFFSKLASSE %d / 3" % [gold, _ship_class_index + 1]
	_style_control(attack_button, firing, true)
	if _hull_bar != null:
		_hull_bar.modulate = Color("ff937c") if hull <= 30 else (Color("f2c470") if hull <= 60 else Color.WHITE)


func _process(delta: float) -> void:
	super._process(delta)
	_last_hud_update += delta
	if _last_hud_update > 0.22 and _speed_info != null and ship != null:
		_last_hud_update = 0.0
		_speed_info.text = "KURS %d°  ·  GESCHW. %.1f" % [posmod(roundi(rad_to_deg(ship.rotation.y)), 360), _sea_speed]

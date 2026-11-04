extends "res://scripts/classic/m3041_chainshot_combat.gd"
## M304.2: stable helm, adaptive non-overlapping HUD, and original UI artwork.
## Gameplay stays LOCAL; no unverified third-party sprites are packaged here.

const HELM_ICON: Texture2D = preload("res://assets/classic/original_ui/helm.svg")
const REPAIR_ICON: Texture2D = preload("res://assets/classic/original_ui/repair.svg")
const FIRE_ICON: Texture2D = preload("res://assets/classic/original_ui/fire.svg")
const TURN_RATE := 106.0
const THROTTLE_ACCEL := 6.8
const THROTTLE_BRAKE := 11.0
const ARRIVAL_RADIUS := 1.0

var _ammo_backplate: Panel
var _ammo_heading: Label

func _ready() -> void:
	super._ready()
	_hud_header.text = "ABYSSAL DOMINION · M304.2"
	_refresh()


func _make_hud() -> void:
	super._make_hud()
	_ammo_backplate = _panel(_ui_root)
	_ammo_backplate.name = "AmmoQuickbarBackplate"
	var plate := _style()
	plate.bg_color = Color("071925ef")
	plate.border_color = Color("b69a61")
	plate.set_border_width_all(2)
	plate.set_corner_radius_all(11)
	_ammo_backplate.add_theme_stylebox_override("panel", plate)
	_ammo_backplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.move_child(_ammo_backplate, 1)
	_ammo_heading = _label(_ui_root, "MUNITION", 11)
	_ammo_heading.name = "AmmoQuickbarLabel"
	_ammo_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ammo_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for ammo: Button in [_ammo_cannon, _ammo_harpoon, _ammo_chain]:
		# Original 72px icons must shrink inside a mobile quickslot instead of
		# expanding the Button minimum width across its neighbor.
		ammo.expand_icon = true
		ammo.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ammo.alignment = HORIZONTAL_ALIGNMENT_CENTER
		ammo.add_theme_font_size_override("font_size", 13)
		ammo.focus_mode = Control.FOCUS_NONE
	# Weapon choice is now handled by the three visible, independently active
	# ammo slots; the old cycling button had caused duplicate overlapping UI.
	harpoon_button.visible = false
	_hud_controls["center"].text = "KURS"
	_hud_controls["repair"].icon = REPAIR_ICON
	_hud_controls["repair"].expand_icon = false
	_hud_controls["repair"].icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	attack_button.icon = FIRE_ICON
	attack_button.expand_icon = false
	attack_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hud_controls["center"].icon = HELM_ICON
	_hud_controls["center"].expand_icon = false
	_hud_controls["center"].icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if _graphics_button != null:
		_graphics_button.visible = false


func _layout_hud() -> void:
	super._layout_hud()
	if _ammo_backplate == null or _ammo_chain == null:
		return
	var viewport := get_viewport().get_visible_rect().size
	var w := viewport.x
	var h := viewport.y
	if w < 300.0 or h < 210.0:
		return
	var compact := h < 540.0 or w < 1024.0
	var tiny := w < 710.0
	var margin := 8.0 if compact else 14.0
	var header := 36.0 if compact else 42.0
	var button_h := 47.0 if compact else 54.0
	var bottom := h - margin - button_h
	var gap := 4.0 if compact else 6.0
	var left_keys: Array[String] = ["center", "left", "right", "zoom_out", "zoom_in"]
	var widths: Array[float] = [70.0, 37.0, 37.0, 36.0, 36.0]
	if not compact:
		widths.assign([102.0, 46.0, 46.0, 43.0, 43.0])
	if tiny:
		left_keys = ["center", "zoom_out", "zoom_in"]
		widths.assign([61.0, 35.0, 35.0])
	for key in ["left", "right"]:
		_hud_controls[key].visible = not tiny
	var nav_width := 0.0
	for width in widths:
		nav_width += width
	nav_width += gap * float(left_keys.size() - 1)
	var start_x := margin
	for i in left_keys.size():
		var button: Button = _hud_controls[left_keys[i]]
		_place(button, start_x, bottom, widths[i], button_h)
		start_x += widths[i] + gap
	var slot_w := 56.0 if compact else 74.0
	if tiny:
		slot_w = 45.0
	var ammo_w := slot_w * 3.0 + gap * 2.0
	var ammo_left := (w - ammo_w) * 0.5
	_place(_ammo_backplate, ammo_left - 7.0, bottom - 21.0, ammo_w + 14.0, button_h + 27.0)
	_place(_ammo_heading, ammo_left - 1.0, bottom - 19.0, ammo_w + 2.0, 17.0)
	_place(_ammo_cannon, ammo_left, bottom, slot_w, button_h)
	_place(_ammo_harpoon, ammo_left + slot_w + gap, bottom, slot_w, button_h)
	_place(_ammo_chain, ammo_left + 2.0 * (slot_w + gap), bottom, slot_w, button_h)
	var repair_w := 82.0 if compact else 115.0
	var attack_w := 106.0 if compact else 142.0
	if tiny:
		repair_w = 65.0
		attack_w = 83.0
	var right_x := w - margin - repair_w - gap - attack_w
	_place(_hud_controls["repair"], right_x, bottom, repair_w, button_h)
	_place(attack_button, right_x + repair_w + gap, bottom, attack_w, button_h)
	# Preserve the full set of controls and avoid silent touch overlap. On very
	# narrow windows the navigation arrows are hidden, not stacked over ammo.
	var groups_fit := margin + nav_width + 11.0 <= ammo_left - 7.0 and ammo_left + ammo_w + 18.0 <= right_x
	if not groups_fit:
		for key in ["left", "right"]:
			_hud_controls[key].visible = false
		# Center and zoom remain available alongside ammunition and combat.
		_place(_hud_controls["center"], margin, bottom, 58.0, button_h)
		_place(_hud_controls["zoom_out"], margin + 62.0, bottom, 32.0, button_h)
		_place(_hud_controls["zoom_in"], margin + 98.0, bottom, 32.0, button_h)
	# Match the actual top-card content bounds to the available display.
	var panel_w := minf(236.0 if compact else 266.0, w * 0.30)
	var player_y := header + margin
	_place(_hud_player_frame, margin, player_y, panel_w, 84.0)
	_place(_portrait, margin + 6.0, player_y + 6.0, 65.0, 70.0)
	_place(_captain_title, margin + 76.0, player_y + 6.0, panel_w - 85.0, 25.0)
	_place(_hull_bar, margin + 76.0, player_y + 35.0, panel_w - 87.0, 8.0)
	_place(_captain_numbers, margin + 76.0, player_y + 48.0, panel_w - 85.0, 34.0)
	var edge := clampf(h * 0.235, 79.0, 125.0)
	_place(_hud_mini_frame, w - margin - edge, player_y, edge, edge)
	_place(mini, 4.0, 4.0, edge - 8.0, edge - 8.0)
	var target_w := minf(205.0, w * 0.31)
	var target_x := w - margin - target_w
	var target_y := player_y + edge + 8.0
	_place(_hud_target_frame, target_x, target_y, target_w, 71.0)
	_place(target_text, target_x + 8.0, target_y + 4.0, target_w - 16.0, 23.0)
	_place(_target_bar, target_x + 8.0, target_y + 31.0, target_w - 16.0, 8.0)
	_place(_target_numbers, target_x + 8.0, target_y + 45.0, target_w - 16.0, 22.0)
	# The quest card sits below (not over) the captain card.
	var quest_y := player_y + 90.0
	var quest_h := minf(101.0, maxf(69.0, bottom - quest_y - 65.0))
	_place(_quest_frame, margin, quest_y, panel_w, quest_h)
	_place(_quest_title, margin + 8.0, quest_y + 4.0, panel_w - 16.0, 19.0)
	_place(_quest_progress, margin + 8.0, quest_y + 24.0, panel_w - 16.0, 19.0)
	_place(_quest_claim, margin + 8.0, quest_y + quest_h - 39.0, panel_w - 16.0, 34.0)
	# Status is deliberately on a separate raised strip above all touch inputs.
	var status_w := minf(330.0, w * 0.42)
	var status_y := bottom - 62.0
	_place(_hud_status_frame, (w - status_w) * 0.5, status_y, status_w, 37.0)
	_place(status, (w - status_w) * 0.5 + 9.0, status_y + 2.0, status_w - 18.0, 31.0)
	# Only one graphical-pack selector: keep the actual menu control.
	if _graphics_button != null:
		_graphics_button.visible = false
	# Popups use reserved rows: three ship choices, chainshot restock, close.
	var modal_w := minf(520.0, w - margin * 2.0)
	var modal_h := minf(368.0, h - margin * 2.0)
	var modal_x := (w - modal_w) * 0.5
	var modal_y := (h - modal_h) * 0.5
	_place(_yard_panel, modal_x, modal_y, modal_w, modal_h)
	_place(_yard_heading, 14.0, 9.0, modal_w - 28.0, 29.0)
	_place(_yard_description, 14.0, 40.0, modal_w - 28.0, 35.0)
	var ship_row_h := clampf((modal_h - 199.0) / 3.0, 38.0, 55.0)
	for i in _yard_buttons.size():
		_place(_yard_buttons[i], 14.0, 78.0 + float(i) * (ship_row_h + 4.0), modal_w - 28.0, ship_row_h)
	_place(_restock_chain_button, 14.0, modal_h - 101.0, modal_w - 28.0, 39.0)
	_place(_yard_close, 14.0, modal_h - 48.0, modal_w - 28.0, 38.0)
	# Options never exceed the available vertical room.
	var options_w := minf(305.0, w - margin * 2.0)
	var options_h := minf(322.0, h - header - margin * 2.0)
	_place(_options, w - options_w - margin, header + margin, options_w, options_h)
	_place(_options_title, 12.0, 9.0, options_w - 24.0, 26.0)
	_place(_pack_button, 12.0, 47.0, options_w - 24.0, 39.0)
	_place(_full_button, 12.0, 94.0, options_w - 24.0, 37.0)
	_place(_coating_button, 12.0, 140.0, options_w - 24.0, 39.0)
	_place(_options_close, 12.0, 187.0, options_w - 24.0, 39.0)
	_place(_build_label, 12.0, options_h - 28.0, options_w - 24.0, 18.0)


func _refresh() -> void:
	super._refresh()
	if _ammo_heading == null:
		return
	var mode_name := "EISENKUGEL"
	if weapon_mode == "harpoon":
		mode_name = "HARPUNE"
	elif weapon_mode == "chain":
		mode_name = "KETTENGESCHOSS"
	_ammo_heading.text = "MUNITION · " + mode_name
	_hud_controls["repair"].text = "REP."
	attack_button.text = "STOPP" if firing else "FEUER"
	# The old mode-cycling button is redundant; it must remain hidden even
	# after an inherited refresh or resize.
	harpoon_button.visible = false


func _sail(delta: float) -> void:
	if ship == null:
		return
	var sprite := ship.get_node_or_null("ShipSprite")
	if route.is_empty():
		_sea_speed = move_toward(_sea_speed, 0.0, THROTTLE_BRAKE * delta)
		if sprite != null:
			sprite.set_moving(false)
			sprite.set_heading(ship.rotation.y)
		if _wake_visual != null:
			_wake_visual.visible = false
		return
	var to_target: Vector3 = route[0] - ship.position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance <= ARRIVAL_RADIUS:
		route.remove_at(0)
		if route.is_empty():
			_sea_speed = 0.0
		return
	var desired_yaw := atan2(-to_target.x, -to_target.z)
	var heading_error := absf(angle_difference(ship.rotation.y, desired_yaw))
	ship.rotation.y = rotate_toward(ship.rotation.y, desired_yaw, deg_to_rad(TURN_RATE) * delta)
	# First rotate the bow, then increase throttle. In a hard turn the ship
	# loses speed smoothly rather than sliding sideways towards the waypoint.
	var helm_factor := clampf((1.65 - heading_error) / 1.4, 0.0, 1.0)
	var approach_factor := clampf((distance - ARRIVAL_RADIUS) / 7.5, 0.18, 1.0)
	var goal_speed := SEA_MAX_SPEED * helm_factor * approach_factor
	var acceleration := THROTTLE_ACCEL if goal_speed >= _sea_speed else THROTTLE_BRAKE
	_sea_speed = move_toward(_sea_speed, goal_speed, acceleration * delta)
	var bow := Vector3(-sin(ship.rotation.y), 0.0, -cos(ship.rotation.y))
	var distance_step := minf(_sea_speed * delta, maxf(0.0, distance - 0.25))
	# Sample the swept path to avoid tunnelling into coasts on slower devices.
	var proposed := ship.position + bow * distance_step
	var obstructed := false
	for fraction in [0.33, 0.66, 1.0]:
		var probe := ship.position.lerp(proposed, fraction)
		if _blocked(probe):
			obstructed = true
			break
	if obstructed:
		route.clear()
		_sea_speed = 0.0
		hint = "Küste voraus · neuen Kurs wählen"
		_refresh()
		return
	ship.position = proposed
	if sprite != null:
		sprite.set_heading(ship.rotation.y)
		sprite.set_moving(_sea_speed > 0.5)
	if _wake_visual != null:
		_wake_visual.visible = _sea_speed > 1.2
		_wake_visual.scale.z = clampf(_sea_speed / SEA_MAX_SPEED, 0.22, 1.0)

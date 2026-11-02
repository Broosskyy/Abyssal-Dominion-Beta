extends "res://scripts/classic/classic_sea_map.gd"
## M303.4: responsive native fullscreen/landscape presentation over isolated M303.1 gameplay.
## The original M302 pipeline remains untouched on main; no copied third-party graphics.
## No online connection; HUD is local gameplay UI only.

var _ui_root: Control
var _hud_bar: Panel
var _hud_header: Label
var _hud_player_frame: Panel
var _hud_target_frame: Panel
var _hud_status_frame: Panel
var _hud_mini_frame: Panel
var _hud_portrait_backdrop: Panel
var _hud_portrait_label: Label
var _hud_controls: Dictionary = {}
var _full_button: Button

func _ready() -> void:
	# Native Android: landscape orientation + immersive navigation/status bar.
	if OS.has_feature("android"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	if not OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	super._ready()
	get_viewport().size_changed.connect(_layout_hud)
	_layout_hud()
	_refresh()


func _panel(parent: Control) -> Panel:
	var item := Panel.new()
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_stylebox_override("panel", _style())
	parent.add_child(item)
	return item


func _label(parent: Control, label: String, font_size: int = 14) -> Label:
	var item := Label.new()
	item.text = label
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_color_override("font_color", Color("f5dcae"))
	item.add_theme_font_size_override("font_size", font_size)
	parent.add_child(item)
	return item


func _control(title: String, method: Callable) -> Button:
	var b := Button.new()
	b.text = title
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.clip_text = true
	b.add_theme_stylebox_override("normal", _style())
	b.add_theme_stylebox_override("hover", _style())
	b.add_theme_stylebox_override("pressed", _style())
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", Color("fff3d0"))
	_ui_root.add_child(b)
	b.pressed.connect(method)
	return b


func _make_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "M3034NativeHud"
	add_child(layer)
	_ui_root = Control.new()
	_ui_root.name = "SafeFullViewport"
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ui_root)

	_hud_bar = _panel(_ui_root)
	_hud_header = _label(_ui_root, "ABYSSAL DOMINION · M303.4   |   10/2 NORDMEER · LOKAL", 14)
	_hud_player_frame = _panel(_ui_root)
	_hud_target_frame = _panel(_ui_root)
	_hud_status_frame = _panel(_ui_root)
	_hud_mini_frame = _panel(_ui_root)

	var player_title := _label(_ui_root, "KAPITÄN   ·   EINSTEIGERSCHIFF", 13)
	player_title.name = "PlayerTitle"
	status = _label(_ui_root, "", 12)
	status.name = "GameplayStatus"
	target_text = _label(_ui_root, "", 13)
	target_text.name = "TargetStatus"
	target_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	mini = MINI_MAP.new()
	mini.name = "MiniMap"
	mini.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud_mini_frame.add_child(mini)

	_hud_controls["center"] = _control("ZENTR.", Callable(self, "_recenter"))
	_hud_controls["left"] = _control("◀", Callable(self, "_pan_left"))
	_hud_controls["right"] = _control("▶", Callable(self, "_pan_right"))
	_hud_controls["zoom_in"] = _control("+", Callable(self, "_zoom_in"))
	_hud_controls["zoom_out"] = _control("−", Callable(self, "_zoom_out"))
	_hud_controls["repair"] = _control("REPARATUR", Callable(self, "_repair"))
	attack_button = _control("FEUER", Callable(self, "_toggle_fire"))
	harpoon_button = _control("KUGELN", Callable(self, "_harpoon"))
	_hud_controls["fire"] = attack_button
	_hud_controls["weapon"] = harpoon_button
	_full_button = _control("VOLLBILD", Callable(self, "_fullscreen"))
	_hud_controls["fullscreen"] = _full_button

	# Native Android should rotate automatically; on web the browser may reject
	# forced orientation/fullscreen until a user gesture.
	_hud_portrait_backdrop = _panel(_ui_root)
	_hud_portrait_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud_portrait_label = _label(_hud_portrait_backdrop, "Bitte ins Querformat drehen\n\nAbyssal Dominion ist als Seekartenspiel im Querformat ausgelegt.", 19)
	_hud_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hud_portrait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _place(c: Control, x: float, y: float, width: float, height: float) -> void:
	# Pixel layout owns position and size; remove inherited stretch anchors.
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.position = Vector2(x, y)
	c.size = Vector2(maxf(1.0, width), maxf(1.0, height))


func _layout_hud() -> void:
	if _ui_root == null:
		return
	var screen := get_viewport().get_visible_rect().size
	var w := screen.x
	var h := screen.y
	if w <= 0.0 or h <= 0.0:
		return
	var portrait := w < h
	var small := w < 1024.0 or h < 540.0
	var margin := 10.0 if small else 16.0
	var bar := 34.0 if small else 44.0
	var control_h := 44.0 if small else 56.0
	var control_gap := 5.0 if small else 8.0
	var near_bottom := h - control_h - margin
	var mini_edge := clampf(h * 0.27, 84.0, 152.0)
	var player_width := minf(w * 0.30, 226.0)
	var right_panel_width := minf(w * 0.27, 222.0)

	_place(_hud_bar, 0, 0, w, bar)
	_place(_hud_header, margin, 6.0 if small else 10.0, w - 124.0, bar - 6.0)
	_hud_header.add_theme_font_size_override("font_size", 12 if small else 16)
	_place(_full_button, w - 90.0 - margin, 3.0, 90.0, bar - 6.0)
	_full_button.add_theme_font_size_override("font_size", 11 if small else 13)

	_place(_hud_player_frame, margin, bar + 7.0, player_width, 74.0 if small else 96.0)
	var player_title := _ui_root.get_node("PlayerTitle") as Label
	_place(player_title, margin + 7.0, bar + 12.0, player_width - 14.0, 20.0)
	player_title.add_theme_font_size_override("font_size", 11 if small else 13)

	_place(_hud_status_frame, margin, bar + (87.0 if small else 111.0), player_width + 24.0, 50.0 if small else 60.0)
	_place(status, margin + 6.0, bar + (91.0 if small else 118.0), player_width + 14.0, 45.0 if small else 53.0)
	status.add_theme_font_size_override("font_size", 11 if small else 13)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var mini_left := w - mini_edge - margin
	_place(_hud_mini_frame, mini_left, bar + 7.0, mini_edge, mini_edge)
	_place(mini, 4.0, 4.0, mini_edge - 8.0, mini_edge - 8.0)
	_place(_hud_target_frame, w - right_panel_width - margin, bar + mini_edge + 14.0, right_panel_width, 63.0 if small else 78.0)
	_place(target_text, w - right_panel_width - margin + 6.0, bar + mini_edge + 19.0, right_panel_width - 12.0, 60.0)
	target_text.add_theme_font_size_override("font_size", 12 if small else 14)

	# Independent left and right edge clusters. Never a continuous bottom bar.
	var x_left := margin
	var nav_width := 73.0 if small else 98.0
	var arrow_width := 40.0 if small else 52.0
	var zoom_width := 40.0 if small else 52.0
	for key in ["center", "left", "right", "zoom_out", "zoom_in"]:
		var btn: Button = _hud_controls[key]
		var width := nav_width if key == "center" else (zoom_width if key.begins_with("zoom") else arrow_width)
		_place(btn, x_left, near_bottom, width, control_h)
		x_left += width + control_gap

	var repair_w := 90.0 if small else 122.0
	var mode_w := 86.0 if small else 122.0
	var attack_w := 103.0 if small else 144.0
	var right_total := repair_w + mode_w + attack_w + 2.0 * control_gap
	var x_right := w - margin - right_total
	_place(_hud_controls["repair"], x_right, near_bottom, repair_w, control_h)
	_place(harpoon_button, x_right + repair_w + control_gap, near_bottom, mode_w, control_h)
	_place(attack_button, x_right + repair_w + mode_w + 2.0 * control_gap, near_bottom, attack_w, control_h)
	attack_button.add_theme_font_size_override("font_size", 12 if small else 15)
	harpoon_button.add_theme_font_size_override("font_size", 11 if small else 13)

	_hud_portrait_backdrop.visible = portrait
	if portrait:
		_place(_hud_portrait_backdrop, 0.0, 0.0, w, h)
		_place(_hud_portrait_label, w * 0.1, h * 0.27, w * 0.8, h * 0.46)


func _fullscreen() -> void:
	if OS.has_feature("android"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_layout_hud()


func _unhandled_input(event: InputEvent) -> void:
	if _hud_portrait_backdrop != null and _hud_portrait_backdrop.visible:
		return
	if event is InputEventMagnifyGesture:
		var factor := (event as InputEventMagnifyGesture).factor
		if factor > 0.0:
			zoom = clampf(zoom / factor, 44.0, 135.0)
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)
